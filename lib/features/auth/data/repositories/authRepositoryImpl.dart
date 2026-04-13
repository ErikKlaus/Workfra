import '../../../../core/error/exceptions.dart';
import '../../domain/entities/jenisKelamin.dart';
import '../../domain/entities/opsiDropdown.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/authRepository.dart';
import '../datasources/authLocalDatasource.dart';
import '../datasources/authRemoteDatasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final user = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      final token = user.token?.trim() ?? '';
      if (token.isEmpty) {
        // Prevent fallback to previous account token when backend response is missing token.
        await _localDataSource.deleteToken();
        throw const ServerException(
          message: 'error_session_expired',
          statusCode: 401,
        );
      }

      await _localDataSource.saveToken(token);
      return user;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    required int batchId,
    required int genderId,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        trainingId: trainingId,
        batchId: batchId,
        genderId: genderId,
      );

      final registerToken = user.token?.trim() ?? '';
      if (registerToken.isNotEmpty) {
        await _localDataSource.saveToken(registerToken);
        return user;
      }

      // Some backends don't include token on register response.
      // Fallback to login so upload-photo step still has an active session.
      final loginUser = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      if (loginUser.token != null && loginUser.token!.isNotEmpty) {
        await _localDataSource.saveToken(loginUser.token!.trim());
        return loginUser;
      }

      await _localDataSource.deleteToken();

      throw const ServerException(
        message:
            'Akun berhasil dibuat, tetapi sesi login belum tersedia. Silakan login kembali.',
        statusCode: 401,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<List<OpsiDropdown>> getTrainings() async {
    try {
      return await _remoteDataSource.getTrainings();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<List<OpsiDropdown>> getBatches() async {
    try {
      return await _remoteDataSource.getBatches();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<List<JenisKelamin>> getGenders() async {
    try {
      return await _remoteDataSource.getGenders();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<void> uploadPhoto({
    required String filePath,
    required String token,
  }) async {
    try {
      await _remoteDataSource.uploadPhoto(filePath: filePath, token: token);
    } on ServerException catch (e) {
      if (e.statusCode == 401) await _localDataSource.clearAll();
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _remoteDataSource.forgotPassword(email: email);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      await _remoteDataSource.verifyOtp(email: email, otp: otp);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        email: email,
        otp: otp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<String?> getToken() async => _localDataSource.getToken();

  @override
  Future<void> saveToken(String token) async =>
      _localDataSource.saveToken(token);

  @override
  Future<void> logout() async => _localDataSource.clearAll();
}
