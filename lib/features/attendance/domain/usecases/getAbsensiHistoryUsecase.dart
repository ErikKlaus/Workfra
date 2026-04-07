import '../../../home/domain/entities/riwayat.dart';
import '../repositories/absensiRepository.dart';

class GetAbsensiHistoryUseCase {
  final AbsensiRepository _repository;
  const GetAbsensiHistoryUseCase(this._repository);

  Future<List<Riwayat>> call({required String token}) =>
      _repository.getHistory(token: token);
}
