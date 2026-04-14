import '../../../auth/domain/entities/user.dart';
import '../repositories/profileRepository.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repository;
  const UpdateProfileUseCase(this._repository);

  Future<User> call({
    required String token,
    required String name,
    required String email,
    String? photoUrl,
  }) {
    return _repository.updateProfile(token: token, name: name, email: email, photoUrl: photoUrl);
  }
}
