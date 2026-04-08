import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';

  bool _isDarkMode;

  ThemeProvider({bool initialIsDarkMode = false})
    : _isDarkMode = initialIsDarkMode;

  bool get isDarkMode => _isDarkMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final nextValue = prefs.getBool(_themeKey) ?? false;
    if (_isDarkMode == nextValue) {
      return;
    }
    _isDarkMode = nextValue;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    if (_isDarkMode == value) {
      return;
    }

    _isDarkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }
}
