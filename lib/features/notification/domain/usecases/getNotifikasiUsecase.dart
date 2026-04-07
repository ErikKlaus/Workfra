import '../entities/notifikasi.dart';
import '../repositories/notifikasiRepository.dart';

class GetNotifikasiUseCase {
  final NotifikasiRepository _repository;
  const GetNotifikasiUseCase(this._repository);

  Future<List<Notifikasi>> call() {
    return _repository.getNotifikasi();
  }
}
