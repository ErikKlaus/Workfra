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
    try {
      final endpoint = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.absenEndpoint}/$id',
      );

      var response = await _apiService.send(
        request: () => _client.delete(
          endpoint,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (_isDeleteSuccess(response.statusCode)) {
        return;
      }

      if (response.statusCode == 401) {
        throw ServerException(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }

      if (_shouldUseMethodOverride(response.statusCode)) {
        response = await _apiService.send(
          request: () => _client.post(
            endpoint,
            headers: ApiConstants.authHeaders(token),
            body: jsonEncode({'_method': 'DELETE', 'id': id}),
          ),
        );

        if (_isDeleteSuccess(response.statusCode)) {
          return;
        }

        if (response.statusCode == 401) {
          throw ServerException(
            message: 'Sesi telah berakhir. Silakan login kembali.',
            statusCode: 401,
          );
        }
      }

      throw ServerException(
        message: _extractErrorMessage(response.body, 'Gagal menghapus data'),
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<RiwayatModel>> getHistory({required String token}) async {
    try {
      final response = await _apiService.send(
        request: () => _client.get(
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.absenHistoryEndpoint}',
          ),
          headers: ApiConstants.authHeaders(token),
        ),
      );

      final body = _safeDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> data = _extractList(body);
        return data
            .map((e) => RiwayatModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (response.statusCode == 401) {
        throw ServerException(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }

      throw ServerException(
        message: _extractMessage(body, 'Gagal memuat riwayat absensi'),
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<AbsensiHariIniModel> getTodayStatus({required String token}) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);

      developer.log(
        'getTodayStatus → GET ${ApiConstants.absenTodayEndpoint}?attendance_date=$dateStr',
        name: 'AbsensiRemoteDataSource',
      );

      final response = await _apiService.send(
        request: () => _client.get(
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.absenTodayEndpoint}?attendance_date=$dateStr',
          ),
          headers: ApiConstants.authHeaders(token),
        ),
      );

      developer.log(
        'getTodayStatus response [${response.statusCode}]: ${response.body}',
        name: 'AbsensiRemoteDataSource',
      );

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response.body);
        final body = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};
        final enriched = _withServerClock(body, response.headers);
        return AbsensiHariIniModel.fromJson(enriched);
      }

      if (response.statusCode == 401) {
        throw ServerException(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }

      // 404 or no data = belum absen hari ini
      if (response.statusCode == 404) {
        return AbsensiHariIniModel.fromJson(
          _withServerClock(const {'status': 'belum'}, response.headers),
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ServerException(
        message:
            body['message'] as String? ??
            'Gagal memuat status absensi hari ini',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      developer.log(
        'getTodayStatus error: $e',
        name: 'AbsensiRemoteDataSource',
      );
      throw ServerException(
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 0,
      );
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
    final safeAddress = address.trim().isEmpty
        ? 'Lokasi tidak tersedia'
        : address.trim();

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
        latitude: latitude,
        longitude: longitude,
        label: 'checkIn',
        customPayload: primaryPayload,
      );
    } on ServerException catch (e) {
      if (e.statusCode != 422) {
        rethrow;
      }

      return _postAbsen(
        endpoint: ApiConstants.checkInEndpoint,
        token: token,
        latitude: latitude,
        longitude: longitude,
        label: 'checkIn-legacy',
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
    final safeAddress = address.trim().isEmpty
        ? 'Lokasi tidak tersedia'
        : address.trim();

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
        latitude: latitude,
        longitude: longitude,
        label: 'checkOut',
        customPayload: primaryPayload,
      );
    } on ServerException catch (e) {
      if (e.statusCode != 422) {
        rethrow;
      }

      return _postAbsen(
        endpoint: ApiConstants.checkOutEndpoint,
        token: token,
        latitude: latitude,
        longitude: longitude,
        label: 'checkOut-legacy',
        customPayload: legacyPayload,
      );
    }
  }

  bool _isDeleteSuccess(int statusCode) {
    return statusCode == 200 || statusCode == 202 || statusCode == 204;
  }

  bool _shouldUseMethodOverride(int statusCode) {
    return statusCode == 404 ||
        statusCode == 405 ||
        statusCode == 422 ||
        statusCode == 500;
  }

  Future<Map<String, dynamic>> _postAbsen({
    required String endpoint,
    required String token,
    required double latitude,
    required double longitude,
    required String label,
    Map<String, dynamic>? customPayload,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      if (dateStr.isEmpty) {
        throw const ServerException(
          message: 'Tanggal absensi tidak valid.',
          statusCode: 0,
        );
      }

      developer.log(
        '$label → POST $endpoint (lat=$latitude, lng=$longitude, date=$dateStr)',
        name: 'AbsensiRemoteDataSource',
      );

      final payload =
          customPayload ??
          <String, dynamic>{
            'latitude': latitude,
            'longitude': longitude,
            'attendance_date': dateStr,
          };

      final response = await _apiService.send(
        request: () => _client.post(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: ApiConstants.authHeaders(token),
          body: jsonEncode(payload),
        ),
      );

      developer.log(
        '$label response [${response.statusCode}]: ${response.body}',
        name: 'AbsensiRemoteDataSource',
      );

      final decoded = _safeDecode(response.body);
      final body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      final enrichedBody = _withServerClock(body, response.headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return enrichedBody;
      }

      if (response.statusCode == 401) {
        throw ServerException(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }

      throw ServerException(
        message: enrichedBody['message'] as String? ?? 'Gagal melakukan $label',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      developer.log('$label error: $e', name: 'AbsensiRemoteDataSource');
      throw ServerException(
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  dynamic _safeDecode(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> _withServerClock(
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) {
    final enriched = Map<String, dynamic>.from(body);

    if (enriched.containsKey('_server_time') ||
        enriched.containsKey('server_time') ||
        enriched.containsKey('server_now') ||
        enriched.containsKey('current_time') ||
        enriched.containsKey('timestamp')) {
      return enriched;
    }

    final serverDate = _extractServerDate(headers);
    if (serverDate == null) {
      return enriched;
    }

    enriched['_server_time'] = serverDate.toIso8601String();
    return enriched;
  }

  DateTime? _extractServerDate(Map<String, String> headers) {
    final rawDate = headers['date'] ?? headers['Date'];
    if (rawDate == null || rawDate.trim().isEmpty) {
      return null;
    }

    final isoParsed = DateTime.tryParse(rawDate);
    if (isoParsed != null) {
      return isoParsed.toLocal();
    }

    try {
      final parsedHttpDate = DateFormat(
        "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
        'en_US',
      ).parseUtc(rawDate);
      return parsedHttpDate.toLocal();
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) {
      return body;
    }

    if (body is! Map) {
      return [];
    }

    final normalized = Map<String, dynamic>.from(body);
    const listKeys = [
      'data',
      'history',
      'attendances',
      'attendance',
      'items',
      'results',
      'records',
    ];

    for (final key in listKeys) {
      final value = normalized[key];
      if (value is List) {
        return value;
      }
    }

    for (final key in listKeys) {
      final value = normalized[key];
      if (value is Map) {
        final nested = _extractList(value);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return [];
  }

  String _extractMessage(dynamic body, String fallback) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  String _extractErrorMessage(String body, String fallback) {
    if (body.trim().isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }

        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
          return firstError.toString();
        }
      }
    } catch (_) {
      return fallback;
    }

    return fallback;
  }
}
