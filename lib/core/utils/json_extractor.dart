class JsonExtractor {
  JsonExtractor._();

  static Map<String, dynamic> mergeSources(Map<String, dynamic> json) {
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

  static String? firstNonEmpty(
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
}
