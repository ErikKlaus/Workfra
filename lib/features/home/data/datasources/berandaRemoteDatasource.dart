import '../models/riwayatModel.dart';

abstract class HomeRemoteDataSource {
  Future<List<RiwayatModel>> getRiwayatTerbaru();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl();

  @override
  Future<List<RiwayatModel>> getRiwayatTerbaru() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      RiwayatModel(id: 1, tanggal: DateTime(now.year, now.month, now.day), jamMasuk: '08:01', jamKeluar: '17:05', status: 'tepat_waktu'),
      RiwayatModel(id: 2, tanggal: DateTime(now.year, now.month, now.day - 1), jamMasuk: '08:45', jamKeluar: '17:00', status: 'telat'),
      RiwayatModel(id: 3, tanggal: DateTime(now.year, now.month, now.day - 2), jamMasuk: '07:55', jamKeluar: '17:15', status: 'tepat_waktu'),
    ];
  }
}
