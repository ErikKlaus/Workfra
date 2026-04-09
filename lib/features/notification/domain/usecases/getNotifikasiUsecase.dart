import '../entities/notifikasi.dart';
import '../repositories/notifikasiRepository.dart';

class GetNotifikasiUseCase {
  final NotifikasiRepository _repository;
  const GetNotifikasiUseCase(this._repository);

  Future<List<Notifikasi>> call({required String localeCode}) {
    return _repository.getNotifikasi(localeCode: localeCode);
  }
}
