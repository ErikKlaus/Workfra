class NotifikasiLocalizationHelper {
  static String normalizeLocaleCode(String localeCode) {
    final normalized = localeCode.toLowerCase();
    if (normalized.startsWith('en')) return 'en';
    if (normalized.startsWith('zh')) return 'zh';
    if (normalized.startsWith('ms')) return 'ms';
    return 'id';
  }

  static String attendanceTitle({
    required bool isCheckIn,
    required String localeCode,
  }) {
    final locale = normalizeLocaleCode(localeCode);
    switch (locale) {
      case 'en':
        return isCheckIn ? 'Check-in Successful' : 'Check-out Successful';
      case 'zh':
        return isCheckIn ? '签到成功' : '签退成功';
      case 'ms':
        return isCheckIn ? 'Check-in Berjaya' : 'Check-out Berjaya';
      case 'id':
      default:
        return isCheckIn ? 'Check-in Berhasil' : 'Check-out Berhasil';
    }
  }

  static String attendanceDescription({
    required bool isCheckIn,
    required String timeLabel,
    required String localeCode,
  }) {
    final locale = normalizeLocaleCode(localeCode);
    switch (locale) {
      case 'en':
        return 'Attendance ${isCheckIn ? 'check-in' : 'check-out'} was recorded at $timeLabel.';
      case 'zh':
        return '考勤${isCheckIn ? '签到' : '签退'}已记录于$timeLabel。';
      case 'ms':
        return 'Presensi ${isCheckIn ? 'masuk' : 'pulang'} direkodkan pada $timeLabel.';
      case 'id':
      default:
        return 'Presensi ${isCheckIn ? 'masuk' : 'pulang'} tercatat pada $timeLabel.';
    }
  }

  static String relativeTime({
    required DateTime createdAt,
    required DateTime now,
    required String localeCode,
  }) {
    final locale = normalizeLocaleCode(localeCode);
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      switch (locale) {
        case 'en':
          return 'Just now';
        case 'zh':
          return '刚刚';
        case 'ms':
          return 'Baru sahaja';
        case 'id':
        default:
          return 'Baru saja';
      }
    }

    if (diff.inHours < 1) {
      final minutes = diff.inMinutes;
      switch (locale) {
        case 'en':
          final unit = minutes == 1 ? 'minute' : 'minutes';
          return '$minutes $unit ago';
        case 'zh':
          return '$minutes分钟前';
        case 'ms':
          return '$minutes minit lalu';
        case 'id':
        default:
          return '$minutes menit lalu';
      }
    }

    if (diff.inHours < 24) {
      final hours = diff.inHours;
      switch (locale) {
        case 'en':
          final unit = hours == 1 ? 'hour' : 'hours';
          return '$hours $unit ago';
        case 'zh':
          return '$hours小时前';
        case 'ms':
          return '$hours jam lalu';
        case 'id':
        default:
          return '$hours jam lalu';
      }
    }

    if (diff.inDays < 7) {
      final days = diff.inDays;
      switch (locale) {
        case 'en':
          final unit = days == 1 ? 'day' : 'days';
          return '$days $unit ago';
        case 'zh':
          return '$days天前';
        case 'ms':
          return '$days hari lalu';
        case 'id':
        default:
          return '$days hari lalu';
      }
    }

    return formatDate(createdAt, localeCode: locale);
  }

  static String formatDate(DateTime date, {required String localeCode}) {
    final locale = normalizeLocaleCode(localeCode);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    if (locale == 'zh') {
      return '$year-$month-$day';
    }

    return '$day/$month/$year';
  }
}
