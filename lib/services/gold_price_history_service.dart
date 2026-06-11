import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/gold_price.dart';

/// A single recorded snapshot of a shop's prices on a given day.
class GoldPriceHistoryPoint {
  final String shopName;
  final double? price916;
  final double? price999;
  final DateTime recordedAt;

  const GoldPriceHistoryPoint({
    required this.shopName,
    required this.recordedAt,
    this.price916,
    this.price999,
  });

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        'price916': price916,
        'price999': price999,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory GoldPriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    return GoldPriceHistoryPoint(
      shopName: json['shopName'] as String? ?? '',
      price916: (json['price916'] as num?)?.toDouble(),
      price999: (json['price999'] as num?)?.toDouble(),
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

/// Persists a daily history of gold prices per shop.
///
/// History is stored as JSON strings in a [Box] keyed by `"$shopName|yyyy-MM-dd"`,
/// so each shop keeps at most one point per day (the latest fetch wins). This
/// avoids a Hive adapter / codegen step entirely.
class GoldPriceHistoryService {
  static const String boxName = 'goldPriceHistoryBox';

  static Box<String> get _box => Hive.box<String>(boxName);

  /// Public accessor so the seed service can compute the same key format.
  static String dayKey(DateTime date) => _dayKey(date);

  /// Returns true if an entry already exists for the given Hive key.
  static bool hasEntry(String key) => _box.containsKey(key);

  /// Writes a [GoldPriceHistoryPoint] directly (used during seeding).
  static Future<void> recordPoint(GoldPriceHistoryPoint point) async {
    await _box.put(
      _entryKey(point.shopName, point.recordedAt),
      jsonEncode(point.toJson()),
    );
  }

  static String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _entryKey(String shopName, DateTime date) =>
      '$shopName|${_dayKey(date)}';

  /// Records a fetched price as today's snapshot for its shop.
  static Future<void> record(GoldPrice price) async {
    if (price.price916 == null && price.price999 == null) return;

    final at = price.fetchedAt ?? DateTime.now();
    final point = GoldPriceHistoryPoint(
      shopName: price.shopName,
      price916: price.price916,
      price999: price.price999,
      recordedAt: at,
    );
    await _box.put(_entryKey(price.shopName, at), jsonEncode(point.toJson()));
  }

  /// Returns all recorded points for a shop, oldest first.
  static List<GoldPriceHistoryPoint> historyFor(String shopName) {
    final prefix = '$shopName|';
    final points = <GoldPriceHistoryPoint>[];
    for (final key in _box.keys) {
      if (key is String && key.startsWith(prefix)) {
        final raw = _box.get(key);
        if (raw == null) continue;
        try {
          points.add(
            GoldPriceHistoryPoint.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          // Skip malformed entries.
        }
      }
    }
    points.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return points;
  }

  /// The most recent point strictly before today's, used to compute a
  /// day-over-day delta on the card.
  static GoldPriceHistoryPoint? previousPoint(String shopName) {
    final points = historyFor(shopName);
    if (points.length < 2) return null;
    final todayKey = _dayKey(DateTime.now());
    // Walk backwards to the first point recorded on an earlier day.
    for (var i = points.length - 1; i >= 0; i--) {
      if (_dayKey(points[i].recordedAt) != todayKey) {
        return points[i];
      }
    }
    return null;
  }
}
