import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/layananPenyimpanan.dart';
import '../../../../core/utils/attendance_utils.dart';
import '../../../../core/utils/safe_notify_mixin.dart';
import '../../../auth/domain/repositories/authRepository.dart';
import '../../../home/domain/entities/riwayat.dart';
import '../../../leave/domain/entities/izin.dart';
import '../../../leave/domain/usecases/getIzinHistoryUsecase.dart';
import '../../domain/entities/absensiHariIni.dart';
import '../../domain/services/attendanceStatusPolicy.dart';
import '../../domain/usecases/getAbsensiHistoryUsecase.dart';
import '../../domain/usecases/getTodayStatusUsecase.dart';

class _CombineTimelineArgs {
  final List<Riwayat> attendanceList;
  final List<Izin> izinList;
  const _CombineTimelineArgs(this.attendanceList, this.izinList);
}

List<RiwayatGabunganItem> _buildCombinedTimelineTask(
  _CombineTimelineArgs args,
) {
  final attendanceList = args.attendanceList;
  final izinList = args.izinList;

  final combined = <RiwayatGabunganItem>[];
  var i = 0;
  var j = 0;

  while (i < attendanceList.length && j < izinList.length) {
    if (attendanceList[i].tanggal.compareTo(izinList[j].date) >= 0) {
      combined.add(RiwayatGabunganItem.fromPresensi(attendanceList[i]));
      i++;
    } else {
      combined.add(RiwayatGabunganItem.fromIzin(izinList[j]));
      j++;
    }
  }

  while (i < attendanceList.length) {
    combined.add(RiwayatGabunganItem.fromPresensi(attendanceList[i]));
    i++;
  }

  while (j < izinList.length) {
    combined.add(RiwayatGabunganItem.fromIzin(izinList[j]));
    j++;
  }

  return combined;
}

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
    return Object.hash(jenis, tanggal, presensi, izin);
  }
}

class RiwayatProvider extends ChangeNotifier with SafeNotifyMixin {
  final GetAbsensiHistoryUseCase _getAbsensiHistoryUseCase;
  final GetTodayStatusUseCase _getTodayStatusUseCase;
  final GetIzinHistoryUseCase _getIzinHistoryUseCase;
  final AuthRepository _authRepository;
  final StorageService _storageService;

  RiwayatProvider({
    required GetAbsensiHistoryUseCase getAbsensiHistoryUseCase,
    required GetTodayStatusUseCase getTodayStatusUseCase,
    required GetIzinHistoryUseCase getIzinHistoryUseCase,
    required AuthRepository authRepository,
    required StorageService storageService,
  }) : _getAbsensiHistoryUseCase = getAbsensiHistoryUseCase,
       _getTodayStatusUseCase = getTodayStatusUseCase,
       _getIzinHistoryUseCase = getIzinHistoryUseCase,
       _authRepository = authRepository,
       _storageService = storageService;

  bool _isLoading = false;
  String? _errorMessage;
  List<RiwayatGabunganItem> _combinedData = [];
  List<RiwayatGabunganItem> _top3CombinedData = [];
  String? _activeToken;

  DateTime? _lastFetch;
  static const Duration _cacheTTL = Duration(seconds: 40);
  static const String _combinedCacheKey = 'cache_combined_history_v1';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RiwayatGabunganItem> get combinedData => _combinedData;
  List<RiwayatGabunganItem> get top3CombinedData => _top3CombinedData;

  Future<void> combineData({bool forceRefresh = false}) async {
    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      _clearSessionState();
      _errorMessage = 'error_session_expired';
      safeNotify();
      return;
    }

    final tokenChanged = _syncSessionToken(token);
    if (tokenChanged) {
      safeNotify();
    }

    final now = DateTime.now();
    final hasFreshCache =
        !tokenChanged &&
        _combinedData.isNotEmpty &&
        _lastFetch != null &&
        now.difference(_lastFetch!) < _cacheTTL;

    if (!forceRefresh && hasFreshCache) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    safeNotify();

    try {
      final results = await Future.wait<Object>([
        _getAbsensiHistoryUseCase(token: token),
        _getIzinHistoryUseCase(token: token),
      ]);

      final attendanceList = results[0] as List<Riwayat>;
      final izinList = (results[1] as List<Izin>).toList(growable: false);

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

      _combinedData = await compute(
        _buildCombinedTimelineTask,
        _CombineTimelineArgs(attendanceWithToday, izinList),
      );
      _top3CombinedData = _combinedData.take(3).toList();
      await _writeCombinedCache(token, _combinedData);
      _lastFetch = DateTime.now();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      final cached = _readCombinedCache(token);
      _combinedData = cached;
      _top3CombinedData = cached.take(3).toList();
    } catch (_) {
      _errorMessage = 'error_load_history';
      final cached = _readCombinedCache(token);
      _combinedData = cached;
      _top3CombinedData = cached.take(3).toList();
    } finally {
      _isLoading = false;
      safeNotify();
    }
  }

  /// Refresh data in background tanpa trigger loading shimmer.
  /// Existing cached data tetap ditampilkan selama fetch.
  Future<void> silentRefresh() async {
    _lastFetch = null; // invalidasi cache
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        _clearSessionState();
        safeNotify();
        return;
      }
      _syncSessionToken(token);

      final results = await Future.wait<Object>([
        _getAbsensiHistoryUseCase(token: token),
        _getIzinHistoryUseCase(token: token),
      ]);

      final attendanceList = results[0] as List<Riwayat>;
      final izinList = (results[1] as List<Izin>).toList(growable: false);

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

      final newData = await compute(
        _buildCombinedTimelineTask,
        _CombineTimelineArgs(attendanceWithToday, izinList),
      );

      _combinedData = newData;
      _top3CombinedData = newData.take(3).toList();
      await _writeCombinedCache(token, newData);
      _lastFetch = DateTime.now();
      safeNotify();
    } catch (_) {
      // Silently fail — existing data tetap tampil
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
      (item) => AttendanceUtils.isSameDate(item.tanggal, today),
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

  static String? _normalizeTime(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty || normalized == '-') {
      return null;
    }
    return normalized;
  }

  Future<void> _writeCombinedCache(
    String token,
    List<RiwayatGabunganItem> items,
  ) async {
    final encoded = items.map(_encodeCombinedItem).toList(growable: false);
    await _storageService.saveString(
      _combinedCacheKeyForToken(token),
      jsonEncode(encoded),
    );
  }

  List<RiwayatGabunganItem> _readCombinedCache(String token) {
    final raw = _storageService.getString(_combinedCacheKeyForToken(token));
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_decodeCombinedItem)
          .whereType<RiwayatGabunganItem>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Map<String, dynamic> _encodeCombinedItem(RiwayatGabunganItem item) {
    if (item.jenis == JenisRiwayatGabungan.presensi && item.presensi != null) {
      final p = item.presensi!;
      return {
        'kind': 'presensi',
        'id': p.id,
        'date': p.tanggal.toIso8601String(),
        'check_in': p.jamMasuk,
        'check_out': p.jamKeluar,
        'status': p.status,
      };
    }

    final leave = item.izin!;
    return {
      'kind': 'izin',
      'id': leave.id,
      'type': leave.type,
      'date': leave.date.toIso8601String(),
      'reason': leave.reason,
      'status': leave.status.name,
      'processed_at': leave.processedAt?.toIso8601String(),
      'rejection_reason': leave.rejectionReason,
    };
  }

  static RiwayatGabunganItem? _decodeCombinedItem(Map<String, dynamic> json) {
    final kind = (json['kind'] as String?)?.trim().toLowerCase();
    if (kind == 'presensi') {
      final date = DateTime.tryParse(json['date'] as String? ?? '');
      if (date == null) {
        return null;
      }

      final presensi = Riwayat(
        id: json['id'] as int?,
        tanggal: date,
        jamMasuk: json['check_in'] as String?,
        jamKeluar: json['check_out'] as String?,
        status: json['status'] as String? ?? 'belum',
      );
      return RiwayatGabunganItem.fromPresensi(presensi);
    }

    if (kind == 'izin') {
      final date = DateTime.tryParse(json['date'] as String? ?? '');
      if (date == null) {
        return null;
      }

      final processedAt = DateTime.tryParse(
        json['processed_at'] as String? ?? '',
      );
      final statusRaw = (json['status'] as String?)?.trim().toLowerCase();
      final status = switch (statusRaw) {
        'approved' => StatusIzin.approved,
        'rejected' => StatusIzin.rejected,
        _ => StatusIzin.pending,
      };

      final leave = Izin(
        id: json['id'] as int?,
        type: json['type'] as String? ?? 'izin',
        date: date,
        reason: json['reason'] as String? ?? '-',
        status: status,
        processedAt: processedAt,
        rejectionReason: json['rejection_reason'] as String?,
      );
      return RiwayatGabunganItem.fromIzin(leave);
    }

    return null;
  }

  String _combinedCacheKeyForToken(String token) {
    final tokenHash = token.hashCode.toUnsigned(32).toRadixString(16);
    return '${_combinedCacheKey}_$tokenHash';
  }

  bool _syncSessionToken(String token) {
    if (_activeToken == token) {
      return false;
    }

    _activeToken = token;
    _lastFetch = null;
    final cached = _readCombinedCache(token);
    _combinedData = cached;
    _top3CombinedData = cached.take(3).toList();
    return true;
  }

  void _clearSessionState() {
    _activeToken = null;
    _lastFetch = null;
    _combinedData = [];
    _top3CombinedData = [];
  }
}
