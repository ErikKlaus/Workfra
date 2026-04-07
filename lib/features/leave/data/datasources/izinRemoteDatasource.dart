import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/apiKonstanta.dart';
import '../../../../core/error/exceptions.dart';
import '../models/izinModel.dart';

abstract class IzinRemoteDataSource {
  Future<List<IzinModel>> getIzinHistory({required String token});
  Future<void> createIzin({
    required String token,
    required String date,
    required String type,
    required String reason,
  });
}

class IzinRemoteDataSourceImpl implements IzinRemoteDataSource {
  final http.Client _client;
  IzinRemoteDataSourceImpl(this._client);

  @override
  Future<List<IzinModel>> getIzinHistory({required String token}) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.izinEndpoint}'),
        headers: ApiConstants.authHeaders(token),
      );

      final body = _safeDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> data = _extractList(body);
        return data
            .map((e) => IzinModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // If endpoint is not available in backend, use empty fallback list.
      if (response.statusCode == 404 || response.statusCode == 405) {
        return [];
      }

      if (response.statusCode == 401) {
        throw ServerException(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }

      throw ServerException(
        message: body['message'] as String? ?? 'Gagal memuat riwayat izin',
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
  Future<void> createIzin({
    required String token,
    required String date,
    required String type,
    required String reason,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.izinEndpoint}'),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({
          'date': date,
          'type': type,
          'reason': reason,
          'alasan_izin': reason,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 401) {
        throw ServerException(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 422) {
        final errors = body['errors'] as Map<String, dynamic>?;
        final message =
            _extractValidationMessage(errors) ??
            body['message'] as String? ??
            'Validasi gagal';
        throw ServerException(message: message, statusCode: 422);
      }

      throw ServerException(
        message: body['message'] as String? ?? 'Gagal mengajukan izin',
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

  Map<String, dynamic> _safeDecode(String rawBody) {
    if (rawBody.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(Map<String, dynamic> body) {
    if (body['data'] is List) return body['data'] as List;
    if (body['leaves'] is List) return body['leaves'] as List;
    if (body['izin'] is List) return body['izin'] as List;
    return [];
  }

  String? _extractValidationMessage(Map<String, dynamic>? errors) {
    if (errors == null) return null;
    final firstError = errors.values.first;
    if (firstError is List && firstError.isNotEmpty) {
      return firstError.first.toString();
    }
    return firstError.toString();
  }
}
