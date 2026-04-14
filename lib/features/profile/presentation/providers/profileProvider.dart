import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/layananPenyimpanan.dart';
import '../../../../core/utils/profilePhotoHelper.dart';
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
  String? _activeToken;
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
    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      _clearSessionState();
      _errorMessage = 'error_session_expired';
      notifyListeners();
      return;
    }

    final previousProfile = _profile;
    final tokenChanged = _syncSessionToken(token);
    if (tokenChanged) {
      notifyListeners();
    }

    final now = DateTime.now();
    final hasFreshCache =
        !tokenChanged &&
        hasCachedProfile &&
        _lastProfileFetch != null &&
        now.difference(_lastProfileFetch!) < _profileCacheTTL;

    if (!forceRefresh && hasFreshCache) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      var fetchedProfile = await _getProfileUseCase(token: token);
      fetchedProfile = _preservePhotoIfMissing(
        token: token,
        profile: fetchedProfile,
        fallbackProfile: tokenChanged ? null : previousProfile,
      );
      _profile = fetchedProfile;
      _hasFetchedProfile = true;
      _lastProfileFetch = DateTime.now();
      if (_profile != null) {
        await _writeCachedProfile(token, _profile!);
      }
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _restoreFromCacheOnFailure(token);
    } catch (_) {
      _errorMessage = 'error_load_profile';
      _restoreFromCacheOnFailure(token);
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
        _clearSessionState();
        _errorMessage = 'error_session_expired';
        _setLoading(false);
        return false;
      }
      // Capture the current photo BEFORE any state changes.
      final previousPhoto = _profile?.photoUrl;
      final cachedPhoto = _readCachedProfile(token)?.photoUrl;
      final photoToPreserve =
          ProfilePhotoHelper.normalizePhotoSource(previousPhoto) ??
          ProfilePhotoHelper.normalizePhotoSource(cachedPhoto);

      final previousProfile = _profile;

      _syncSessionToken(token);
      var updatedProfile = await _updateProfileUseCase(
        token: token,
        name: name,
        email: email,
      );
      final updatedPhoto = ProfilePhotoHelper.normalizePhotoSource(
        updatedProfile.photoUrl,
      );
      final resolvedPhoto = photoToPreserve ?? updatedPhoto;
      // Since we only updated name/email, explicitly carry forward the
      // previous photo and other missing fields. We do NOT rely on the API
      // response for the photo because the backend may return a different URL
      // format (e.g. a relative path) that doesn't match the locally-stored base64 string.
      _profile = User(
        id: updatedProfile.id ?? previousProfile?.id,
        name: updatedProfile.name.isNotEmpty
            ? updatedProfile.name
            : (previousProfile?.name ?? name),
        email: updatedProfile.email.isNotEmpty
            ? updatedProfile.email
            : (previousProfile?.email ?? email),
        token: updatedProfile.token ?? previousProfile?.token ?? token,
        photoUrl: resolvedPhoto,
      );
      _hasFetchedProfile = true;
      _lastProfileFetch = DateTime.now();
      if (_profile != null) {
        await _writeCachedProfile(token, _profile!);
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
        _clearSessionState();
        _errorMessage = 'error_session_expired';
        _setLoading(false);
        return false;
      }
      _syncSessionToken(token);
      await _uploadProfilePhotoUseCase(token: token, filePath: filePath);
      // Reload profile to get updated photo URL
      await loadProfile(forceRefresh: true);
      if (_profile != null) {
        await _writeCachedProfile(token, _profile!);
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

  User _preservePhotoIfMissing({
    required String token,
    required User profile,
    User? fallbackProfile,
  }) {
    final normalizedCurrentPhoto = ProfilePhotoHelper.normalizePhotoSource(
      profile.photoUrl,
    );
    final normalizedFallbackPhoto =
        ProfilePhotoHelper.normalizePhotoSource(fallbackProfile?.photoUrl) ??
        ProfilePhotoHelper.normalizePhotoSource(
          _readCachedProfile(token)?.photoUrl,
        );
    final resolvedPhoto = _resolvePreferredPhoto(
      current: normalizedCurrentPhoto,
      fallback: normalizedFallbackPhoto,
    );
    if (resolvedPhoto == profile.photoUrl) {
      return profile;
    }

    return User(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      token: profile.token,
      photoUrl: resolvedPhoto,
    );
  }

  String? _resolvePreferredPhoto({String? current, String? fallback}) {
    if (current == null) return fallback;
    if (fallback == null) return current;

    final currentIsDataUrl = current.startsWith('data:image');
    final fallbackIsDataUrl = fallback.startsWith('data:image');

    if (!currentIsDataUrl && fallbackIsDataUrl) {
      return fallback;
    }

    if (_hasUnreachableLocalHost(current)) {
      return fallback;
    }

    return current;
  }

  bool _hasUnreachableLocalHost(String source) {
    final parsed = Uri.tryParse(source);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return false;
    }

    final host = parsed.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';
  }

  void _restoreFromCacheOnFailure(String token) {
    final cachedProfile = _readCachedProfile(token);
    if (cachedProfile == null) {
      return;
    }

    _profile = cachedProfile;
    _hasFetchedProfile = true;
  }

  Future<void> _writeCachedProfile(String token, User profile) async {
    final payload = <String, dynamic>{
      'id': profile.id,
      'name': profile.name,
      'email': profile.email,
      'photo_url': profile.photoUrl,
    };

    await _storageService.saveString(
      _profileCacheKeyForToken(token),
      jsonEncode(payload),
    );
  }

  User? _readCachedProfile(String token) {
    final raw = _storageService.getString(_profileCacheKeyForToken(token));
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

  String _profileCacheKeyForToken(String token) {
    final tokenHash = token.hashCode.toUnsigned(32).toRadixString(16);
    return '${_profileCacheKey}_$tokenHash';
  }

  bool _syncSessionToken(String token) {
    if (_activeToken == token) {
      return false;
    }

    _activeToken = token;
    _lastProfileFetch = null;
    _profile = null;
    _hasFetchedProfile = false;
    return true;
  }

  void _clearSessionState() {
    _activeToken = null;
    _profile = null;
    _hasFetchedProfile = false;
    _lastProfileFetch = null;
  }
}
