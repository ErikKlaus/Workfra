import '../../../../core/error/exceptions.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profileRepository.dart';
import '../datasources/profileRemoteDatasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<User> getProfile({required String token}) async {
    try {
      return await _remoteDataSource.getProfile(token: token);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<User> updateProfile({
    required String token,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    try {
      return await _remoteDataSource.updateProfile(
        token: token,
        name: name,
        email: email,
        photoUrl: photoUrl,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<void> uploadPhoto({
    required String token,
    required String filePath,
  }) async {
    try {
      await _remoteDataSource.uploadPhoto(token: token, filePath: filePath);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: 0);
    }
  }
}
