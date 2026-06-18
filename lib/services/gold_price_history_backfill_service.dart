import 'dart:convert';

import 'package:http/http.dart' as http;

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

  /// Manual sync triggered by the user — always attempts a fetch from the
  /// latest stored date up to today (inclusive), so the user can force a
  /// refresh even when the auto-backfill found no gap.
  ///
  /// Returns the number of records inserted, or throws on network failure
  /// (so the caller can show a proper error message).
  static Future<int> manualSync() async {
    final today = _dateOnly(DateTime.now());

    DateTime? earliestFrom;

    for (final shopName in _shopNames) {
      final history = GoldPriceHistoryService.historyFor(shopName);

      DateTime fromDate;
      if (history.isEmpty) {
        // No local data at all — fetch the last 30 days as a safe default.
        fromDate = today.subtract(const Duration(days: 30));
      } else {
        final latestDate = _dateOnly(history.last.recordedAt);
        if (!latestDate.isBefore(today)) continue; // fully up to date
        fromDate = latestDate.add(const Duration(days: 1));
      }

      if (earliestFrom == null || fromDate.isBefore(earliestFrom)) {
        earliestFrom = fromDate;
      }
    }

    if (earliestFrom == null) return 0; // all shops are current

    // propagateError = true so the UI can catch and show a proper message.
    return _fetchAndStore(from: earliestFrom, to: today, propagateError: true);
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
