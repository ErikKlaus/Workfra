import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/apiKonstanta.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/api_service.dart';
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
  final ApiService _apiService;

  AuthRemoteDataSourceImpl(this._client, this._apiService);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final body = await _apiService.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
      headers: ApiConstants.jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final token = _extractTokenFromBody(body);
    final userData = _extractUserFromBody(body);
    return UserModel.fromJson(userData, token: token);
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
    final genderCode = _genderCodeFromId(genderId);
    final body = await _apiService.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
      headers: ApiConstants.jsonHeaders,
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
    final token = _extractTokenFromBody(body);
    final userData = _extractUserFromBody(body);
    return UserModel.fromJson(userData, token: token);
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
    final body = await _apiService.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.trainingsEndpoint}'),
      headers: ApiConstants.acceptHeaders,
    );
    final items = _extractListFromBody(body, 'trainings');
    return items.map(OpsiDropdownModel.fromJson).toList(growable: false);
  }

  @override
  Future<List<OpsiDropdownModel>> getBatches() async {
    final body = await _apiService.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.batchesEndpoint}'),
      headers: ApiConstants.acceptHeaders,
    );
    final items = _extractListFromBody(body, 'batches');
    return items.map(OpsiDropdownModel.fromJson).toList(growable: false);
  }

  static const _fallbackGenders = [
    JenisKelaminModel(id: 1, nama: 'Laki-laki'),
    JenisKelaminModel(id: 2, nama: 'Perempuan'),
  ];

  @override
  Future<List<JenisKelaminModel>> getGenders() async {
    try {
      final body = await _apiService.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.gendersEndpoint}'),
        headers: ApiConstants.acceptHeaders,
      );
      final items = _extractListFromBody(body, 'genders');
      if (items.isEmpty) return _fallbackGenders;

      final result = items
          .map(JenisKelaminModel.fromJson)
          .where((item) => item.id > 0 && item.nama != '-')
          .toList(growable: false);
      return result.isEmpty ? _fallbackGenders : result;
    } on ClientException catch (e) {
      if (e.statusCode == 404) return _fallbackGenders;
      rethrow;
    } catch (_) {
      return _fallbackGenders;
    }
  }

  @override
  Future<void> uploadPhoto({
    required String filePath,
    required String token,
  }) async {
    await _apiService.ensureInternetConnection();
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.profilePhotoEndpoint}',
    );

    final uploadedMultipart = await _tryMultipartUpload(
      uri: uri,
      token: token,
      filePath: filePath,
    );
    if (uploadedMultipart) return;

    final photoDataUrl = await _buildProfilePhotoDataUrl(filePath);
    final payload = {'profile_photo': photoDataUrl};

    try {
      await _apiService.put(
        uri,
        headers: ApiConstants.authJsonHeaders(token),
        body: jsonEncode(payload),
      );
    } catch (_) {
      // Fallback for backend requiring POST + _method=PUT
      try {
        await _apiService.post(
          uri,
          headers: ApiConstants.authJsonHeaders(token),
          body: jsonEncode({...payload, '_method': 'PUT'}),
        );
      } catch (e) {
        if (e is ServerException) rethrow;
        throw const ClientException(
          message: 'error_upload_photo',
          statusCode: 400,
        ); // Standard message mapping
      }
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
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      try {
        final putResponse = await _apiService
            .retryRequest<http.StreamedResponse>(
              () =>
                  _client.send(putRequest).timeout(const Duration(seconds: 10)),
              shouldRetry: (e) =>
                  e is TimeoutException ||
                  e is SocketException ||
                  e is http.ClientException,
            );
        if (putResponse.statusCode == 200 || putResponse.statusCode == 201)
          return true;
      } catch (_) {}

      final postRequest = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['_method'] = 'PUT'
        ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      try {
        final postResponse = await _apiService
            .retryRequest<http.StreamedResponse>(
              () => _client
                  .send(postRequest)
                  .timeout(const Duration(seconds: 10)),
              shouldRetry: (e) =>
                  e is TimeoutException ||
                  e is SocketException ||
                  e is http.ClientException,
            );
        if (postResponse.statusCode == 200 || postResponse.statusCode == 201)
          return true;
      } catch (_) {}
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
    if (dotIndex == -1 || dotIndex == filePath.length - 1)
      return 'application/octet-stream';
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

  @override
  Future<void> forgotPassword({required String email}) async {
    await _apiService.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.forgotPasswordEndpoint}',
      ),
      headers: ApiConstants.jsonHeaders,
      body: jsonEncode({'email': email}),
    );
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    await _apiService.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtpEndpoint}'),
      headers: ApiConstants.jsonHeaders,
      body: jsonEncode({'email': email, 'otp': otp}),
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _apiService.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resetPasswordEndpoint}'),
      headers: ApiConstants.jsonHeaders,
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
  }

  String _extractTokenFromBody(Map<String, dynamic> body) {
    String? pickToken(dynamic value) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
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
    if (user is Map<String, dynamic>) return user;
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) return nestedUser;
      if (data['name'] != null || data['email'] != null || data['id'] != null)
        return data;
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
    if (candidate is List)
      return candidate.whereType<Map<String, dynamic>>().toList(
        growable: false,
      );
    return const [];
  }
}
