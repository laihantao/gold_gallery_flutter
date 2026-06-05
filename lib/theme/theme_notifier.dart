import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.gold;

  AppTheme get currentTheme => _currentTheme;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString(_themeKey) ?? 'gold';
    _currentTheme = AppTheme.values.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => AppTheme.gold,
    );
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.id);
    notifyListeners();
  }

  ThemeData getThemeData() => _currentTheme.toThemeData();
}
