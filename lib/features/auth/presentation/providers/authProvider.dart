import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/layananPenyimpanan.dart';
import '../../domain/entities/jenisKelamin.dart';
import '../../domain/entities/opsiDropdown.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/authRepository.dart';
import '../../domain/usecases/getBatchesUsecase.dart';
import '../../domain/usecases/getGendersUsecase.dart';
import '../../domain/usecases/getTrainingsUsecase.dart';
import '../../domain/usecases/lupaPasswordUsecase.dart';
import '../../domain/usecases/loginUsecase.dart';
import '../../domain/usecases/registerUsecase.dart';
import '../../domain/usecases/resetPasswordUsecase.dart';
import '../../domain/usecases/uploadFotoUsecase.dart';
import '../../domain/usecases/verifikasiOtpUsecase.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetTrainingsUseCase _getTrainingsUseCase;
  final GetBatchesUseCase _getBatchesUseCase;
  final GetGendersUseCase _getGendersUseCase;
  final UploadPhotoUseCase _uploadPhotoUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final AuthRepository _authRepository;
  final StorageService _storageService;

  AuthProvider({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetTrainingsUseCase getTrainingsUseCase,
    required GetBatchesUseCase getBatchesUseCase,
    required GetGendersUseCase getGendersUseCase,
    required UploadPhotoUseCase uploadPhotoUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required AuthRepository authRepository,
    required StorageService storageService,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _getTrainingsUseCase = getTrainingsUseCase,
       _getBatchesUseCase = getBatchesUseCase,
       _getGendersUseCase = getGendersUseCase,
       _uploadPhotoUseCase = uploadPhotoUseCase,
       _forgotPasswordUseCase = forgotPasswordUseCase,
       _verifyOtpUseCase = verifyOtpUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       _authRepository = authRepository,
       _storageService = storageService;

  bool _isLoading = false;
  String? _errorMessage;
  User? _user;
  bool _isAuthenticated = false;
  List<OpsiDropdown> _daftarTraining = const [];
  List<OpsiDropdown> _daftarBatch = const [];
  List<JenisKelamin> _daftarGender = const [];
  bool _isLoadingTraining = false;
  bool _isLoadingBatch = false;
  bool _isLoadingGender = false;
  String? _trainingError;
  String? _batchError;
  String? _genderError;
  int? _selectedGenderId;
  String _resetEmail = '';
  String _resetOtp = '';
  Timer? _resendTimer;
  int _resendCountdown = 0;
  DateTime? _lastSessionValidatedAt;

  static const Duration _sessionValidationTtl = Duration(seconds: 30);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  List<OpsiDropdown> get daftarTraining => _daftarTraining;
  List<OpsiDropdown> get daftarBatch => _daftarBatch;
  List<JenisKelamin> get daftarGender => _daftarGender;
  bool get isLoadingTraining => _isLoadingTraining;
  bool get isLoadingBatch => _isLoadingBatch;
  bool get isLoadingGender => _isLoadingGender;
  String? get trainingError => _trainingError;
  String? get batchError => _batchError;
  String? get genderError => _genderError;
  int? get selectedGenderId => _selectedGenderId;
  String get resetEmail => _resetEmail;
  String get resetOtp => _resetOtp;
  int get resendCountdown => _resendCountdown;
  bool get canResendOtp => _resendCountdown <= 0;

  String get timerText {
    final minutes = (_resendCountdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendCountdown % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

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

  void selectGender(int id) {
    if (id <= 0) {
      return;
    }
    if (_selectedGenderId != id) {
      _selectedGenderId = id;
      notifyListeners();
    }
  }

  Future<bool> checkAuth({bool forceServerValidation = false}) async {
    final isFirstInstallHandled = _storageService.isFirstInstallHandled();
    if (!isFirstInstallHandled) {
      await _storageService.clearAuthStartupArtifacts();
      await _storageService.markFirstInstallHandled();
      _setUnauthenticatedState();
      notifyListeners();
      return false;
    }

    final rawToken = await _authRepository.getToken();
    final token = rawToken?.trim();
    if (!_isTokenUsable(token)) {
      await _forceLogoutCleanup(notify: false);
      notifyListeners();
      return false;
    }

    final now = DateTime.now();
    final hasFreshSessionValidation =
        !forceServerValidation &&
        _isAuthenticated &&
        _lastSessionValidatedAt != null &&
        now.difference(_lastSessionValidatedAt!) < _sessionValidationTtl;

    if (hasFreshSessionValidation) {
      return true;
    }

    if (_isJwtExpired(token!)) {
      await _forceLogoutCleanup(notify: false);
      notifyListeners();
      return false;
    }

    try {
      final user = await _authRepository.verifySession(token: token);
      if (!_isValidSessionUser(user)) {
        await _forceLogoutCleanup(notify: false);
        notifyListeners();
        return false;
      }

      _user = user;
      _isAuthenticated = true;
      _lastSessionValidatedAt = DateTime.now();
      await _storageService.markSessionValidated();
      notifyListeners();
      return true;
    } catch (_) {
      await _forceLogoutCleanup(notify: false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;
    _user = null;
    _isAuthenticated = false;
    try {
      _user = await _loginUseCase(email: email, password: password);
      await _storageService.clearSessionScopedCaches();
      await _storageService.markFirstInstallHandled();
      await _storageService.markSessionValidated();
      _isAuthenticated = true;
      _lastSessionValidatedAt = DateTime.now();
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'error_generic';
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required int genderId,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _user = null;
    _isAuthenticated = false;
    try {
      _user = await _registerUseCase(
        name: name,
        email: email,
        password: password,
        trainingId: trainingId,
        batchId: batchId,
        genderId: genderId,
      );
      await _storageService.clearSessionScopedCaches();
      await _storageService.markFirstInstallHandled();
      await _storageService.markSessionValidated();
      _isAuthenticated = true;
      _lastSessionValidatedAt = DateTime.now();
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'error_generic';
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerWithPhoto({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required int genderId,
    required String photoPath,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _registerUseCase(
        name: name,
        email: email,
        password: password,
        trainingId: trainingId,
        batchId: batchId,
        genderId: genderId,
      );
      await _storageService.clearSessionScopedCaches();
      await _storageService.markFirstInstallHandled();
      await _storageService.markSessionValidated();
      _isAuthenticated = true;
      _lastSessionValidatedAt = DateTime.now();

      String? token = _user?.token;
      if (token == null || token.isEmpty) {
        token = await _authRepository.getToken();
      }

      if (token == null || token.isEmpty) {
        _isAuthenticated = false;
        _errorMessage = 'error_session_after_register';
        _setLoading(false);
        return false;
      }

      await _uploadPhotoUseCase(filePath: photoPath, token: token);
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        _isAuthenticated = false;
        _errorMessage = 'error_session_expired';
      } else {
        _errorMessage = e.message;
      }
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'error_generic';
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadRegisterReferenceData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _daftarTraining = const [];
      _daftarBatch = const [];
      _daftarGender = const [];
      _selectedGenderId = null;
    }
    await Future.wait([loadTrainings(), loadBatches(), loadGenders()]);
  }

  void resetRegisterState() {
    _selectedGenderId = null;
    notifyListeners();
  }

  Future<void> loadTrainings() async {
    _isLoadingTraining = true;
    _trainingError = null;
    notifyListeners();
    try {
      final result = await _getTrainingsUseCase();
      _daftarTraining = result;
    } on ServerException catch (e) {
      _trainingError = e.message;
      _daftarTraining = const [];
    } catch (_) {
      _trainingError = 'error_load_training';
      _daftarTraining = const [];
    } finally {
      _isLoadingTraining = false;
      notifyListeners();
    }
  }

  Future<void> loadBatches() async {
    _isLoadingBatch = true;
    _batchError = null;
    notifyListeners();
    try {
      final result = await _getBatchesUseCase();
      _daftarBatch = result;
    } on ServerException catch (e) {
      _batchError = e.message;
      _daftarBatch = const [];
    } catch (_) {
      _batchError = 'error_load_batch';
      _daftarBatch = const [];
    } finally {
      _isLoadingBatch = false;
      notifyListeners();
    }
  }

  Future<void> loadGenders() async {
    _isLoadingGender = true;
    _genderError = null;
    notifyListeners();
    try {
      final result = await _getGendersUseCase();
      _daftarGender = result.where((item) => item.id > 0).toList();
      if (_selectedGenderId != null &&
          !_daftarGender.any((item) => item.id == _selectedGenderId)) {
        _selectedGenderId = null;
      }
    } on ServerException catch (e) {
      _genderError = e.message;
      _daftarGender = const [];
      _selectedGenderId = null;
    } catch (_) {
      _genderError = 'error_load_gender';
      _daftarGender = const [];
      _selectedGenderId = null;
    } finally {
      _isLoadingGender = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPhoto(String filePath) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'error_session_expired';
        _isAuthenticated = false;
        _setLoading(false);
        return false;
      }
      await _uploadPhotoUseCase(filePath: filePath, token: token);
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        _isAuthenticated = false;
        _errorMessage = 'error_session_expired';
      } else {
        _errorMessage = e.message;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'error_upload_avatar';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _forgotPasswordUseCase(email: email);
      _resetEmail = email;
      _startResendTimer();
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'error_generic';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp({required String otp}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _verifyOtpUseCase(email: _resetEmail, otp: otp);
      _resetOtp = otp;
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'error_generic';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _resetPasswordUseCase(
        email: _resetEmail,
        otp: _resetOtp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _resetEmail = '';
      _resetOtp = '';
      _cancelResendTimer();
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'error_generic';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (!canResendOtp) return false;
    return forgotPassword(email: _resetEmail);
  }

  void _startResendTimer() {
    _cancelResendTimer();
    _resendCountdown = 119;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 0) {
        timer.cancel();
      } else {
        _resendCountdown--;
      }
      notifyListeners();
    });
  }

  void _cancelResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
    _resendCountdown = 0;
  }

  Future<void> logout() async {
    await _forceLogoutCleanup();
  }

  Future<void> _forceLogoutCleanup({bool notify = true}) async {
    await _authRepository.logout();
    await _storageService.clearAuthStartupArtifacts();
    await _storageService.clearSessionValidationFlag();

    _setUnauthenticatedState();

    if (notify) {
      notifyListeners();
    }
  }

  void _setUnauthenticatedState() {
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _selectedGenderId = null;
    _resetEmail = '';
    _resetOtp = '';
    _lastSessionValidatedAt = null;
    _cancelResendTimer();
  }

  bool _isTokenUsable(String? token) {
    if (token == null) {
      return false;
    }

    final normalized = token.trim();
    if (normalized.isEmpty) {
      return false;
    }

    if (normalized.contains(RegExp(r'\s'))) {
      return false;
    }

    return true;
  }

  bool _isJwtExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return false;
    }

    try {
      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payload = jsonDecode(payloadJson);
      if (payload is! Map<String, dynamic>) {
        return false;
      }

      final expRaw = payload['exp'];
      if (expRaw is! num) {
        return false;
      }

      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSeconds >= expRaw.toInt();
    } catch (_) {
      return false;
    }
  }

  bool _isValidSessionUser(User user) {
    final email = user.email.trim();
    final name = user.name.trim();
    return email.isNotEmpty && email.contains('@') && name.isNotEmpty;
  }

  @override
  void dispose() {
    _cancelResendTimer();
    super.dispose();
  }
}
