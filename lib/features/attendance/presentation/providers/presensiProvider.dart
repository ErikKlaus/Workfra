import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/lokasiService.dart';
import '../../../../core/services/networkService.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../domain/entities/absensiHariIni.dart';
import '../../domain/services/attendanceStatusPolicy.dart';
import '../../domain/usecases/getTodayStatusUsecase.dart';
import '../../domain/usecases/checkInUsecase.dart';
import '../../domain/usecases/checkOutUsecase.dart';

class PresensiProvider extends ChangeNotifier {
  final GetTodayStatusUseCase _getTodayStatusUseCase;
  final CheckInUseCase _checkInUseCase;
  final CheckOutUseCase _checkOutUseCase;
  final AuthRepository _authRepository;
  final LokasiService _lokasiService;
  final NetworkService _networkService;

  PresensiProvider({
    required GetTodayStatusUseCase getTodayStatusUseCase,
    required CheckInUseCase checkInUseCase,
    required CheckOutUseCase checkOutUseCase,
    required AuthRepository authRepository,
    required LokasiService lokasiService,
    required NetworkService networkService,
  }) : _getTodayStatusUseCase = getTodayStatusUseCase,
       _checkInUseCase = checkInUseCase,
       _checkOutUseCase = checkOutUseCase,
       _authRepository = authRepository,
       _lokasiService = lokasiService,
       _networkService = networkService;

  // State
  bool _isLoadingData = false;
  bool _isLoadingMap = false;
  bool _isSubmitting = false;
  bool _isRequirementFailure = false;
  String? _errorMessage;
  AbsensiHariIni _todayStatus = AbsensiHariIni.empty;
  Position? _currentPosition;
  DateTime? _lastLocationFetch;
  String _currentAddress = 'loading_location';
  bool _hasFetchedTodayStatus = false;
  DateTime? _lastTodayStatusFetch;
  Duration _serverTimeOffset = Duration.zero;

  static const Duration _todayStatusCacheTTL = Duration(seconds: 40);
  static const Duration _locationCacheTTL = Duration(seconds: 60);

  // Getters
  bool get isLoading => _isLoadingData || _isLoadingMap;
  bool get isLoadingData => _isLoadingData;
  bool get isLoadingMap => _isLoadingMap;
  bool get isSubmitting => _isSubmitting;
  bool get isRequirementFailure => _isRequirementFailure;
  String? get errorMessage => _errorMessage;
  AbsensiHariIni get todayStatus => _todayStatus;
  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  bool get hasCachedTodayStatus => _hasFetchedTodayStatus;
  bool get hasCachedLocation => _currentPosition != null;
  DateTime get serverNow => DateTime.now().add(_serverTimeOffset);
  Duration get serverTimeOffset => _serverTimeOffset;

  /// Load today's attendance status from API.
  Future<void> loadTodayStatus({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final hasFreshCache =
        _hasFetchedTodayStatus &&
        _lastTodayStatusFetch != null &&
        now.difference(_lastTodayStatusFetch!) < _todayStatusCacheTTL;

    if (!forceRefresh && hasFreshCache) {
      return;
    }

    _isLoadingData = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'error_session_expired';
        _isLoadingData = false;
        notifyListeners();
        return;
      }
      _todayStatus = await _getTodayStatusUseCase(token: token);
      _syncServerClock(_todayStatus.serverNow);
      _hasFetchedTodayStatus = true;
      _lastTodayStatusFetch = DateTime.now();
    } on ServerException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'error_load_attendance_status';
    } finally {
      _isLoadingData = false;
      notifyListeners();
    }
  }

  /// Get current GPS position and resolve address.
  Future<void> getCurrentLocation({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final hasFreshLocationCache =
        _currentPosition != null &&
        _lastLocationFetch != null &&
        now.difference(_lastLocationFetch!) < _locationCacheTTL;

    if (!forceRefresh && hasFreshLocationCache) {
      return;
    }

    _isLoadingMap = true;
    try {
      _currentAddress = 'loading_location';
      notifyListeners();

      _currentPosition = await _lokasiService.getCurrentPosition();
      _lastLocationFetch = DateTime.now();
      _currentAddress = await _lokasiService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } on LokasiException catch (e) {
      _errorMessage = e.message;
      _currentAddress = 'location_fetch_failed';
    } catch (_) {
      _currentAddress = 'location_fetch_failed';
    } finally {
      _isLoadingMap = false;
      notifyListeners();
    }
  }

  Future<void> preparePresensiData({bool forceRefresh = false}) async {
    await Future.wait([
      getCurrentLocation(forceRefresh: forceRefresh),
      loadTodayStatus(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> prefetchPresensiData() async {
    await preparePresensiData();
  }

  /// Perform check-in with current GPS coordinates.
  Future<bool> doCheckIn() async {
    _isRequirementFailure = false;

    if (!await _validateRequestPrerequisites()) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _isRequirementFailure = false;
        _errorMessage = 'error_session_expired';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      final response = await _checkInUseCase(
        token: token,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _resolveAttendanceAddress(),
      );

      final responseServerNow = _extractServerNow(response);
      final responseCheckIn = _extractResponseTime(response, const [
        'check_in',
        'check_in_time',
        'jam_masuk',
        'checkIn',
      ]);
      final resolvedCheckIn = responseCheckIn ?? _fallbackNowTime();

      _syncServerClock(responseServerNow);
      final effectiveServerNow = responseServerNow ?? serverNow;
      _todayStatus = _todayStatus.copyWith(
        hasCheckedIn: true,
        checkInTime: resolvedCheckIn,
        status: AttendanceStatusPolicy.resolve(
          rawStatus: _todayStatus.status,
          checkInTime: resolvedCheckIn,
          hasCheckedIn: true,
          hasCheckedOut: _todayStatus.hasCheckedOut,
          referenceNow: effectiveServerNow,
          attendanceDate: effectiveServerNow,
        ),
        serverNow: effectiveServerNow,
      );
      _hasFetchedTodayStatus = true;
      _lastTodayStatusFetch = DateTime.now();
      _isSubmitting = false;
      notifyListeners();

      unawaited(loadTodayStatus(forceRefresh: true));
      return true;
    } on ServerException catch (e) {
      _isRequirementFailure = false;
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _isRequirementFailure = false;
      _errorMessage = 'error_check_in_failed';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Perform check-out with current GPS coordinates.
  Future<bool> doCheckOut() async {
    _isRequirementFailure = false;

    if (!await _validateRequestPrerequisites()) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _isRequirementFailure = false;
        _errorMessage = 'error_session_expired';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      final response = await _checkOutUseCase(
        token: token,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _resolveAttendanceAddress(),
      );

      final responseServerNow = _extractServerNow(response);
      final responseCheckIn = _extractResponseTime(response, const [
        'check_in',
        'check_in_time',
        'jam_masuk',
        'checkIn',
      ]);
      final responseCheckOut = _extractResponseTime(response, const [
        'check_out',
        'check_out_time',
        'jam_keluar',
        'checkOut',
      ]);
      final resolvedCheckOut = responseCheckOut ?? _fallbackNowTime();
      final effectiveCheckIn = _todayStatus.checkInTime ?? responseCheckIn;

      _syncServerClock(responseServerNow);
      final effectiveServerNow = responseServerNow ?? serverNow;
      _todayStatus = _todayStatus.copyWith(
        hasCheckedIn: _todayStatus.hasCheckedIn || effectiveCheckIn != null,
        hasCheckedOut: true,
        checkInTime: effectiveCheckIn,
        checkOutTime: resolvedCheckOut,
        status: AttendanceStatusPolicy.resolve(
          rawStatus: _todayStatus.status,
          checkInTime: effectiveCheckIn,
          hasCheckedIn: _todayStatus.hasCheckedIn || effectiveCheckIn != null,
          hasCheckedOut: true,
          referenceNow: effectiveServerNow,
          attendanceDate: effectiveServerNow,
        ),
        serverNow: effectiveServerNow,
      );
      _hasFetchedTodayStatus = true;
      _lastTodayStatusFetch = DateTime.now();
      _isSubmitting = false;
      notifyListeners();

      unawaited(loadTodayStatus(forceRefresh: true));
      return true;
    } on ServerException catch (e) {
      _isRequirementFailure = false;
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _isRequirementFailure = false;
      _errorMessage = 'error_check_out_failed';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _isRequirementFailure = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _validateRequestPrerequisites() async {
    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      _isRequirementFailure = true;
      _errorMessage = 'error_wifi_data_required';
      notifyListeners();
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isRequirementFailure = true;
      _errorMessage = 'error_gps_required';
      notifyListeners();
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _isRequirementFailure = true;
      _errorMessage = 'error_location_permission_denied';
      notifyListeners();
      return false;
    }

    if (_currentPosition == null) {
      _isRequirementFailure = true;
      _errorMessage =
          'error_location_not_ready';
      notifyListeners();
      return false;
    }

    if (_lokasiService.isMockLocation(_currentPosition!)) {
      _isRequirementFailure = true;
      _errorMessage =
          'error_mock_gps_detected';
      notifyListeners();
      return false;
    }

    return true;
  }

  String _resolveAttendanceAddress() {
    final cleaned = _currentAddress.trim();

    if (cleaned.isNotEmpty &&
        cleaned != 'loading_location' &&
        cleaned != 'location_fetch_failed') {
      return cleaned;
    }

    final position = _currentPosition;
    if (position != null) {
      return 'Lat ${position.latitude}, Lng ${position.longitude}';
    }

    return 'error_location_unavailable';
  }

  void _syncServerClock(DateTime? serverTime) {
    if (serverTime == null) {
      return;
    }

    _serverTimeOffset = serverTime.difference(DateTime.now());
  }

  String _fallbackNowTime() {
    final now = serverNow;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  DateTime? _extractServerNow(Map<String, dynamic> payload) {
    final raw = _extractFirstString(payload, const [
      '_server_time',
      'server_time',
      'server_now',
      'current_time',
      'timestamp',
      'server_timestamp',
    ]);

    if (raw == null) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);
    return parsed?.toLocal();
  }

  String? _extractResponseTime(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    final raw = _extractFirstString(payload, keys);
    if (raw == null) {
      return null;
    }

    return _normalizeTime(raw);
  }

  String? _extractFirstString(Map<String, dynamic> payload, List<String> keys) {
    final nestedData = payload['data'];
    final nestedAttendance = payload['attendance'];
    final nestedMeta = payload['meta'];

    final candidateMaps = <Map<String, dynamic>>[
      payload,
      if (nestedData is Map<String, dynamic>) nestedData,
      if (nestedAttendance is Map<String, dynamic>) nestedAttendance,
      if (nestedMeta is Map<String, dynamic>) nestedMeta,
    ];

    for (final source in candidateMaps) {
      for (final key in keys) {
        final value = source[key];
        if (value == null) {
          continue;
        }

        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return null;
  }

  String _normalizeTime(String raw) {
    final value = raw.trim();
    final directMatch = RegExp(r'^\d{1,2}:\d{2}').firstMatch(value);
    if (directMatch != null) {
      final hhmm = directMatch.group(0)!;
      final parts = hhmm.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    }

    final parsedDateTime = DateTime.tryParse(value);
    if (parsedDateTime != null) {
      final hour = parsedDateTime.hour.toString().padLeft(2, '0');
      final minute = parsedDateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return value;
  }
}
