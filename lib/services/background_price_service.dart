import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/gold_alert.dart';
import 'notification_service.dart';

// ── Constants ──────────────────────────────────────────────────────────────────

const _taskUniqueName = 'pocket-gold-daily-price-check';
const _taskName = 'backgroundPriceCheck';

const _gasUrl =
    'https://script.google.com/macros/s/AKfycbwGTHOMglUn03qW9l6htqn2hFijITLv0P6uZZNxqM4gDP8-Jgunqw-jVmj6wd3HFzk/exec';
const _alertsPrefKey = 'gold_alerts_v1';
const _lastFetchPrefKey = 'last_price_fetch_ms';

// ── WorkManager entry point ────────────────────────────────────────────────────

/// Must be a top-level function. Called by WorkManager on a background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskName) return true;
    try {
      await _backgroundPriceCheck();
      return true;
    } catch (_) {
      return false;
    }
  });
}

// ── Registration helper ────────────────────────────────────────────────────────

/// Call once from main() to register the daily background task.
/// Targets 1:30 PM local time (after the AppScript finishes at ~1 PM).
/// Uses [ExistingWorkPolicy.keep] so reinstalling the app doesn't reschedule.
/// No-ops on platforms where WorkManager is unsupported (web, Windows, macOS).
Future<void> registerDailyPriceCheck() async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _taskUniqueName,
    _taskName,
    frequency: const Duration(hours: 24),
    initialDelay: _delayUntil(hour: 13, minute: 30),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// Calculates how long until the next occurrence of [hour]:[minute] local time.
Duration _delayUntil({required int hour, required int minute}) {
  final now = DateTime.now();
  var target = DateTime(now.year, now.month, now.day, hour, minute);
  if (!now.isBefore(target)) {
    target = target.add(const Duration(days: 1));
  }
  return target.difference(now);
}

// ── Background task logic ──────────────────────────────────────────────────────

Future<void> _backgroundPriceCheck() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();

  // Read stored active alerts.
  final raw = prefs.getString(_alertsPrefKey);
  if (raw == null) return;

  final List<GoldAlert> alerts;
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    alerts = list
        .map((e) => GoldAlert.fromJson(e as Map<String, dynamic>))
        .where((a) => a.isActive)
        .toList();
  } catch (_) {
    return;
  }
  if (alerts.isEmpty) return;

  // Fetch today's prices from the Google Apps Script endpoint.
  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final uri = Uri.parse(_gasUrl)
      .replace(queryParameters: {'from': dateStr, 'to': dateStr});

  final response =
      await http.get(uri).timeout(const Duration(seconds: 20));
  if (response.statusCode != 200) return;

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final dataList = (json['data'] as List<dynamic>?) ?? [];
  if (dataList.isEmpty) return;

  // Build price map: { shopName → { purity → price } }
  final prices = <String, Map<String, double>>{};
  for (final item in dataList) {
    final map = item as Map<String, dynamic>;
    final shopName = map['shop'] as String?;
    final price916 = (map['price916'] as num?)?.toDouble();
    final price999 = (map['price999'] as num?)?.toDouble();
    if (shopName == null) continue;
    prices[shopName] = {
      '916': ?price916,
      '999': ?price999,
    };
  }

  // Check each alert and fire notification if matched.
  for (final alert in alerts) {
    final price = prices[alert.shopName]?[alert.purity];
    if (price == null) continue;
    final triggered =
        alert.alertAbove ? price >= alert.targetPrice : price <= alert.targetPrice;
    if (triggered) {
      await NotificationService.showPriceAlert(alert, price);
    }
  }

  // Update last-fetch timestamp so the home page skips the next auto-fetch.
  await prefs.setInt(
      _lastFetchPrefKey, DateTime.now().millisecondsSinceEpoch);
}
