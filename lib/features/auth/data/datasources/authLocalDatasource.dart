import '../../../../core/error/exceptions.dart';
import '../../../../core/services/layananPenyimpanan.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  String? getToken();
  bool hasToken();
  Future<void> deleteToken();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StorageService _storageService;

  AuthLocalDataSourceImpl(this._storageService);

  @override
  Future<void> saveToken(String token) async {
    final success = await _storageService.saveToken(token);
    if (!success) {
      throw const CacheException(message: 'Gagal menyimpan token');
    }
  }

  @override
  String? getToken() {
    return _storageService.getToken();
  }

  @override
  bool hasToken() {
    return _storageService.hasToken();
  }

  @override
  Future<void> deleteToken() async {
    await _storageService.deleteToken();
  }

  @override
  Future<void> clearAll() async {
    await _storageService.clearAll();
  }
}
