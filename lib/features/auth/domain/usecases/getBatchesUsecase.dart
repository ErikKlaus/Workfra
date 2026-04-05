import '../entities/opsiDropdown.dart';
import '../repositories/authRepository.dart';

class GetBatchesUseCase {
  final AuthRepository _repository;

  const GetBatchesUseCase(this._repository);

  Future<List<OpsiDropdown>> call() {
    return _repository.getBatches();
  }
}
