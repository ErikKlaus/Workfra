class Riwayat {
  final int? id;
  final DateTime tanggal;
  final String? jamMasuk;
  final String? jamKeluar;
  final String status; // 'tepat_waktu' or 'telat'

  const Riwayat({
    this.id,
    required this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    required this.status,
  });

  bool get isTelat => status == 'telat';
}
