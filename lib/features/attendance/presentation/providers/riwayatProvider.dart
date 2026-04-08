import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../domain/services/attendanceStatusPolicy.dart';
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RiwayatGabunganItem &&
        other.jenis == jenis &&
        other.tanggal == tanggal &&
        other.presensi == presensi &&
        other.izin == izin;
  }

  @override
  int get hashCode {
    return jenis.hashCode ^
        tanggal.hashCode ^
        presensi.hashCode ^
        izin.hashCode;
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
  List<RiwayatGabunganItem> _top3CombinedData = [];

  DateTime? _lastFetch;
  static const Duration _cacheTTL = Duration(seconds: 40);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RiwayatGabunganItem> get combinedData => _combinedData;
  List<RiwayatGabunganItem> get top3CombinedData => _top3CombinedData;

  Future<void> combineData({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final hasFreshCache =
        _combinedData.isNotEmpty &&
        _lastFetch != null &&
        now.difference(_lastFetch!) < _cacheTTL;

    if (!forceRefresh && hasFreshCache) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
        _combinedData = [];
        _top3CombinedData = [];
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

      _combinedData = _buildCombinedTimeline(
        attendanceList: attendanceWithToday,
        izinList: izinList,
      );
      _top3CombinedData = _combinedData.take(3).toList();
      _lastFetch = DateTime.now();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _combinedData = [];
      _top3CombinedData = [];
    } catch (_) {
      _errorMessage = 'Gagal memuat riwayat aktivitas.';
      _combinedData = [];
      _top3CombinedData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static List<Riwayat> _appendTodayFallback({
    required List<Riwayat> attendanceList,
    required AbsensiHariIni? todayStatus,
  }) {
    if (todayStatus == null) {
      return attendanceList;
    }

    final referenceNow = todayStatus.serverNow ?? DateTime.now();
    final today = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );

    final todayCheckIn = _normalizeTime(todayStatus.checkInTime);
    final todayCheckOut = _normalizeTime(todayStatus.checkOutTime);
    final fallbackStatus = AttendanceStatusPolicy.resolve(
      rawStatus: todayStatus.status,
      checkInTime: todayCheckIn,
      hasCheckedIn: todayStatus.hasCheckedIn,
      hasCheckedOut: todayStatus.hasCheckedOut,
      referenceNow: referenceNow,
      attendanceDate: today,
    );

    final hasTodayRecord = attendanceList.any(
      (item) => _isSameDate(item.tanggal, today),
    );
    if (hasTodayRecord) {
      return attendanceList;
    }

    if (todayCheckIn == null &&
        todayCheckOut == null &&
        fallbackStatus != 'absent') {
      return attendanceList;
    }

    final fallbackItem = Riwayat(
      tanggal: today,
      jamMasuk: todayCheckIn,
      jamKeluar: todayCheckOut,
      status: fallbackStatus,
    );

    return [fallbackItem, ...attendanceList];
  }

  static List<RiwayatGabunganItem> _buildCombinedTimeline({
    required List<Riwayat> attendanceList,
    required List<Izin> izinList,
  }) {
    final combined = <RiwayatGabunganItem>[];
    combined.addAll(attendanceList.map(RiwayatGabunganItem.fromPresensi));
    combined.addAll(izinList.map(RiwayatGabunganItem.fromIzin));
    combined.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return combined;
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String? _normalizeTime(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty || normalized == '-') {
      return null;
    }
    return normalized;
  }
}
