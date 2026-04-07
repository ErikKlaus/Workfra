import '../entities/notifikasi.dart';

abstract class NotifikasiRepository {
  Future<List<Notifikasi>> getNotifikasi();
  Future<void> addPresensiNotifikasi({
    required bool isCheckIn,
    required String? timeLabel,
  });
  Future<void> markAllAsRead();
}
