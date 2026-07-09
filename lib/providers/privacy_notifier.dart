import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide toggle for masking monetary values (e.g. when showing the phone to
/// others). Persisted, and defaults to hidden.
class PrivacyNotifier extends ChangeNotifier {
  static const _key = 'values_hidden_v1';

  bool _valuesHidden = true;
  bool get valuesHidden => _valuesHidden;

  PrivacyNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_key);
    if (stored != null && stored != _valuesHidden) {
      _valuesHidden = stored;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _valuesHidden = !_valuesHidden;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _valuesHidden);
  }
}
