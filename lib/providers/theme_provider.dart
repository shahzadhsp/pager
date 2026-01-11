import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // default system theme

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  // Set theme
  void setTheme(ThemeMode mode) {
    if (_themeMode == mode) return; // avoid unnecessary rebuild
    _themeMode = mode;
    notifyListeners();
  }

  // Toggle theme (optional helper)
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }
}
