import '../../../auth/domain/entities/user.dart';
import '../repositories/profileRepository.dart';

class GetProfileUseCase {
  final ProfileRepository _repository;
  const GetProfileUseCase(this._repository);

  Future<User> call({required String token}) {
    return _repository.getProfile(token: token);
  }
}
