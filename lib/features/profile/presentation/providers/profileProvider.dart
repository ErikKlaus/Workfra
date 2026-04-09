import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/layananPenyimpanan.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../domain/usecases/getProfileUsecase.dart';
import '../../domain/usecases/updateProfileUsecase.dart';
import '../../domain/usecases/uploadProfilePhotoUsecase.dart';

class ProfileProvider extends ChangeNotifier {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UploadProfilePhotoUseCase _uploadProfilePhotoUseCase;
  final AuthRepository _authRepository;
  final StorageService _storageService;

  ProfileProvider({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UploadProfilePhotoUseCase uploadProfilePhotoUseCase,
    required AuthRepository authRepository,
    required StorageService storageService,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _uploadProfilePhotoUseCase = uploadProfilePhotoUseCase,
       _authRepository = authRepository,
       _storageService = storageService;

  bool _isLoading = false;
  String? _errorMessage;
  User? _profile;
  bool _hasFetchedProfile = false;
  DateTime? _lastProfileFetch;

  static const Duration _profileCacheTTL = Duration(minutes: 2);
  static const String _profileCacheKey = 'cache_profile_v1';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get profile => _profile;
  bool get hasCachedProfile => _hasFetchedProfile && _profile != null;

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Memuat profil user langsung dari endpoint API profile.
  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (_profile == null) {
      final cachedProfile = _readCachedProfile();
      if (cachedProfile != null) {
        _profile = cachedProfile;
        _hasFetchedProfile = true;
        notifyListeners();
      }
    }

    final now = DateTime.now();
    final hasFreshCache =
        hasCachedProfile &&
        _lastProfileFetch != null &&
        now.difference(_lastProfileFetch!) < _profileCacheTTL;

    if (!forceRefresh && hasFreshCache) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _profile = null;
        _hasFetchedProfile = false;
        _lastProfileFetch = null;
        _errorMessage = 'error_session_expired';
        _setLoading(false);
        return;
      }
      _profile = await _getProfileUseCase(token: token);
      _hasFetchedProfile = true;
      _lastProfileFetch = DateTime.now();
      if (_profile != null) {
        await _writeCachedProfile(_profile!);
      }
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _restoreFromCacheOnFailure();
    } catch (_) {
      _errorMessage = 'error_load_profile';
      _restoreFromCacheOnFailure();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'error_session_expired';
        _setLoading(false);
        return false;
      }
      _profile = await _updateProfileUseCase(
        token: token,
        name: name,
        email: email,
      );
      _hasFetchedProfile = true;
      _lastProfileFetch = DateTime.now();
      if (_profile != null) {
        await _writeCachedProfile(_profile!);
      }
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'error_update_profile';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> uploadPhoto(String filePath) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'error_session_expired';
        _setLoading(false);
        return false;
      }
      await _uploadProfilePhotoUseCase(token: token, filePath: filePath);
      // Reload profile to get updated photo URL
      await loadProfile(forceRefresh: true);
      if (_profile != null) {
        await _writeCachedProfile(_profile!);
      }
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'error_upload_avatar';
      _setLoading(false);
      return false;
    }
  }

  void _restoreFromCacheOnFailure() {
    final cachedProfile = _readCachedProfile();
    if (cachedProfile == null) {
      return;
    }

    _profile = cachedProfile;
    _hasFetchedProfile = true;
  }

  Future<void> _writeCachedProfile(User profile) async {
    final payload = <String, dynamic>{
      'id': profile.id,
      'name': profile.name,
      'email': profile.email,
      'photo_url': profile.photoUrl,
    };

    await _storageService.saveString(_profileCacheKey, jsonEncode(payload));
  }

  User? _readCachedProfile() {
    final raw = _storageService.getString(_profileCacheKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return User(
        id: decoded['id'] as int?,
        name: decoded['name'] as String? ?? '',
        email: decoded['email'] as String? ?? '',
        photoUrl: decoded['photo_url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
