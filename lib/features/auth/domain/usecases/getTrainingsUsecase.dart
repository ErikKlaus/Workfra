import '../entities/opsiDropdown.dart';
import '../repositories/authRepository.dart';

class GetTrainingsUseCase {
  final AuthRepository _repository;

  const GetTrainingsUseCase(this._repository);

  Future<List<OpsiDropdown>> call() {
    return _repository.getTrainings();
  }
}
