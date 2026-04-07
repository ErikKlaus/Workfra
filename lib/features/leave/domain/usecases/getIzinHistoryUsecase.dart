import '../entities/izin.dart';
import '../repositories/izinRepository.dart';

class GetIzinHistoryUseCase {
  final IzinRepository _repository;
  const GetIzinHistoryUseCase(this._repository);

  Future<List<Izin>> call({required String token}) =>
      _repository.getIzinHistory(token: token);
}
