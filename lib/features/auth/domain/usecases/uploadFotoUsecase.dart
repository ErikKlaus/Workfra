import '../repositories/authRepository.dart';

class UploadPhotoUseCase {
  final AuthRepository _repository;
  const UploadPhotoUseCase(this._repository);

  Future<void> call({required String filePath, required String token}) {
    return _repository.uploadPhoto(filePath: filePath, token: token);
  }
}
