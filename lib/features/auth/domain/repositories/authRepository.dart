import '../entities/user.dart';
import '../entities/opsiDropdown.dart';
import '../entities/jenisKelamin.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> verifySession({required String token});
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required int genderId,
  });
  Future<List<OpsiDropdown>> getTrainings();
  Future<List<OpsiDropdown>> getBatches();
  Future<List<JenisKelamin>> getGenders();
  Future<void> uploadPhoto({required String filePath, required String token});
  Future<void> forgotPassword({required String email});
  Future<void> verifyOtp({required String email, required String otp});
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  });
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> logout();
}
