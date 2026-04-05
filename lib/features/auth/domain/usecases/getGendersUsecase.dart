import '../entities/jenisKelamin.dart';
import '../repositories/authRepository.dart';

class GetGendersUseCase {
  final AuthRepository _repository;

  const GetGendersUseCase(this._repository);

  Future<List<JenisKelamin>> call() {
    return _repository.getGenders();
  }
}
