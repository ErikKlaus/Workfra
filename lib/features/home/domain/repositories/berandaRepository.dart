import '../../domain/entities/riwayat.dart';

abstract class HomeRepository {
  Future<List<Riwayat>> getRiwayatTerbaru();
}
