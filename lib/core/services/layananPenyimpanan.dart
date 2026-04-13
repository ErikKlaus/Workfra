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

  Future<bool> saveString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> saveStringList(String key, List<String> values) async {
    return _prefs.setStringList(key, values);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? const [];
  }

  Future<bool> remove(String key) async {
    return _prefs.remove(key);
  }

  Future<void> clearSessionScopedCaches() async {
    const cachePrefixes = [
      'cache_profile_v1',
      'cache_combined_history_v1',
      'pending_izin_queue_v1',
    ];

    final keys = _prefs.getKeys();
    for (final key in keys) {
      final shouldRemove = cachePrefixes.any(
        (prefix) => key.startsWith(prefix),
      );
      if (shouldRemove) {
        await _prefs.remove(key);
      }
    }
  }
}
