import '../../../../core/utils/json_extractor.dart';
import '../../../../core/utils/time_normalizer.dart';
import '../../../attendance/domain/services/attendanceStatusPolicy.dart';
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
    final source = JsonExtractor.mergeSources(json);
    final dateValue = JsonExtractor.firstNonEmpty(source, [
      'attendance_date',
      'tanggal',
      'date',
      'created_at',
      'attendance_datetime',
    ]);
    final checkIn = TimeNormalizer.normalize(
      JsonExtractor.firstNonEmpty(source, [
        'check_in',
        'jam_masuk',
        'check_in_time',
        'checkin_time',
        'check_in_at',
      ]),
    );
    final checkOut = TimeNormalizer.normalize(
      JsonExtractor.firstNonEmpty(source, [
        'check_out',
        'jam_keluar',
        'check_out_time',
        'checkout_time',
        'check_out_at',
      ]),
    );
    final rawStatus = JsonExtractor.firstNonEmpty(source, ['status', 'attendance_status']);
    final attendanceDate = _parseDate(dateValue);

    return RiwayatModel(
      id: _toInt(source['id'] ?? json['id']),
      tanggal: attendanceDate,
      jamMasuk: checkIn,
      jamKeluar: checkOut,
      status: AttendanceStatusPolicy.resolve(
        rawStatus: rawStatus,
        checkInTime: checkIn,
        hasCheckedIn: checkIn != null,
        hasCheckedOut: checkOut != null,
        referenceNow: DateTime.now(),
        attendanceDate: attendanceDate,
      ),
    );
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
}
