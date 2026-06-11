import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gold_price_history_service.dart';

/// Seeds the price history database from bundled CSV assets on first launch.
///
/// The flag [_seedKey] is written to SharedPreferences once seeding completes
/// so subsequent launches skip the import entirely.
class GoldPriceHistorySeedService {
  static const String _seedKey = 'gold_history_seeded_v1';

  static const List<_SeedFile> _files = [
    _SeedFile(
      assetPath: 'assets/data/gold_price_history_poh_kong.csv',
      shopName: 'Poh Kong',
    ),
    _SeedFile(
      assetPath: 'assets/data/gold_price_history_chiang_heng.csv',
      shopName: 'Chiang Heng',
    ),
  ];

  /// Runs the seed import if it has never been done on this device.
  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seedKey) == true) return;

    for (final file in _files) {
      await _importCsv(file);
    }

    await prefs.setBool(_seedKey, true);
  }

  static Future<void> _importCsv(_SeedFile file) async {
    try {
      final raw = await rootBundle.loadString(file.assetPath);
      final lines = const LineSplitter().convert(raw);

      // Skip the header row.
      for (final line in lines.skip(1)) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final parts = trimmed.split(',');
        if (parts.length < 4) continue;

        final dateStr = parts[0].trim();
        final price916 = double.tryParse(parts[2].trim());
        final price999 = double.tryParse(parts[3].trim());

        if (price916 == null || price999 == null) continue;

        final recordedAt = _parseDate(dateStr);
        if (recordedAt == null) continue;

        // Only write if no entry already exists for this shop + day,
        // so live-fetched data is never overwritten by seed data.
        final key = '${file.shopName}|${GoldPriceHistoryService.dayKey(recordedAt)}';
        if (GoldPriceHistoryService.hasEntry(key)) continue;

        final point = GoldPriceHistoryPoint(
          shopName: file.shopName,
          price916: price916,
          price999: price999,
          recordedAt: recordedAt,
        );
        await GoldPriceHistoryService.recordPoint(point);
      }
    } catch (_) {
      // Non-fatal: if the asset is missing or malformed, skip silently.
    }
  }

  /// Parses two date formats found in the seed CSV files.
  ///
  /// Supported formats:
  ///   • `M/d/yyyy HH:mm`    — e.g. `5/29/2025 23:57`  (slash-separated)
  ///   • `yyyy-MM-dd HH:mm:ss` / `yyyy-MM-dd HH:mm`    (dash-separated)
  static DateTime? _parseDate(String value) {
    final parts = value.split(' ');
    if (parts.length < 2) return null;

    final datePart = parts[0];
    final timeParts = parts[1].split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;

    int? year, month, day;

    if (datePart.contains('/')) {
      // Format: M/d/yyyy
      final d = datePart.split('/');
      if (d.length != 3) return null;
      month = int.tryParse(d[0]);
      day = int.tryParse(d[1]);
      year = int.tryParse(d[2]);
    } else if (datePart.contains('-')) {
      // Format: yyyy-MM-dd
      final d = datePart.split('-');
      if (d.length != 3) return null;
      year = int.tryParse(d[0]);
      month = int.tryParse(d[1]);
      day = int.tryParse(d[2]);
    } else {
      return null;
    }

    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day, hour, minute, second);
  }
}

class _SeedFile {
  final String assetPath;
  final String shopName;

  const _SeedFile({required this.assetPath, required this.shopName});
}
