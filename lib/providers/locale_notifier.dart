import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class LocaleNotifier extends ChangeNotifier {
  static const _prefKey = 'app_locale';

  AppLocale _locale = AppLocale.en;

  AppLocale get locale => _locale;
  AppLocalizations get localizations => AppLocalizations(_locale);

  LocaleNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == null) return;
    final match = AppLocale.values.where((l) => l.name == saved).firstOrNull;
    if (match != null && match != _locale) {
      _locale = match;
      notifyListeners();
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.name);
  }
}
