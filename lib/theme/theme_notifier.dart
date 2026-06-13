import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'aurum_theme';
  AurumTheme _currentTheme = AurumTheme.parchment;

  AurumTheme get currentTheme => _currentTheme;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString(_themeKey) ?? AurumTheme.parchment.id;
    _currentTheme = AurumTheme.values.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => AurumTheme.parchment,
    );
    notifyListeners();
  }

  Future<void> setTheme(AurumTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.id);
    notifyListeners();
  }

  ThemeData getThemeData() => _currentTheme.toThemeData();
}
