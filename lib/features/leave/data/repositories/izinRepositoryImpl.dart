import '../../domain/entities/izin.dart';
import '../../domain/repositories/izinRepository.dart';
import '../datasources/izinRemoteDatasource.dart';

class IzinRepositoryImpl implements IzinRepository {
  final IzinRemoteDataSource _remoteDataSource;
  IzinRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Izin>> getIzinHistory({required String token}) async =>
      _remoteDataSource.getIzinHistory(token: token);

  @override
  Future<void> createIzin({
    required String token,
    required String date,
    required String type,
    required String reason,
  }) async =>
      _remoteDataSource.createIzin(
        token: token,
        date: date,
        type: type,
        reason: reason,
      );
}
