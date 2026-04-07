import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String _funFact = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalHari => _totalHari;
  int get hadir => _hadir;
  int get telat => _telat;
  int get absen => _absen;
  String get avgCheckIn => _avgCheckIn;
  String get avgCheckOut => _avgCheckOut;
  String get fastestCheckIn => _fastestCheckIn;
  String get latestCheckOut => _latestCheckOut;
  double get onTimePercentage => _onTimePercentage;
  String get funFact => _funFact;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final history = await _getHistoryUseCase(token: token);
      _calculateMetrics(history);
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _resetMetrics();
    } catch (_) {
      _errorMessage = 'Gagal memuat data statistik.';
      _resetMetrics();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateMetrics(List<Riwayat> history) {
    if (history.isEmpty) {
      _resetMetrics();
      _funFact = 'Belum ada data absensi untuk dianalisis.';
      return;
    }

    final workdayHistory = history.where((r) => !r.isIzin).toList();
    if (workdayHistory.isEmpty) {
      _resetMetrics();
      _funFact =
          'Data saat ini berstatus izin dan tidak dihitung sebagai hari kerja.';
      return;
    }

    _totalHari = workdayHistory.length;
    _hadir = workdayHistory.where((r) => r.isOnTime).length;
    _telat = workdayHistory.where((r) => r.isTelat).length;
    _absen = workdayHistory.where((r) => r.isAbsent).length;

    // On-time percentage
    _onTimePercentage = _totalHari > 0 ? (_hadir / _totalHari) * 100 : 0;

    // Time calculations
    _calculateTimeMetrics(workdayHistory);

    // Fun fact
    _generateFunFact(workdayHistory);
  }

  void _calculateTimeMetrics(List<Riwayat> history) {
    final checkInMinutes = <int>[];
    final checkOutMinutes = <int>[];

    for (final r in history) {
      if (r.jamMasuk != null && r.jamMasuk!.isNotEmpty) {
        final mins = _timeToMinutes(r.jamMasuk!);
        if (mins != null) checkInMinutes.add(mins);
      }
      if (r.jamKeluar != null && r.jamKeluar!.isNotEmpty) {
        final mins = _timeToMinutes(r.jamKeluar!);
        if (mins != null) checkOutMinutes.add(mins);
      }
    }

    // Average check-in
    if (checkInMinutes.isNotEmpty) {
      final avg =
          checkInMinutes.reduce((a, b) => a + b) ~/ checkInMinutes.length;
      _avgCheckIn = _minutesToTime(avg);
      _fastestCheckIn = _minutesToTime(
        checkInMinutes.reduce((a, b) => a < b ? a : b),
      );
    } else {
      _avgCheckIn = '--:--';
      _fastestCheckIn = '--:--';
    }

    // Average check-out
    if (checkOutMinutes.isNotEmpty) {
      final avg =
          checkOutMinutes.reduce((a, b) => a + b) ~/ checkOutMinutes.length;
      _avgCheckOut = _minutesToTime(avg);
      _latestCheckOut = _minutesToTime(
        checkOutMinutes.reduce((a, b) => a > b ? a : b),
      );
    } else {
      _avgCheckOut = '--:--';
      _latestCheckOut = '--:--';
    }
  }

  void _generateFunFact(List<Riwayat> history) {
    // Find the day with most on-time occurrences
    final dayFormat = DateFormat('EEEE', 'id_ID');
    final onTimeDayCounts = <String, int>{};
    final checkInByDay = <String, List<int>>{};

    for (final r in history) {
      final dayName = dayFormat.format(r.tanggal);

      if (r.isOnTime) {
        onTimeDayCounts[dayName] = (onTimeDayCounts[dayName] ?? 0) + 1;
      }

      if (r.jamMasuk != null && r.jamMasuk!.isNotEmpty) {
        final mins = _timeToMinutes(r.jamMasuk!);
        if (mins != null) {
          checkInByDay.putIfAbsent(dayName, () => []).add(mins);
        }
      }
    }

    // Find the day with earliest average check-in
    String? earliestDay;
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
      _funFact =
          'Anda paling sering check-in lebih awal di hari $earliestDay. Konsistensi yang hebat!';
    } else if (onTimeDayCounts.isNotEmpty) {
      final bestDay = onTimeDayCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      _funFact = 'Hari $bestDay adalah hari dengan kehadiran terbanyak Anda!';
    } else {
      _funFact = 'Terus jaga kehadiran Anda untuk mendapat insight lebih baik!';
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
    _funFact = '';
  }
}
