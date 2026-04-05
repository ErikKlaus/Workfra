import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/apiKonstanta.dart';
import '../../../../core/error/exceptions.dart';
import '../models/jenisKelaminModel.dart';
import '../models/opsiDropdownModel.dart';
import '../models/userModel.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required int genderId,
  });
  Future<List<OpsiDropdownModel>> getTrainings();
  Future<List<OpsiDropdownModel>> getBatches();
  Future<List<JenisKelaminModel>> getGenders();
  Future<void> uploadPhoto({required String filePath, required String token});
  Future<void> forgotPassword({required String email});
  Future<void> verifyOtp({required String email, required String otp});
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client _client;
  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final token = _extractTokenFromBody(body);
        final userData = _extractUserFromBody(body);
        return UserModel.fromJson(userData, token: token);
      } else if (response.statusCode == 401) {
        throw const ServerException(
          message: 'Email atau kata sandi salah',
          statusCode: 401,
        );
      } else if (response.statusCode == 422) {
        final errors = body['errors'] as Map<String, dynamic>?;
        final message =
            _extractValidationMessage(errors) ??
            body['message'] as String? ??
            'Validasi gagal';
        throw ServerException(message: message, statusCode: 422);
      } else {
        throw ServerException(
          message:
              body['message'] as String? ?? 'Terjadi kesalahan pada server',
          statusCode: response.statusCode,
        );
      }
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
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required int genderId,
  }) async {
    try {
      final genderCode = _genderCodeFromId(genderId);
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'training_id': trainingId,
          'batch_id': batchId,
          'gender_id': genderId,
          'jenis_kelamin_id': genderId,
          'gender': genderCode,
          'jenis_kelamin': genderCode,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = _extractTokenFromBody(body);
        final userData = _extractUserFromBody(body);
        return UserModel.fromJson(userData, token: token);
      } else if (response.statusCode == 422) {
        final errors = body['errors'] as Map<String, dynamic>?;
        final message =
            _extractValidationMessage(errors) ??
            body['message'] as String? ??
            'Validasi gagal';
        throw ServerException(message: message, statusCode: 422);
      } else {
        throw ServerException(
          message:
              body['message'] as String? ?? 'Terjadi kesalahan pada server',
          statusCode: response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  String _genderCodeFromId(int genderId) {
    switch (genderId) {
      case 1:
        return 'L';
      case 2:
        return 'P';
      default:
        return genderId.toString();
    }
  }

  @override
  Future<List<OpsiDropdownModel>> getTrainings() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.trainingsEndpoint}'),
        headers: ApiConstants.defaultHeaders,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      developer.log(
        'getTrainings response: ${response.body}',
        name: 'AuthRemoteDataSource',
      );
      if (response.statusCode == 200) {
        final items = _extractListFromBody(body, 'trainings');
        final result = items
            .map(OpsiDropdownModel.fromJson)
            .toList(growable: false);
        developer.log(
          'getTrainings parsed ${result.length} items: ${result.map((e) => '${e.id}:${e.nama}').join(', ')}',
          name: 'AuthRemoteDataSource',
        );
        return result;
      }

      throw ServerException(
        message: body['message'] as String? ?? 'Gagal mengambil data pelatihan',
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
  Future<List<OpsiDropdownModel>> getBatches() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.batchesEndpoint}'),
        headers: ApiConstants.defaultHeaders,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      developer.log(
        'getBatches response: ${response.body}',
        name: 'AuthRemoteDataSource',
      );
      if (response.statusCode == 200) {
        final items = _extractListFromBody(body, 'batches');
        final result = items
            .map(OpsiDropdownModel.fromJson)
            .toList(growable: false);
        developer.log(
          'getBatches parsed ${result.length} items: ${result.map((e) => '${e.id}:${e.nama}').join(', ')}',
          name: 'AuthRemoteDataSource',
        );
        return result;
      }

      throw ServerException(
        message: body['message'] as String? ?? 'Gagal mengambil data batch',
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

  /// Default gender options used when the API endpoint is unavailable.
  static const _fallbackGenders = [
    JenisKelaminModel(id: 1, nama: 'Laki-laki'),
    JenisKelaminModel(id: 2, nama: 'Perempuan'),
  ];

  @override
  Future<List<JenisKelaminModel>> getGenders() async {
    try {
      developer.log(
        'getGenders → GET ${ApiConstants.baseUrl}${ApiConstants.gendersEndpoint}',
        name: 'AuthRemoteDataSource',
      );
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.gendersEndpoint}'),
        headers: ApiConstants.defaultHeaders,
      );

      developer.log(
        'getGenders response [${response.statusCode}]: ${response.body}',
        name: 'AuthRemoteDataSource',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = _extractListFromBody(body, 'genders');

        if (items.isEmpty) {
          developer.log(
            'getGenders → API returned empty list, using fallback',
            name: 'AuthRemoteDataSource',
          );
          return _fallbackGenders;
        }

        final result = items
            .map(JenisKelaminModel.fromJson)
            .where((item) => item.id > 0 && item.nama != '-')
            .toList(growable: false);

        if (result.isEmpty) {
          developer.log(
            'getGenders → API list invalid, using fallback',
            name: 'AuthRemoteDataSource',
          );
          return _fallbackGenders;
        }

        developer.log(
          'getGenders parsed ${result.length} items from API: '
          '${result.map((e) => '${e.id}:${e.nama}').join(', ')}',
          name: 'AuthRemoteDataSource',
        );
        return result;
      }

      // Endpoint belum ada di backend (404) → gunakan data fallback
      if (response.statusCode == 404) {
        developer.log(
          'getGenders → endpoint 404, using local fallback data',
          name: 'AuthRemoteDataSource',
        );
        return _fallbackGenders;
      }

      // Status lain (500, 401, dll) → lempar error agar UI tampilkan retry
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ServerException(
        message:
            body['message'] as String? ?? 'Gagal mengambil data jenis kelamin',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      // Network error / timeout → tetap fallback agar UI tidak stuck
      developer.log(
        'getGenders → error: $e, using local fallback data',
        name: 'AuthRemoteDataSource',
      );
      return _fallbackGenders;
    }
  }

  @override
  Future<void> uploadPhoto({
    required String filePath,
    required String token,
  }) async {
    try {
      const fieldCandidates = ['photo_profile', 'photo', 'profile_photo'];
      const methodCandidates = [
        (httpMethod: 'PUT', methodOverride: null),
        (httpMethod: 'POST', methodOverride: null),
        (httpMethod: 'POST', methodOverride: 'PUT'),
      ];
      ServerException? lastError;

      for (final method in methodCandidates) {
        for (final fieldName in fieldCandidates) {
          try {
            await _uploadPhotoWithField(
              filePath: filePath,
              token: token,
              fieldName: fieldName,
              httpMethod: method.httpMethod,
              methodOverride: method.methodOverride,
            );
            return;
          } on ServerException catch (e) {
            lastError = e;
            if (!_shouldRetryUpload(e)) {
              rethrow;
            }
          }
        }
      }

      // Some backends validate profile photo as a string field.
      if (lastError != null &&
          (_looksLikeStringPhotoError(lastError.message) ||
              _looksLikeMissingPhotoField(lastError.message))) {
        final photoStringCandidates = await _buildPhotoStringCandidates(
          filePath,
        );
        for (final method in methodCandidates) {
          for (final fieldName in fieldCandidates) {
            for (final photoValue in photoStringCandidates) {
              try {
                await _uploadPhotoAsString(
                  token: token,
                  fieldName: fieldName,
                  photoValue: photoValue,
                  httpMethod: method.httpMethod,
                  methodOverride: method.methodOverride,
                );
                return;
              } on ServerException catch (e) {
                lastError = e;
                if (!_shouldRetryUpload(e)) {
                  rethrow;
                }
              }
            }
          }
        }
      }

      throw lastError ??
          const ServerException(
            message: 'Gagal mengunggah foto',
            statusCode: 0,
          );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Gagal mengunggah foto: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<void> _uploadPhotoWithField({
    required String filePath,
    required String token,
    required String fieldName,
    required String httpMethod,
    required String? methodOverride,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.profilePhotoEndpoint}',
    );
    final request = http.MultipartRequest(httpMethod, uri);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (methodOverride != null) {
      request.fields['_method'] = methodOverride;
    }
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    final message = _extractErrorMessage(
      response.body,
      'Gagal mengunggah foto',
    );
    throw ServerException(message: message, statusCode: response.statusCode);
  }

  Future<void> _uploadPhotoAsString({
    required String token,
    required String fieldName,
    required String photoValue,
    required String httpMethod,
    required String? methodOverride,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.profilePhotoEndpoint}',
    );
    final payload = <String, dynamic>{fieldName: photoValue};
    if (methodOverride != null) {
      payload['_method'] = methodOverride;
    }

    final response = switch (httpMethod) {
      'PUT' => await _client.put(
        uri,
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode(payload),
      ),
      _ => await _client.post(
        uri,
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode(payload),
      ),
    };

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    final message = _extractErrorMessage(
      response.body,
      'Gagal mengunggah foto',
    );
    throw ServerException(message: message, statusCode: response.statusCode);
  }

  Future<List<String>> _buildPhotoStringCandidates(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final rawBase64 = base64Encode(bytes);
    final mimeType = _mimeTypeFromPath(filePath);
    final dataUrl = 'data:$mimeType;base64,$rawBase64';
    return [dataUrl, rawBase64];
  }

  String _mimeTypeFromPath(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filePath.length - 1) {
      return 'application/octet-stream';
    }

    final extension = filePath.substring(dotIndex + 1).toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  bool _looksLikeMissingPhotoField(String? message) {
    if (message == null || message.isEmpty) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('photo profile') ||
        normalized.contains('photo_profile') ||
        normalized.contains('profile photo') ||
        normalized.contains('profile_photo') ||
        (normalized.contains('photo') && normalized.contains('required'));
  }

  bool _shouldRetryUpload(ServerException error) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return false;
    }

    final message = error.message;
    final normalized = message.toLowerCase();
    if (_looksLikeMissingPhotoField(message)) {
      return true;
    }

    if (_looksLikeStringPhotoError(message)) {
      return true;
    }

    if (error.statusCode == 405 || error.statusCode == 415) {
      return true;
    }

    return normalized.contains('method not allowed') ||
        normalized.contains('unsupported media type');
  }

  bool _looksLikeStringPhotoError(String message) {
    final normalized = message.toLowerCase();
    final mentionsPhoto =
        normalized.contains('photo') ||
        normalized.contains('profile_photo') ||
        normalized.contains('photo_profile') ||
        normalized.contains('profile photo');
    return mentionsPhoto && normalized.contains('must be string');
  }

  String _extractErrorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        final validationMessage = errors is Map<String, dynamic>
            ? _extractValidationMessage(errors)
            : null;
        return validationMessage ?? decoded['message'] as String? ?? fallback;
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await _client.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.forgotPasswordEndpoint}',
        ),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({'email': email}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message:
              body['message'] as String? ?? 'Gagal mengirim kode verifikasi',
          statusCode: response.statusCode,
        );
      }
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
  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtpEndpoint}'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: body['message'] as String? ?? 'Kode OTP tidak valid',
          statusCode: response.statusCode,
        );
      }
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
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.resetPasswordEndpoint}',
        ),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message:
              body['message'] as String? ?? 'Gagal mengatur ulang kata sandi',
          statusCode: response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  String? _extractValidationMessage(Map<String, dynamic>? errors) {
    if (errors == null) return null;
    final firstError = errors.values.first;
    if (firstError is List && firstError.isNotEmpty) {
      return firstError.first.toString();
    }
    return firstError.toString();
  }

  String _extractTokenFromBody(Map<String, dynamic> body) {
    String? pickToken(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return null;
    }

    final data = body['data'];
    final user = body['user'];

    return pickToken(body['token']) ??
        pickToken(body['access_token']) ??
        pickToken(body['accessToken']) ??
        (data is Map<String, dynamic>
            ? pickToken(data['token']) ??
                  pickToken(data['access_token']) ??
                  pickToken(data['accessToken'])
            : null) ??
        (user is Map<String, dynamic>
            ? pickToken(user['token']) ??
                  pickToken(user['access_token']) ??
                  pickToken(user['accessToken'])
            : null) ??
        '';
  }

  Map<String, dynamic> _extractUserFromBody(Map<String, dynamic> body) {
    final user = body['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) {
        return nestedUser;
      }

      if (data['name'] != null || data['email'] != null || data['id'] != null) {
        return data;
      }
    }

    return body;
  }

  List<Map<String, dynamic>> _extractListFromBody(
    Map<String, dynamic> body,
    String expectedKey,
  ) {
    final data = body['data'];
    final candidate =
        body[expectedKey] ??
        (data is Map<String, dynamic> ? data[expectedKey] : null) ??
        data;

    if (candidate is List) {
      return candidate.whereType<Map<String, dynamic>>().toList(
        growable: false,
      );
    }
    return const [];
  }
}
