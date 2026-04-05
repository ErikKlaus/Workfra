import '../repositories/authRepository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;
  const VerifyOtpUseCase(this._repository);

  Future<void> call({required String email, required String otp}) {
    return _repository.verifyOtp(email: email, otp: otp);
  }
}
