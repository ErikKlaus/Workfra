import '../../../auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<User> getProfile({required String token});
  Future<User> updateProfile({
    required String token,
    required String name,
    required String email,
  });
  Future<void> uploadPhoto({required String token, required String filePath});
}
