import '../../domain/entities/riwayat.dart';

class RiwayatModel extends Riwayat {
  const RiwayatModel({
    super.id,
    required super.tanggal,
    super.jamMasuk,
    super.jamKeluar,
    required super.status,
  });

  factory RiwayatModel.fromJson(Map<String, dynamic> json) {
    final source = _mergeJsonSources(json);
    final dateValue = _firstNonEmpty(source, [
      'attendance_date',
      'tanggal',
      'date',
      'created_at',
      'attendance_datetime',
    ]);
    final checkIn = _normalizeTime(
      _firstNonEmpty(source, [
        'check_in',
        'jam_masuk',
        'check_in_time',
        'checkin_time',
        'check_in_at',
      ]),
    );
    final checkOut = _normalizeTime(
      _firstNonEmpty(source, [
        'check_out',
        'jam_keluar',
        'check_out_time',
        'checkout_time',
        'check_out_at',
      ]),
    );
    final normalizedStatus = _firstNonEmpty(source, [
      'status',
      'attendance_status',
    ])?.toLowerCase();

    return RiwayatModel(
      id: _toInt(source['id'] ?? json['id']),
      tanggal: _parseDate(dateValue),
      jamMasuk: checkIn,
      jamKeluar: checkOut,
      status: _resolveStatus(
        normalizedStatus,
        checkIn: checkIn,
        checkOut: checkOut,
      ),
    );
  }

  static Map<String, dynamic> _mergeJsonSources(Map<String, dynamic> json) {
    final merged = <String, dynamic>{...json};
    for (final key in const ['data', 'attendance', 'item']) {
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

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value == null) {
      return null;
    }
    return int.tryParse(value.toString());
  }

  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateTime.now();
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static String _resolveStatus(
    String? normalizedStatus, {
    String? checkIn,
    String? checkOut,
  }) {
    if (normalizedStatus != null &&
        normalizedStatus.isNotEmpty &&
        normalizedStatus != 'unknown') {
      return normalizedStatus;
    }
    if (checkOut != null) {
      return 'done';
    }
    if (checkIn != null) {
      return 'hadir';
    }
    return 'unknown';
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
}
