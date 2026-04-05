import '../entities/user.dart';
import '../repositories/authRepository.dart';

class RegisterUseCase {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<User> call({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required int genderId,
  }) {
    return _repository.register(
      name: name,
      email: email,
      password: password,
      trainingId: trainingId,
      batchId: batchId,
      genderId: genderId,
    );
  }
}
