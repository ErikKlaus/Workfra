import '../../domain/entities/notifikasi.dart';
import '../../domain/repositories/notifikasiRepository.dart';
import '../datasources/notifikasiLocalDatasource.dart';

class NotifikasiRepositoryImpl implements NotifikasiRepository {
  final NotifikasiLocalDataSource _localDataSource;
  NotifikasiRepositoryImpl(this._localDataSource);

  @override
  Future<List<Notifikasi>> getNotifikasi() async {
    return _localDataSource.getNotifikasi();
  }

  @override
  Future<void> addPresensiNotifikasi({
    required bool isCheckIn,
    required String? timeLabel,
  }) async {
    await _localDataSource.addPresensiNotifikasi(
      isCheckIn: isCheckIn,
      timeLabel: timeLabel,
    );
  }

  @override
  Future<void> markAllAsRead() async {
    await _localDataSource.markAllAsRead();
  }
}
