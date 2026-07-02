import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'gold_price_history_service.dart';

/// Fetches missing days of gold price history from the Google Apps Script
/// web endpoint and upserts them into the local Hive history store.
///
/// Runs at startup (after seed) to patch gaps caused by the app not being
/// opened for several days — or after a reinstall.
class GoldPriceHistoryBackfillService {
  // ── IMPORTANT: paste your deployed Apps Script Web App URL here ──────────
  static const String _webAppUrl =
      'https://script.google.com/macros/s/AKfycbwGTHOMglUn03qW9l6htqn2hFijITLv0P6uZZNNxqM4gDP8-Jgunqw-jVmj6wd3HFzk/exec';
  // ─────────────────────────────────────────────────────────────────────────

  static const List<String> _shopNames = ['Chiang Heng', 'Poh Kong', 'Tomei'];
  static const Duration _timeout = Duration(seconds: 15);

  static const _reconcileKey = 'gold_history_reconciled';

  /// Reconciles the last 7 days of history against Google Sheets.
  ///
  /// At startup this runs at most once per day ([force] = false).
  /// When triggered manually from Settings, pass [force] = true to always run.
  static Future<void> reconcileRecentHistory({bool force = false}) async {
    final today = _fmt(_dateOnly(DateTime.now()));

    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_reconcileKey) == today) return;
    }

    final from = _dateOnly(DateTime.now().subtract(const Duration(days: 7)));
    await _fetchAndStore(from: from, to: _dateOnly(DateTime.now()));

    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reconcileKey, today);
    }
  }

  /// Auto-backfill on startup — returns the number of records inserted.
  /// Returns 0 when there are no gaps (fast path, no HTTP call made).
  static Future<int> backfillIfNeeded() async {
    final yesterday = _dateOnly(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    DateTime? earliestFrom;

    for (final shopName in _shopNames) {
      final history = GoldPriceHistoryService.historyFor(shopName);
      if (history.isEmpty) continue;

      final latestDate = _dateOnly(history.last.recordedAt);
      if (!latestDate.isBefore(yesterday)) continue; // no gap

      final fromDate = latestDate.add(const Duration(days: 1));
      if (earliestFrom == null || fromDate.isBefore(earliestFrom)) {
        earliestFrom = fromDate;
      }
    }

    if (earliestFrom == null) return 0; // nothing to do

    return _fetchAndStore(from: earliestFrom, to: yesterday);
  }

  /// Manual sync triggered by the user — scans the last [_lookbackDays] of
  /// history per shop and fetches any missing days, including gaps in the
  /// middle (e.g. June 18 absent even though June 19 is present).
  ///
  /// Returns the number of records inserted, or throws on network failure
  /// (so the caller can show a proper error message).
  static const int _lookbackDays = 30;

  static Future<int> manualSync() async {
    final today = _dateOnly(DateTime.now());
    final lookbackStart = today.subtract(const Duration(days: _lookbackDays));

    DateTime? earliestMissing;

    for (final shopName in _shopNames) {
      final history = GoldPriceHistoryService.historyFor(shopName);

      if (history.isEmpty) {
        // No local data at all — pull the full lookback window.
        if (earliestMissing == null || lookbackStart.isBefore(earliestMissing)) {
          earliestMissing = lookbackStart;
        }
        continue;
      }

      // Build a fast lookup of days we already have for this shop.
      final existingDays = <String>{
        for (final p in history) _fmt(_dateOnly(p.recordedAt)),
      };

      // Scan from the older of (first local record, lookbackStart) up to today.
      // This detects internal gaps (e.g. June 18 missing while June 19 exists).
      final firstLocal = _dateOnly(history.first.recordedAt);
      final scanFrom = firstLocal.isBefore(lookbackStart) ? lookbackStart : firstLocal;

      for (var d = scanFrom; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
        if (!existingDays.contains(_fmt(d))) {
          if (earliestMissing == null || d.isBefore(earliestMissing)) {
            earliestMissing = d;
          }
          break; // only need the earliest missing date per shop
        }
      }
    }

    if (earliestMissing == null) return 0; // no gaps found

    // propagateError = true so the UI can catch and show a proper message.
    return _fetchAndStore(from: earliestMissing, to: today, propagateError: true);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String _fmt(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static Future<int> _fetchAndStore({
    required DateTime from,
    required DateTime to,
    bool propagateError = false,
  }) async {
    final uri = Uri.parse(_webAppUrl).replace(queryParameters: {
      'from': _fmt(from),
      'to': _fmt(to),
    });

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = (json['data'] as List<dynamic>?) ?? [];

      var count = 0;
      for (final item in dataList) {
        final map = item as Map<String, dynamic>;

        final shopName = map['shop'] as String?;
        final dateStr  = map['date']  as String?;
        final price916 = (map['price916'] as num?)?.toDouble();
        final price999 = (map['price999'] as num?)?.toDouble();

        if (shopName == null || dateStr == null) continue;
        if (price916 == null && price999 == null) continue;

        final parts = dateStr.split('-');
        if (parts.length != 3) continue;
        final recordedAt = DateTime(
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 1,
          int.tryParse(parts[2]) ?? 1,
          12, // noon — avoids timezone midnight edge cases
        );

        await GoldPriceHistoryService.recordPoint(
          GoldPriceHistoryPoint(
            shopName: shopName,
            price916: price916,
            price999: price999,
            recordedAt: recordedAt,
          ),
        );
        count++;
      }
      return count;
    } catch (e) {
      if (propagateError) rethrow;
      return 0; // silent failure for auto-backfill
    }
  }
}
