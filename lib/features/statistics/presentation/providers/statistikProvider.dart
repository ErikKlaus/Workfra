import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/safe_notify_mixin.dart';
import '../../../attendance/domain/usecases/getAbsensiHistoryUsecase.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../../home/domain/entities/riwayat.dart';

class _MetricsResult {
  final int totalHari;
  final int hadir;
  final int telat;
  final int absen;
  final String avgCheckIn;
  final String avgCheckOut;
  final String fastestCheckIn;
  final String latestCheckOut;
  final double onTimePercentage;
  final String funFactKey;
  final int? funFactWeekday;

  const _MetricsResult({
    required this.totalHari,
    required this.hadir,
    required this.telat,
    required this.absen,
    required this.avgCheckIn,
    required this.avgCheckOut,
    required this.fastestCheckIn,
    required this.latestCheckOut,
    required this.onTimePercentage,
    required this.funFactKey,
    this.funFactWeekday,
  });

  factory _MetricsResult.empty() {
    return const _MetricsResult(
      totalHari: 0,
      hadir: 0,
      telat: 0,
      absen: 0,
      avgCheckIn: '--:--',
      avgCheckOut: '--:--',
      fastestCheckIn: '--:--',
      latestCheckOut: '--:--',
      onTimePercentage: 0,
      funFactKey: 'stats_fun_fact_no_data',
    );
  }
}

int? _timeToMinutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return null;
  final hours = int.tryParse(parts[0]);
  final minutes = int.tryParse(parts[1]);
  if (hours == null || minutes == null) return null;
  return hours * 60 + minutes;
}

String _minutesToTime(int totalMinutes) {
  final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final m = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

_MetricsResult _calculateMetricsTask(List<Riwayat> history) {
  final workdayHistory = history
      .where((r) => !r.isIzin)
      .toList(growable: false);
  if (workdayHistory.isEmpty) {
    return _MetricsResult(
      totalHari: 0,
      hadir: 0,
      telat: 0,
      absen: 0,
      avgCheckIn: '--:--',
      avgCheckOut: '--:--',
      fastestCheckIn: '--:--',
      latestCheckOut: '--:--',
      onTimePercentage: 0,
      funFactKey: history.isEmpty
          ? 'stats_fun_fact_no_data'
          : 'stats_fun_fact_leave_only',
    );
  }

  int hadir = 0, telat = 0, absen = 0;
  final checkInMinutes = <int>[];
  final checkOutMinutes = <int>[];
  final onTimeDayCounts = <int, int>{};
  final checkInByDay = <int, List<int>>{};

  for (final r in workdayHistory) {
    if (r.isOnTime) {
      hadir++;
    } else if (r.isTelat) {
      telat++;
    } else if (r.isAbsent) {
      absen++;
    }

    if (r.jamMasuk != null && r.jamMasuk!.isNotEmpty) {
      final mins = _timeToMinutes(r.jamMasuk!);
      if (mins != null) {
        checkInMinutes.add(mins);
        final day = r.tanggal.weekday;
        checkInByDay.putIfAbsent(day, () => []).add(mins);
      }
    }

    if (r.jamKeluar != null && r.jamKeluar!.isNotEmpty) {
      final mins = _timeToMinutes(r.jamKeluar!);
      if (mins != null) checkOutMinutes.add(mins);
    }

    if (r.isOnTime) {
      final day = r.tanggal.weekday;
      onTimeDayCounts[day] = (onTimeDayCounts[day] ?? 0) + 1;
    }
  }

  final totalHari = workdayHistory.length;
  final onTimePercentage = totalHari > 0 ? (hadir / totalHari) * 100 : 0.0;

  String avgIn = '--:--', fastestIn = '--:--';
  if (checkInMinutes.isNotEmpty) {
    final sum = checkInMinutes.reduce((a, b) => a + b);
    avgIn = _minutesToTime(sum ~/ checkInMinutes.length);
    fastestIn = _minutesToTime(checkInMinutes.reduce((a, b) => a < b ? a : b));
  }

  String avgOut = '--:--', latestOut = '--:--';
  if (checkOutMinutes.isNotEmpty) {
    final sum = checkOutMinutes.reduce((a, b) => a + b);
    avgOut = _minutesToTime(sum ~/ checkOutMinutes.length);
    latestOut = _minutesToTime(checkOutMinutes.reduce((a, b) => a > b ? a : b));
  }

  int? earliestDay;
  int earliestAvg = 24 * 60;
  for (final entry in checkInByDay.entries) {
    if (entry.value.isNotEmpty) {
      final avg = entry.value.reduce((a, b) => a + b) ~/ entry.value.length;
      if (avg < earliestAvg) {
        earliestAvg = avg;
        earliestDay = entry.key;
      }
    }
  }

  String funFactKey;
  int? funFactWeekday;
  if (earliestDay != null) {
    funFactKey = 'stats_fun_fact_early_day';
    funFactWeekday = earliestDay;
  } else if (onTimeDayCounts.isNotEmpty) {
    final bestDay = onTimeDayCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    funFactKey = 'stats_fun_fact_best_day';
    funFactWeekday = bestDay;
  } else {
    funFactKey = 'stats_fun_fact_keep_up';
  }

  return _MetricsResult(
    totalHari: totalHari,
    hadir: hadir,
    telat: telat,
    absen: absen,
    avgCheckIn: avgIn,
    avgCheckOut: avgOut,
    fastestCheckIn: fastestIn,
    latestCheckOut: latestOut,
    onTimePercentage: onTimePercentage,
    funFactKey: funFactKey,
    funFactWeekday: funFactWeekday,
  );
}

class StatistikProvider extends ChangeNotifier with SafeNotifyMixin {
  final GetAbsensiHistoryUseCase _getHistoryUseCase;
  final AuthRepository _authRepository;

  StatistikProvider({
    required GetAbsensiHistoryUseCase getHistoryUseCase,
    required AuthRepository authRepository,
  }) : _getHistoryUseCase = getHistoryUseCase,
       _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  // TTL Cache
  DateTime? _lastFetch;
  String? _activeToken;
  static const Duration _cacheTTL = Duration(seconds: 40);

  // Metrics
  int _totalHari = 0;
  int _hadir = 0;
  int _telat = 0;
  int _absen = 0;
  String _avgCheckIn = '--:--';
  String _avgCheckOut = '--:--';
  String _fastestCheckIn = '--:--';
  String _latestCheckOut = '--:--';
  double _onTimePercentage = 0;
  String _funFactKey = '';
  int? _funFactWeekday;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalHari => _totalHari;
  int get hadir => _hadir;
  int get telat => _telat;
  int get totalKehadiran => _hadir + _telat;
  int get absen => _absen;
  String get avgCheckIn => _avgCheckIn;
  String get avgCheckOut => _avgCheckOut;
  String get fastestCheckIn => _fastestCheckIn;
  String get latestCheckOut => _latestCheckOut;
  double get onTimePercentage => _onTimePercentage;
  String get funFactKey => _funFactKey;
  int? get funFactWeekday => _funFactWeekday;

  Future<void> loadData({bool forceRefresh = false}) async {
    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      _clearSessionState();
      _errorMessage = 'error_session_expired';
      safeNotify();
      return;
    }

    final tokenChanged = _syncSessionToken(token);
    final now = DateTime.now();
    final hasFreshCache =
        !tokenChanged &&
        _lastFetch != null &&
        now.difference(_lastFetch!) < _cacheTTL;

    if (!forceRefresh && hasFreshCache) return;

    _isLoading = true;
    _errorMessage = null;
    safeNotify();
    try {
      final history = await _getHistoryUseCase(token: token);
      final result = await compute(_calculateMetricsTask, history);
      _applyResult(result);
      _lastFetch = DateTime.now();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _resetMetrics();
    } catch (_) {
      _errorMessage = 'error_load_statistics';
      _resetMetrics();
    } finally {
      _isLoading = false;
      safeNotify();
    }
  }

  void _applyResult(_MetricsResult result) {
    _totalHari = result.totalHari;
    _hadir = result.hadir;
    _telat = result.telat;
    _absen = result.absen;
    _avgCheckIn = result.avgCheckIn;
    _avgCheckOut = result.avgCheckOut;
    _fastestCheckIn = result.fastestCheckIn;
    _latestCheckOut = result.latestCheckOut;
    _onTimePercentage = result.onTimePercentage;
    _funFactKey = result.funFactKey;
    _funFactWeekday = result.funFactWeekday;
  }

  void _resetMetrics() {
    _applyResult(_MetricsResult.empty());
  }

  bool _syncSessionToken(String token) {
    if (_activeToken == token) {
      return false;
    }

    _activeToken = token;
    _lastFetch = null;
    _resetMetrics();
    return true;
  }

  void _clearSessionState() {
    _activeToken = null;
    _lastFetch = null;
    _resetMetrics();
  }
}
