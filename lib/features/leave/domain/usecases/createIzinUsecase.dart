import '../repositories/izinRepository.dart';

class CreateIzinUseCase {
  final IzinRepository _repository;
  const CreateIzinUseCase(this._repository);

  Future<void> call({
    required String token,
    required String date,
    required String type,
    required String reason,
  }) =>
      _repository.createIzin(
        token: token,
        date: date,
        type: type,
        reason: reason,
      );
}
