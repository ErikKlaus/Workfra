import '../repositories/authRepository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;
  const ResetPasswordUseCase(this._repository);

  Future<void> call({required String email, required String otp, required String password, required String passwordConfirmation}) {
    return _repository.resetPassword(email: email, otp: otp, password: password, passwordConfirmation: passwordConfirmation);
  }
}
