import '../repositories/authRepository.dart';

class ForgotPasswordUseCase {
  final AuthRepository _repository;
  const ForgotPasswordUseCase(this._repository);

  Future<void> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}
