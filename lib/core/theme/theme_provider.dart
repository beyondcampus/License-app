import 'package:flutter/material.dart';

import '../services/prefs_service.dart';

/// App-level theme mode state, persisted via [PrefsService].
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) : _mode = _prefs.themeMode;

  final PrefsService _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;
  bool get isDark => _mode != ThemeMode.light;

  Future<void> toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setThemeMode(mode);
  }
}
