import '../repositories/absensiRepository.dart';

class DeleteAbsenUseCase {
  final AbsensiRepository _repository;
  const DeleteAbsenUseCase(this._repository);

  Future<void> call({required String token, required int id}) =>
      _repository.deleteAbsen(token: token, id: id);
}
