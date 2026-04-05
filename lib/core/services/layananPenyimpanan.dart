import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';

  StorageService(this._prefs);

  Future<bool> saveToken(String token) async {
    return _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  bool hasToken() {
    return _prefs.containsKey(_tokenKey) &&
        (_prefs.getString(_tokenKey)?.isNotEmpty ?? false);
  }

  Future<bool> deleteToken() async {
    return _prefs.remove(_tokenKey);
  }

  Future<bool> saveUserName(String name) async {
    return _prefs.setString(_userNameKey, name);
  }

  String? getUserName() {
    return _prefs.getString(_userNameKey);
  }

  Future<bool> clearAll() async {
    return _prefs.clear();
  }
}
