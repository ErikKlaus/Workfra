import '../../../home/domain/entities/riwayat.dart';
import '../../domain/entities/absensiHariIni.dart';
import '../../domain/repositories/absensiRepository.dart';
import '../datasources/absensiRemoteDatasource.dart';

class AbsensiRepositoryImpl implements AbsensiRepository {
  final AbsensiRemoteDataSource _remoteDataSource;
  AbsensiRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> deleteAbsen({required String token, required int id}) async =>
      _remoteDataSource.deleteAbsen(token: token, id: id);

  @override
  Future<List<Riwayat>> getHistory({required String token}) async =>
      _remoteDataSource.getHistory(token: token);

  @override
  Future<AbsensiHariIni> getTodayStatus({required String token}) async =>
      _remoteDataSource.getTodayStatus(token: token);

  @override
  Future<Map<String, dynamic>> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async => _remoteDataSource.checkIn(
    token: token,
    latitude: latitude,
    longitude: longitude,
    address: address,
  );

  @override
  Future<Map<String, dynamic>> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async => _remoteDataSource.checkOut(
    token: token,
    latitude: latitude,
    longitude: longitude,
    address: address,
  );
}
