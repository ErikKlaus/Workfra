import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _sessionValidFlagKey = 'auth_session_valid_v1';
  static const String _firstInstallMarkerKey = 'app_install_marker_v1';

  static const List<String> _rememberedEmailKeys = [
    'remembered_email',
    'remember_me_email',
    'remember_email',
    'last_login_email',
  ];

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

  bool isFirstInstallHandled() {
    return _prefs.getBool(_firstInstallMarkerKey) ?? false;
  }

  Future<void> markFirstInstallHandled() async {
    await _prefs.setBool(_firstInstallMarkerKey, true);
  }

  Future<void> markSessionValidated() async {
    await _prefs.setBool(_sessionValidFlagKey, true);
  }

  Future<void> clearSessionValidationFlag() async {
    await _prefs.remove(_sessionValidFlagKey);
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

  Future<void> clearAuthSessionData() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_sessionValidFlagKey);

    for (final key in _rememberedEmailKeys) {
      await _prefs.remove(key);
    }
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

  Future<void> clearAuthStartupArtifacts() async {
    await clearAuthSessionData();
    await clearSessionScopedCaches();
  }
}
