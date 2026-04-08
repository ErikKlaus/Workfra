class AttendanceStatusPolicy {
  const AttendanceStatusPolicy._();

  static const int onTimeCutoffMinutes = 8 * 60;
  static const int absentCutoffMinutes = 15 * 60;

  static String resolve({
    required String? rawStatus,
    required String? checkInTime,
    required bool hasCheckedIn,
    required bool hasCheckedOut,
    required DateTime referenceNow,
    DateTime? attendanceDate,
  }) {
    final normalizedRaw = _normalizeRawStatus(rawStatus);
    final normalizedDate = _dateOnly(attendanceDate ?? referenceNow);
    final referenceDate = _dateOnly(referenceNow);

    if (_isLeaveStatus(normalizedRaw)) {
      return normalizedRaw;
    }

    final checkInMinutes = parseTimeToMinutes(checkInTime);
    final resolvedHasCheckIn = hasCheckedIn || checkInMinutes != null;

    if (resolvedHasCheckIn) {
      if (checkInMinutes != null && checkInMinutes > onTimeCutoffMinutes) {
        return 'late';
      }

      if (_isLateStatus(normalizedRaw)) {
        return 'late';
      }

      if (hasCheckedOut && normalizedRaw == 'done') {
        return 'done';
      }

      return 'hadir';
    }

    if (_isAbsentStatus(normalizedRaw)) {
      return 'absent';
    }

    if (_isPastCutoff(
      referenceNow: referenceNow,
      attendanceDate: normalizedDate,
      referenceDate: referenceDate,
    )) {
      return 'absent';
    }

    if (_isPendingStatus(normalizedRaw)) {
      return 'belum';
    }

    return normalizedRaw.isEmpty ? 'belum' : normalizedRaw;
  }

  static int? parseTimeToMinutes(String? raw) {
    if (raw == null) {
      return null;
    }

    final normalized = raw.trim();
    if (normalized.isEmpty || normalized == '-') {
      return null;
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(normalized);
    if (match != null) {
      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      if (hour == null || minute == null || hour > 23 || minute > 59) {
        return null;
      }
      return (hour * 60) + minute;
    }

    final parsedDateTime = DateTime.tryParse(normalized);
    if (parsedDateTime == null) {
      return null;
    }

    return (parsedDateTime.hour * 60) + parsedDateTime.minute;
  }

  static bool _isPastCutoff({
    required DateTime referenceNow,
    required DateTime attendanceDate,
    required DateTime referenceDate,
  }) {
    if (attendanceDate.isBefore(referenceDate)) {
      return true;
    }

    if (attendanceDate.isAfter(referenceDate)) {
      return false;
    }

    final nowMinutes = (referenceNow.hour * 60) + referenceNow.minute;
    return nowMinutes >= absentCutoffMinutes;
  }

  static String _normalizeRawStatus(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'late':
      case 'telat':
      case 'terlambat':
        return 'late';
      case 'absent':
      case 'absen':
      case 'alpa':
      case 'tidak_hadir':
        return 'absent';
      case 'on_time':
      case 'tepat_waktu':
      case 'present':
      case 'check_in':
      case 'check_out':
      case 'masuk':
      case 'pulang':
      case 'hadir':
        return 'hadir';
      case 'done':
      case 'selesai':
      case 'completed':
        return 'done';
      case '':
      case 'unknown':
      case '-':
      case 'belum':
      case 'pending':
        return 'belum';
      default:
        return normalized;
    }
  }

  static bool _isLateStatus(String normalized) => normalized == 'late';

  static bool _isAbsentStatus(String normalized) => normalized == 'absent';

  static bool _isLeaveStatus(String normalized) {
    return normalized == 'izin' ||
        normalized == 'leave' ||
        normalized == 'permission' ||
        normalized == 'cuti' ||
        normalized == 'sakit';
  }

  static bool _isPendingStatus(String normalized) => normalized == 'belum';

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
