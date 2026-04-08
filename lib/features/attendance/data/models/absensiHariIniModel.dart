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
    final data = _mergeJsonSources(json);

    final checkIn = _normalizeTime(
      _firstNonEmpty(data, [
        'check_in',
        'jam_masuk',
        'check_in_time',
        'checkin_time',
        'check_in_at',
      ]),
    );
    final checkOut = _normalizeTime(
      _firstNonEmpty(data, [
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

    final rawStatus = _firstNonEmpty(data, ['status', 'attendance_status']);
    final serverNow = _parseServerNow(data);
    final attendanceDate =
        _parseAttendanceDate(
          _firstNonEmpty(data, [
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

  static Map<String, dynamic> _mergeJsonSources(Map<String, dynamic> json) {
    final merged = <String, dynamic>{...json};
    for (final key in const ['data', 'attendance', 'today', 'item']) {
      final nested = json[key];
      if (nested is Map<String, dynamic>) {
        merged.addAll(nested);
      } else if (nested is Map) {
        merged.addAll(Map<String, dynamic>.from(nested));
      }
    }
    return merged;
  }

  static String? _firstNonEmpty(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
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
    return null;
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

  static String? _normalizeTime(String? raw) {
    if (raw == null) {
      return null;
    }

    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

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

  static DateTime? _parseServerNow(Map<String, dynamic> source) {
    final raw = _firstNonEmpty(source, const [
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
