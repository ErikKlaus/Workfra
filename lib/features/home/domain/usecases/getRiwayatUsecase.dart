import '../entities/riwayat.dart';
import '../repositories/berandaRepository.dart';

class GetRiwayatUseCase {
  final HomeRepository _repository;
  const GetRiwayatUseCase(this._repository);
  Future<List<Riwayat>> call() => _repository.getRiwayatTerbaru();
}
