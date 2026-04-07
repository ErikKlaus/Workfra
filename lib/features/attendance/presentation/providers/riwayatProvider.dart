import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../domain/entities/absensiHariIni.dart';
import '../../domain/usecases/getTodayStatusUsecase.dart';
import '../../../home/domain/entities/riwayat.dart';
import '../../../leave/domain/entities/izin.dart';
import '../../../leave/domain/usecases/getIzinHistoryUsecase.dart';
import '../../domain/usecases/getAbsensiHistoryUsecase.dart';

enum JenisRiwayatGabungan { presensi, izin }

class RiwayatGabunganItem {
  final JenisRiwayatGabungan jenis;
  final DateTime tanggal;
  final Riwayat? presensi;
  final Izin? izin;

  const RiwayatGabunganItem._({
    required this.jenis,
    required this.tanggal,
    this.presensi,
    this.izin,
  });

  factory RiwayatGabunganItem.fromPresensi(Riwayat item) {
    return RiwayatGabunganItem._(
      jenis: JenisRiwayatGabungan.presensi,
      tanggal: item.tanggal,
      presensi: item,
    );
  }

  factory RiwayatGabunganItem.fromIzin(Izin item) {
    return RiwayatGabunganItem._(
      jenis: JenisRiwayatGabungan.izin,
      tanggal: item.date,
      izin: item,
    );
  }
}

class RiwayatProvider extends ChangeNotifier {
  final GetAbsensiHistoryUseCase _getAbsensiHistoryUseCase;
  final GetTodayStatusUseCase _getTodayStatusUseCase;
  final GetIzinHistoryUseCase _getIzinHistoryUseCase;
  final AuthRepository _authRepository;

  RiwayatProvider({
    required GetAbsensiHistoryUseCase getAbsensiHistoryUseCase,
    required GetTodayStatusUseCase getTodayStatusUseCase,
    required GetIzinHistoryUseCase getIzinHistoryUseCase,
    required AuthRepository authRepository,
  }) : _getAbsensiHistoryUseCase = getAbsensiHistoryUseCase,
       _getTodayStatusUseCase = getTodayStatusUseCase,
       _getIzinHistoryUseCase = getIzinHistoryUseCase,
       _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<RiwayatGabunganItem> _combinedData = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RiwayatGabunganItem> get combinedData => _combinedData;

  Future<void> combineData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
        _combinedData = [];
        return;
      }

      final results = await Future.wait<Object>([
        _getAbsensiHistoryUseCase(token: token),
        _getIzinHistoryUseCase(token: token),
      ]);

      final attendanceList = results[0] as List<Riwayat>;
      final izinList = results[1] as List<Izin>;

      AbsensiHariIni? todayStatus;
      try {
        todayStatus = await _getTodayStatusUseCase(token: token);
      } catch (_) {
        todayStatus = null;
      }

      final attendanceWithToday = _appendTodayFallback(
        attendanceList: attendanceList,
        todayStatus: todayStatus,
      );

      final combined = <RiwayatGabunganItem>[
        ...attendanceWithToday.map(RiwayatGabunganItem.fromPresensi),
        ...izinList.map(RiwayatGabunganItem.fromIzin),
      ];

      combined.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      _combinedData = combined;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _combinedData = [];
    } catch (_) {
      _errorMessage = 'Gagal memuat riwayat aktivitas.';
      _combinedData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Riwayat> _appendTodayFallback({
    required List<Riwayat> attendanceList,
    required AbsensiHariIni? todayStatus,
  }) {
    if (todayStatus == null) {
      return attendanceList;
    }

    final todayCheckIn = _normalizeTime(todayStatus.checkInTime);
    final todayCheckOut = _normalizeTime(todayStatus.checkOutTime);
    if (todayCheckIn == null && todayCheckOut == null) {
      return attendanceList;
    }

    final today = DateTime.now();
    final hasTodayWithTime = attendanceList.any((item) {
      if (!_isSameDate(item.tanggal, today)) {
        return false;
      }
      return _normalizeTime(item.jamMasuk) != null ||
          _normalizeTime(item.jamKeluar) != null;
    });

    if (hasTodayWithTime) {
      return attendanceList;
    }

    final fallbackStatus = _resolveTodayStatus(
      rawStatus: todayStatus.status,
      checkIn: todayCheckIn,
      checkOut: todayCheckOut,
    );

    final fallbackItem = Riwayat(
      tanggal: DateTime(today.year, today.month, today.day),
      jamMasuk: todayCheckIn,
      jamKeluar: todayCheckOut,
      status: fallbackStatus,
    );

    return [fallbackItem, ...attendanceList];
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String? _normalizeTime(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty || normalized == '-') {
      return null;
    }
    return normalized;
  }

  String _resolveTodayStatus({
    required String rawStatus,
    required String? checkIn,
    required String? checkOut,
  }) {
    final normalized = rawStatus.trim().toLowerCase();
    if (normalized.isNotEmpty &&
        normalized != 'unknown' &&
        normalized != 'belum') {
      return normalized;
    }
    if (checkOut != null) {
      return 'done';
    }
    if (checkIn != null) {
      return 'hadir';
    }
    return 'unknown';
  }
}
