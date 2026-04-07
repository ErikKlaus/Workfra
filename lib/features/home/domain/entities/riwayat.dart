class Riwayat {
  final int? id;
  final DateTime tanggal;
  final String? jamMasuk;
  final String? jamKeluar;
  final String status; // API-driven status value

  const Riwayat({
    this.id,
    required this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    required this.status,
  });

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isTelat =>
      normalizedStatus == 'late' ||
      normalizedStatus == 'telat' ||
      normalizedStatus == 'terlambat';
  bool get isAbsent =>
      normalizedStatus == 'absent' || normalizedStatus == 'absen';
  bool get isIzin =>
      normalizedStatus == 'izin' ||
      normalizedStatus == 'leave' ||
      normalizedStatus == 'permission' ||
      normalizedStatus == 'cuti' ||
      normalizedStatus == 'sakit';
  bool get isOnTime =>
      normalizedStatus == 'on_time' ||
      normalizedStatus == 'tepat_waktu' ||
      normalizedStatus == 'hadir' ||
      normalizedStatus == 'done' ||
      normalizedStatus == 'masuk' ||
      normalizedStatus == 'pulang' ||
      normalizedStatus == 'present' ||
      normalizedStatus == 'check_in' ||
      normalizedStatus == 'check_out';
}
