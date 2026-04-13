import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider({required SharedPreferences prefs})
    : _prefs = prefs,
      _locale = Locale(_normalizeCode(prefs.getString(_prefsKey)));

  static const String _prefsKey = 'lang';

  final SharedPreferences _prefs;
  Locale _locale;

  Locale get locale => _locale;

  void changeLanguage(String code) {
    final normalizedCode = _normalizeCode(code);

    if (_locale.languageCode == normalizedCode) {
      return;
    }

    _locale = Locale(normalizedCode);
    _saveToPrefs(normalizedCode);
    notifyListeners();
  }

  Future<void> _saveToPrefs(String code) async {
    await _prefs.setString(_prefsKey, code);
  }

  static String _normalizeCode(String? code) {
    const supportedCodes = {
      'id', 'en', 'zh', 'ms', 'ja', 'hi', 'es', 'fr', 'jv', 
      'min', 'su', 'btk', 'mnd'
    };

    if (code == null || !supportedCodes.contains(code)) {
      return 'id';
    }

    return code;
  }
}
