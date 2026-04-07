import '../../../home/domain/entities/riwayat.dart';
import '../entities/absensiHariIni.dart';

abstract class AbsensiRepository {
  Future<List<Riwayat>> getHistory({required String token});
  Future<AbsensiHariIni> getTodayStatus({required String token});
  Future<void> deleteAbsen({required String token, required int id});
  Future<Map<String, dynamic>> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  });
  Future<Map<String, dynamic>> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  });
}
