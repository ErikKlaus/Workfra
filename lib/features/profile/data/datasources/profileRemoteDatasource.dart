import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/apiKonstanta.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/profilePhotoHelper.dart';
import '../models/profileModel.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile({required String token});
  Future<ProfileModel> updateProfile({
    required String token,
    required String name,
    required String email,
    String? photoUrl,
  });
  Future<void> uploadPhoto({required String token, required String filePath});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client _client;
  final ApiService _apiService;

  ProfileRemoteDataSourceImpl(this._client, this._apiService);

  @override
  Future<ProfileModel> getProfile({required String token}) async {
    final body = await _apiService.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileEndpoint}'),
      headers: ApiConstants.authAcceptHeaders(token),
    );
    final userData = _mergePhotoSource(
      userData: _extractUserFromBody(body),
      responseBody: body,
    );
    return ProfileModel.fromJson(userData);
  }

  @override
  Future<ProfileModel> updateProfile({
    required String token,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    // Only send name & email — photo is updated exclusively via uploadPhoto().
    // Including the base64 photo here causes the backend to either ignore it
    // or return a response without the photo, clearing it from the UI.
    final payload = <String, dynamic>{'name': name, 'email': email};

    final body = await _apiService.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileEndpoint}'),
      headers: ApiConstants.authJsonHeaders(token),
      body: jsonEncode(payload),
    );
    final userData = _mergePhotoSource(
      userData: _extractUserFromBody(body),
      responseBody: body,
    );
    return ProfileModel.fromJson(userData);
  }

  @override
  Future<void> uploadPhoto({
    required String token,
    required String filePath,
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
        );
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

  Map<String, dynamic> _mergePhotoSource({
    required Map<String, dynamic> userData,
    required Map<String, dynamic> responseBody,
  }) {
    final merged = Map<String, dynamic>.from(userData);

    final candidates = <Map<String, dynamic>>[merged, responseBody];
    final data = responseBody['data'];
    if (data is Map<String, dynamic>) {
      candidates.add(data);
      final dataUser = data['user'];
      if (dataUser is Map<String, dynamic>) {
        candidates.add(dataUser);
      }
      final dataProfile = data['profile'];
      if (dataProfile is Map<String, dynamic>) {
        candidates.add(dataProfile);
      }
    }

    final rootUser = responseBody['user'];
    if (rootUser is Map<String, dynamic>) {
      candidates.add(rootUser);
    }
    final rootProfile = responseBody['profile'];
    if (rootProfile is Map<String, dynamic>) {
      candidates.add(rootProfile);
    }

    final photoSources = <String>[];
    for (final candidate in candidates) {
      final candidatePhoto = ProfilePhotoHelper.extractPhotoSource(candidate);
      if (candidatePhoto != null) {
        photoSources.add(candidatePhoto);
      }
    }

    final preferredPhoto = _pickPreferredPhotoSource(photoSources);
    if (preferredPhoto != null) {
      merged['photo_url'] = preferredPhoto;
    }

    return merged;
  }

  String? _pickPreferredPhotoSource(List<String> sources) {
    if (sources.isEmpty) {
      return null;
    }

    for (final source in sources) {
      if (source.startsWith('data:image')) {
        return source;
      }
    }

    for (final source in sources) {
      if (!_hasUnreachableLocalHost(source)) {
        return source;
      }
    }

    return sources.first;
  }

  bool _hasUnreachableLocalHost(String source) {
    final parsed = Uri.tryParse(source);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return false;
    }

    final host = parsed.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';
  }
}
