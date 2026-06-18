import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gold_alert.dart';

class GoldAlertNotifier extends ChangeNotifier {
  static const _prefKey = 'gold_alerts_v1';

  List<GoldAlert> _alerts = [];
  final List<TriggeredAlert> _triggered = [];

  List<GoldAlert> get alerts => List.unmodifiable(_alerts);
  List<TriggeredAlert> get triggered => List.unmodifiable(_triggered);

  GoldAlertNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _alerts = list
          .map((e) => GoldAlert.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey, jsonEncode(_alerts.map((a) => a.toJson()).toList()));
  }

  List<GoldAlert> alertsFor(String shopName) =>
      _alerts.where((a) => a.shopName == shopName).toList();

  Future<void> addOrUpdate(GoldAlert alert) async {
    final idx = _alerts.indexWhere(
      (a) => a.shopName == alert.shopName && a.purity == alert.purity,
    );
    if (idx >= 0) {
      _alerts[idx] = alert;
    } else {
      _alerts.add(alert);
    }
    await _save();
    notifyListeners();
  }

  Future<void> remove(GoldAlert alert) async {
    _alerts.removeWhere(
        (a) => a.shopName == alert.shopName && a.purity == alert.purity);
    await _save();
    notifyListeners();
  }

  /// Called by [GoldPriceSection] after fresh prices arrive.
  void checkPrices(Map<String, Map<String, double?>> latestPrices) {
    final newTriggered = <TriggeredAlert>[];
    for (final alert in _alerts) {
      if (!alert.isActive) continue;
      final shopPrices = latestPrices[alert.shopName];
      if (shopPrices == null) continue;
      final price = shopPrices[alert.purity];
      if (price == null) continue;

      final triggered = alert.alertAbove
          ? price >= alert.targetPrice
          : price <= alert.targetPrice;

      if (triggered) {
        newTriggered.add(TriggeredAlert(alert: alert, currentPrice: price));
      }
    }
    if (newTriggered.isNotEmpty) {
      _triggered
        ..clear()
        ..addAll(newTriggered);
      notifyListeners();
    }
  }

  void dismissAll() {
    _triggered.clear();
    notifyListeners();
  }

  void dismiss(TriggeredAlert t) {
    _triggered.remove(t);
    notifyListeners();
  }
}
