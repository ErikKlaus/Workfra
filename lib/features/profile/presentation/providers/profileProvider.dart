import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
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

  ProfileProvider({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UploadProfilePhotoUseCase uploadProfilePhotoUseCase,
    required AuthRepository authRepository,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _uploadProfilePhotoUseCase = uploadProfilePhotoUseCase,
       _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  User? _profile;
  bool _hasFetchedProfile = false;
  DateTime? _lastProfileFetch;

  static const Duration _profileCacheTTL = Duration(minutes: 2);

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
    } on ServerException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'error_load_profile';
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
}
