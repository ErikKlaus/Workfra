import '../../../../core/utils/json_extractor.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../domain/entities/absensiHariIni.dart';
import '../../domain/services/attendanceStatusPolicy.dart';

class AbsensiHariIniModel extends AbsensiHariIni {
  const AbsensiHariIniModel({
    required super.hasCheckedIn,
    required super.hasCheckedOut,
    super.checkInTime,
    super.checkOutTime,
    super.serverNow,
    required super.status,
  });

  factory AbsensiHariIniModel.fromJson(Map<String, dynamic> json) {
    final data = JsonExtractor.mergeSources(json);

    final checkIn = TimeNormalizer.normalize(
      JsonExtractor.firstNonEmpty(data, [
        'check_in',
        'jam_masuk',
        'check_in_time',
        'checkin_time',
        'check_in_at',
      ]),
    );
    final checkOut = TimeNormalizer.normalize(
      JsonExtractor.firstNonEmpty(data, [
        'check_out',
        'jam_keluar',
        'check_out_time',
        'checkout_time',
        'check_out_at',
      ]),
    );

    final hasInFlag =
        _toBool(data['has_checked_in']) ??
        _toBool(data['is_check_in']) ??
        _toBool(data['checked_in']) ??
        false;
    final hasOutFlag =
        _toBool(data['has_checked_out']) ??
        _toBool(data['is_check_out']) ??
        _toBool(data['checked_out']) ??
        false;

    final hasIn = hasInFlag || checkIn != null;
    final hasOut = hasOutFlag || checkOut != null;

    final rawStatus = JsonExtractor.firstNonEmpty(data, ['status', 'attendance_status']);
    final serverNow = _parseServerNow(data);
    final attendanceDate =
        _parseAttendanceDate(
          JsonExtractor.firstNonEmpty(data, [
            'attendance_date',
            'tanggal',
            'date',
            'attendance_datetime',
            'created_at',
          ]),
        ) ??
        serverNow ??
        DateTime.now();

    final status = AttendanceStatusPolicy.resolve(
      rawStatus: rawStatus,
      checkInTime: checkIn,
      hasCheckedIn: hasIn,
      hasCheckedOut: hasOut,
      referenceNow: serverNow ?? DateTime.now(),
      attendanceDate: attendanceDate,
    );

    return AbsensiHariIniModel(
      hasCheckedIn: hasIn,
      hasCheckedOut: hasOut,
      checkInTime: checkIn,
      checkOutTime: checkOut,
      serverNow: serverNow,
      status: status,
    );
  }

  static bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return null;
  }

  static DateTime? _parseServerNow(Map<String, dynamic> source) {
    final raw = JsonExtractor.firstNonEmpty(source, const [
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
    if (parsed == null) {
      return null;
    }

    return parsed.toLocal();
  }

  static DateTime? _parseAttendanceDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      return null;
    }

    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
