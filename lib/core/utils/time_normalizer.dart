class TimeNormalizer {
  TimeNormalizer._();

  static String? normalize(String? raw) {
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
}
