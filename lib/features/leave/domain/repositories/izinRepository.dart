import '../entities/izin.dart';

abstract class IzinRepository {
  Future<List<Izin>> getIzinHistory({required String token});
  Future<void> createIzin({
    required String token,
    required String date,
    required String type,
    required String reason,
  });
}
