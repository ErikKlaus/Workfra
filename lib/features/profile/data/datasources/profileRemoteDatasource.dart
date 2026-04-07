import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/apiKonstanta.dart';
import '../../../../core/error/exceptions.dart';
import '../models/profileModel.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile({required String token});
  Future<ProfileModel> updateProfile({
    required String token,
    required String name,
    required String email,
  });
  Future<void> uploadPhoto({required String token, required String filePath});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client _client;
  ProfileRemoteDataSourceImpl(this._client);

  @override
  Future<ProfileModel> getProfile({required String token}) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileEndpoint}'),
        headers: ApiConstants.authHeaders(token),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final userData = _extractUserFromBody(body);
        return ProfileModel.fromJson(userData);
      }
      throw ServerException(
        message: body['message'] as String? ?? 'Gagal mengambil data profil',
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
  Future<ProfileModel> updateProfile({
    required String token,
    required String name,
    required String email,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileEndpoint}'),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({'name': name, 'email': email}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = _extractUserFromBody(body);
        return ProfileModel.fromJson(userData);
      } else if (response.statusCode == 422) {
        final errors = body['errors'] as Map<String, dynamic>?;
        final message =
            _extractValidationMessage(errors) ??
            body['message'] as String? ??
            'Validasi gagal';
        throw ServerException(message: message, statusCode: 422);
      }
      throw ServerException(
        message: body['message'] as String? ?? 'Gagal memperbarui profil',
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
  Future<void> uploadPhoto({
    required String token,
    required String filePath,
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

      throw ServerException(
        message: 'Gagal mengunggah foto profil',
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

  Map<String, dynamic> _extractUserFromBody(Map<String, dynamic> body) {
    final profile = body['profile'];
    if (profile is Map<String, dynamic>) return profile;
    final user = body['user'];
    if (user is Map<String, dynamic>) return user;
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) return nestedUser;
      if (data['name'] != null || data['email'] != null) return data;
    }
    return body;
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
