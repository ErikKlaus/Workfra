import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../../home/domain/entities/riwayat.dart';
import '../../../attendance/domain/usecases/getAbsensiHistoryUsecase.dart';

class StatistikProvider extends ChangeNotifier {
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
    final now = DateTime.now();
    final hasFreshCache =
        _lastFetch != null && now.difference(_lastFetch!) < _cacheTTL;

    if (!forceRefresh && hasFreshCache) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'error_session_expired';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final history = await _getHistoryUseCase(token: token);
      _calculateMetrics(history);
      _lastFetch = DateTime.now();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _resetMetrics();
    } catch (_) {
      _errorMessage = 'error_load_statistics';
      _resetMetrics();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Single-pass O(n) metrics calculation — replaces the previous ~6-pass approach.
  void _calculateMetrics(List<Riwayat> history) {
    final workdayHistory = history.where((r) => !r.isIzin).toList();
    if (workdayHistory.isEmpty) {
      _resetMetrics();
      _funFactKey = history.isEmpty
          ? 'stats_fun_fact_no_data'
          : 'stats_fun_fact_leave_only';
      _funFactWeekday = null;
      return;
    }

    // Single-pass accumulation
    int hadir = 0, telat = 0, absen = 0;
    final checkInMinutes = <int>[];
    final checkOutMinutes = <int>[];
    final onTimeDayCounts = <int, int>{};
    final checkInByDay = <int, List<int>>{};

    for (final r in workdayHistory) {
      // Count statuses
      if (r.isOnTime) {
        hadir++;
      } else if (r.isTelat) {
        telat++;
      } else if (r.isAbsent) {
        absen++;
      }

      // Accumulate check-in times and per-day data
      if (r.jamMasuk != null && r.jamMasuk!.isNotEmpty) {
        final mins = _timeToMinutes(r.jamMasuk!);
        if (mins != null) {
          checkInMinutes.add(mins);
          final day = r.tanggal.weekday;
          checkInByDay.putIfAbsent(day, () => []).add(mins);
        }
      }

      // Accumulate check-out times
      if (r.jamKeluar != null && r.jamKeluar!.isNotEmpty) {
        final mins = _timeToMinutes(r.jamKeluar!);
        if (mins != null) checkOutMinutes.add(mins);
      }

      // Accumulate on-time day counts for fun-fact
      if (r.isOnTime) {
        final day = r.tanggal.weekday;
        onTimeDayCounts[day] = (onTimeDayCounts[day] ?? 0) + 1;
      }
    }

    _totalHari = workdayHistory.length;
    _hadir = hadir;
    _telat = telat;
    _absen = absen;
    _onTimePercentage = _totalHari > 0 ? (hadir / _totalHari) * 100 : 0;

    // Resolve time metrics from accumulated data
    if (checkInMinutes.isNotEmpty) {
      final sum = checkInMinutes.reduce((a, b) => a + b);
      _avgCheckIn = _minutesToTime(sum ~/ checkInMinutes.length);
      _fastestCheckIn = _minutesToTime(
        checkInMinutes.reduce((a, b) => a < b ? a : b),
      );
    } else {
      _avgCheckIn = '--:--';
      _fastestCheckIn = '--:--';
    }

    if (checkOutMinutes.isNotEmpty) {
      final sum = checkOutMinutes.reduce((a, b) => a + b);
      _avgCheckOut = _minutesToTime(sum ~/ checkOutMinutes.length);
      _latestCheckOut = _minutesToTime(
        checkOutMinutes.reduce((a, b) => a > b ? a : b),
      );
    } else {
      _avgCheckOut = '--:--';
      _latestCheckOut = '--:--';
    }

    // Fun fact: find day with earliest average check-in
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

    if (earliestDay != null) {
      _funFactKey = 'stats_fun_fact_early_day';
      _funFactWeekday = earliestDay;
    } else if (onTimeDayCounts.isNotEmpty) {
      final bestDay = onTimeDayCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      _funFactKey = 'stats_fun_fact_best_day';
      _funFactWeekday = bestDay;
    } else {
      _funFactKey = 'stats_fun_fact_keep_up';
      _funFactWeekday = null;
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

  void _resetMetrics() {
    _totalHari = 0;
    _hadir = 0;
    _telat = 0;
    _absen = 0;
    _avgCheckIn = '--:--';
    _avgCheckOut = '--:--';
    _fastestCheckIn = '--:--';
    _latestCheckOut = '--:--';
    _onTimePercentage = 0;
    _funFactKey = '';
    _funFactWeekday = null;
  }
}
