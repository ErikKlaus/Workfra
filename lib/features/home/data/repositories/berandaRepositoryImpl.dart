import '../../domain/entities/riwayat.dart';
import '../../domain/repositories/berandaRepository.dart';
import '../datasources/berandaRemoteDatasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  HomeRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Riwayat>> getRiwayatTerbaru() async => _remoteDataSource.getRiwayatTerbaru();
}
