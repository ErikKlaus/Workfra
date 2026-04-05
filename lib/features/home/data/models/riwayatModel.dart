import '../../domain/entities/riwayat.dart';

class RiwayatModel extends Riwayat {
  const RiwayatModel({super.id, required super.tanggal, super.jamMasuk, super.jamKeluar, required super.status});

  factory RiwayatModel.fromJson(Map<String, dynamic> json) {
    return RiwayatModel(id: json['id'] as int?, tanggal: DateTime.parse(json['tanggal'] as String), jamMasuk: json['jam_masuk'] as String?, jamKeluar: json['jam_keluar'] as String?, status: json['status'] as String? ?? 'tepat_waktu');
  }
}
