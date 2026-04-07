import '../repositories/profileRepository.dart';

class UploadProfilePhotoUseCase {
  final ProfileRepository _repository;
  const UploadProfilePhotoUseCase(this._repository);

  Future<void> call({required String token, required String filePath}) {
    return _repository.uploadPhoto(token: token, filePath: filePath);
  }
}
