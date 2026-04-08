import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

/// Shared attendance-related utility functions used across the presentation layer.
class AttendanceUtils {
  AttendanceUtils._();

  /// Normalizes a nullable time string for display.
  /// Returns `-` if the value is null, empty or whitespace-only.
  static String displayValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '-';
    }
    return normalized;
  }

  /// Checks if two DateTimes fall on the same calendar day.
  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Resolves a raw attendance status string into a localized display label.
  static String localizeStatus(BuildContext context, String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'late':
      case 'telat':
        return tr(context, 'status_late');
      case 'absent':
      case 'absen':
        return tr(context, 'status_absent');
      case 'on_time':
      case 'tepat_waktu':
      case 'hadir':
      case 'done':
      case 'masuk':
      case 'pulang':
      case 'present':
      case 'check_in':
      case 'check_out':
        return tr(context, 'status_present');
      case 'izin':
      case 'leave':
      case 'permission':
      case 'cuti':
      case 'sakit':
        return tr(context, 'status_leave');
      default:
        return tr(context, 'status_unknown');
    }
  }

  /// Resolves a raw attendance status to its associated display color.
  static Color statusColor(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'late':
      case 'telat':
        return const Color(0xFFF59E0B);
      case 'absent':
      case 'absen':
        return const Color(0xFFEF4444);
      case 'on_time':
      case 'tepat_waktu':
      case 'hadir':
      case 'done':
      case 'masuk':
      case 'pulang':
      case 'present':
      case 'check_in':
      case 'check_out':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
