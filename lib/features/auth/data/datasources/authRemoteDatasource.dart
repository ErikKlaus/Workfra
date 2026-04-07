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
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.profilePhotoEndpoint}',
      );

      final uploadedMultipart = await _tryMultipartUpload(
        uri: uri,
        token: token,
        filePath: filePath,
      );
      if (uploadedMultipart) {
        return;
      }

      final photoDataUrl = await _buildProfilePhotoDataUrl(filePath);
      final payload = <String, dynamic>{'profile_photo': photoDataUrl};

      final putResponse = await _client.put(
        uri,
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode(payload),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        return;
      }

      // Fallback untuk backend yang mengharuskan POST + _method=PUT.
      final postResponse = await _client.post(
        uri,
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({...payload, '_method': 'PUT'}),
      );

      if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
        return;
      }

      final putMessage = _extractErrorMessage(
        putResponse.body,
        'Gagal mengunggah foto',
      );
      final postMessage = _extractErrorMessage(postResponse.body, putMessage);
      throw ServerException(
        message: postMessage,
        statusCode: postResponse.statusCode,
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

  Future<bool> _tryMultipartUpload({
    required Uri uri,
    required String token,
    required String filePath,
  }) async {
    const fieldCandidates = ['profile_photo', 'photo_profile', 'photo'];

    for (final fieldName in fieldCandidates) {
      final putRequest = http.MultipartRequest('PUT', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';

      putRequest.files.add(
        await http.MultipartFile.fromPath(fieldName, filePath),
      );

      final putResponse = await _client.send(putRequest);
      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        return true;
      }

      final postRequest = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['_method'] = 'PUT';

      postRequest.files.add(
        await http.MultipartFile.fromPath(fieldName, filePath),
      );

      final postResponse = await _client.send(postRequest);
      if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
        return true;
      }
    }

    return false;
  }

  Future<String> _buildProfilePhotoDataUrl(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final rawBase64 = base64Encode(bytes);
    final mimeType = _mimeTypeFromPath(filePath);
    return 'data:$mimeType;base64,$rawBase64';
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
