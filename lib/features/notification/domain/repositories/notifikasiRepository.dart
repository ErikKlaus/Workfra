import '../entities/notifikasi.dart';

abstract class NotifikasiRepository {
  Future<List<Notifikasi>> getNotifikasi({required String localeCode});
  Future<void> addPresensiNotifikasi({
    required bool isCheckIn,
    required String? timeLabel,
  });
  Future<void> markAllAsRead();
}
