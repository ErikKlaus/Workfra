import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../core/constants/apiKonstanta.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/api_service.dart';
import '../../../home/data/models/riwayatModel.dart';
import '../models/absensiHariIniModel.dart';

abstract class AbsensiRemoteDataSource {
  Future<List<RiwayatModel>> getHistory({required String token});
  Future<AbsensiHariIniModel> getTodayStatus({required String token});
  Future<void> deleteAbsen({required String token, required int id});
  Future<Map<String, dynamic>> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  });
  Future<Map<String, dynamic>> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  });
}

class AbsensiRemoteDataSourceImpl implements AbsensiRemoteDataSource {
  final http.Client _client;
  final ApiService _apiService;

  AbsensiRemoteDataSourceImpl(this._client, this._apiService);

  @override
  Future<void> deleteAbsen({required String token, required int id}) async {
    final endpoint = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.absenEndpoint}/$id');

    try {
      await _apiService.delete(endpoint, headers: ApiConstants.authHeaders(token));
    } catch (e) {
      if (e is ServerException && _shouldUseMethodOverride(e.statusCode)) {
        await _apiService.post(
          endpoint,
          headers: ApiConstants.authHeaders(token),
          body: jsonEncode({'_method': 'DELETE', 'id': id}),
        );
        return;
      }
      rethrow;
    }
  }

  @override
  Future<List<RiwayatModel>> getHistory({required String token}) async {
    final body = await _apiService.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.absenHistoryEndpoint}'),
      headers: ApiConstants.authHeaders(token),
    );
    final data = _extractList(body);
    return data.map((e) => RiwayatModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AbsensiHariIniModel> getTodayStatus({required String token}) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    try {
      final response = await _apiService.send(
        request: () => _client.get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.absenTodayEndpoint}?attendance_date=$dateStr'),
          headers: ApiConstants.authHeaders(token),
        ),
      );
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final enriched = _withServerClock(body, response.headers);
        return AbsensiHariIniModel.fromJson(enriched);
      }
      
      if (response.statusCode == 401) {
        throw const UnauthorizedException();
      }

      if (response.statusCode == 404) {
        return AbsensiHariIniModel.fromJson(
          _withServerClock(const {'status': 'belum'}, response.headers),
        );
      }

      throw ServerException(statusCode: response.statusCode);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(statusCode: 0);
    }
  }

  @override
  Future<Map<String, dynamic>> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final checkInTime = DateFormat('HH:mm').format(now);
    final safeAddress = address.trim().isEmpty ? 'Lokasi tidak tersedia' : address.trim();

    final primaryPayload = <String, dynamic>{
      'attendance_date': dateStr,
      'latitude': latitude,
      'longitude': longitude,
      'address': safeAddress,
    };

    final legacyPayload = <String, dynamic>{
      ...primaryPayload,
      'check_in': checkInTime,
      'check_in_lat': latitude,
      'check_in_lng': longitude,
      'check_in_address': safeAddress,
    };

    try {
      return await _postAbsen(
        endpoint: ApiConstants.checkInEndpoint,
        token: token,
        customPayload: primaryPayload,
      );
    } on ValidationException {
      return _postAbsen(
        endpoint: ApiConstants.checkInEndpoint,
        token: token,
        customPayload: legacyPayload,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final checkOutTime = DateFormat('HH:mm').format(now);
    final safeAddress = address.trim().isEmpty ? 'Lokasi tidak tersedia' : address.trim();

    final primaryPayload = <String, dynamic>{
      'attendance_date': dateStr,
      'latitude': latitude,
      'longitude': longitude,
      'address': safeAddress,
    };

    final legacyPayload = <String, dynamic>{
      ...primaryPayload,
      'check_out': checkOutTime,
      'check_out_lat': latitude,
      'check_out_lng': longitude,
      'check_out_address': safeAddress,
    };

    try {
      return await _postAbsen(
        endpoint: ApiConstants.checkOutEndpoint,
        token: token,
        customPayload: primaryPayload,
      );
    } on ValidationException {
      return _postAbsen(
        endpoint: ApiConstants.checkOutEndpoint,
        token: token,
        customPayload: legacyPayload,
      );
    }
  }

  bool _shouldUseMethodOverride(int statusCode) {
    return statusCode == 404 || statusCode == 405 || statusCode == 422 || statusCode == 500;
  }

  Future<Map<String, dynamic>> _postAbsen({
    required String endpoint,
    required String token,
    required Map<String, dynamic> customPayload,
  }) async {
    final response = await _apiService.send(
      request: () => _client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode(customPayload),
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
       final body = jsonDecode(response.body) as Map<String, dynamic>;
       return _withServerClock(body, response.headers);
    }
    
    if (response.statusCode == 401) throw const UnauthorizedException();
    if (response.statusCode == 422) throw const ValidationException();

    throw ServerException(statusCode: response.statusCode);
  }

  Map<String, dynamic> _withServerClock(Map<String, dynamic> body, Map<String, String> headers) {
    final enriched = Map<String, dynamic>.from(body);

    if (enriched.containsKey('_server_time') || enriched.containsKey('server_time') ||
        enriched.containsKey('server_now') || enriched.containsKey('current_time') ||
        enriched.containsKey('timestamp')) {
      return enriched;
    }

    final serverDate = _extractServerDate(headers);
    if (serverDate == null) return enriched;

    enriched['_server_time'] = serverDate.toIso8601String();
    return enriched;
  }

  DateTime? _extractServerDate(Map<String, String> headers) {
    final rawDate = headers['date'] ?? headers['Date'];
    if (rawDate == null || rawDate.trim().isEmpty) return null;

    final isoParsed = DateTime.tryParse(rawDate);
    if (isoParsed != null) return isoParsed.toLocal();

    try {
      final parsedHttpDate = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US').parseUtc(rawDate);
      return parsedHttpDate.toLocal();
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return [];

    final normalized = Map<String, dynamic>.from(body);
    const listKeys = ['data', 'history', 'attendances', 'attendance', 'items', 'results', 'records'];

    for (final key in listKeys) {
      if (normalized[key] is List) return normalized[key] as List;
    }

    for (final key in listKeys) {
      if (normalized[key] is Map) {
        final nested = _extractList(normalized[key]);
        if (nested.isNotEmpty) return nested;
      }
    }

    return [];
  }
}
