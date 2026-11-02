import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/gold_price.dart';
import '../services/gold_price_history_service.dart';
import '../services/gold_price_service.dart';

enum GoldPriceStatus { idle, loading, success, error }

class ShopPriceState {
  final GoldPrice? data;
  final GoldPriceStatus status;
  final String? errorReason;

  /// Technical detail of the last failure (HTTP code, exception message, start
  /// of an unexpected body), shown after a manual refresh.
  final String? errorDetail;

  const ShopPriceState({
    required this.status,
    this.data,
    this.errorReason,
    this.errorDetail,
  });
}

class GoldPriceNotifier extends ChangeNotifier {
  final Box<GoldPrice> _box = Hive.box<GoldPrice>('goldPriceBox');

  final Map<String, ShopPriceState> _states = {};

  bool get isAnyLoading =>
      _states.values.any((state) => state.status == GoldPriceStatus.loading);

  ShopPriceState stateFor(String shopName) =>
      _states[shopName] ?? const ShopPriceState(status: GoldPriceStatus.idle);

  Map<String, ShopPriceState> get allStates => Map.unmodifiable(_states);

  /// Shows cached prices immediately, then fetches every shop so the cards
  /// are current on every launch (including shops added in an update, which
  /// have no cached price yet).
  GoldPriceNotifier() {
    _loadFromCache();
    fetchAll();
  }

  void _loadFromCache() {
    for (final cached in _box.values) {
      _states[cached.shopName] = ShopPriceState(
        status: GoldPriceStatus.success,
        data: cached,
      );
    }
    notifyListeners();
  }

  /// Fetches every shop; completes once all of them have succeeded or failed,
  /// returning each shop's final state.
  Future<Map<String, ShopPriceState>> fetchAll() async {
    final sources = GoldPriceService.sources;

    for (final source in sources) {
      _states[source.shopName] = ShopPriceState(
        status: GoldPriceStatus.loading,
        data: _states[source.shopName]?.data,
      );
    }

    notifyListeners();

    await Future.wait(sources.map(_fetchSource));
    return {
      for (final source in sources)
        source.shopName: stateFor(source.shopName),
    };
  }

  /// Re-fetch a single shop, e.g. from a card's refresh button. Completes with
  /// the shop's final state so the caller can report the result.
  Future<ShopPriceState> retry(String shopName) async {
    final source = GoldPriceService.sources.firstWhere(
      (s) => s.shopName == shopName,
      orElse: () => GoldPriceService.sources.first,
    );

    _states[shopName] = ShopPriceState(
      status: GoldPriceStatus.loading,
      data: _states[shopName]?.data,
    );
    notifyListeners();

    await _fetchSource(source);
    return stateFor(shopName);
  }

  /// Redraws the cards after price history changed outside a fetch (e.g. a
  /// manual sync), since cards read history for deltas and fallback prices.
  void notifyHistoryChanged() => notifyListeners();

  Future<void> _fetchSource(GoldPriceSource source) {
    return source.fetch().then((price) {
      _states[price.shopName] = ShopPriceState(
        status: GoldPriceStatus.success,
        data: price,
      );
      _box.put(price.shopName, price);
      GoldPriceHistoryService.record(price);
      notifyListeners();
    }).catchError((Object error) {
      final shopName = error is GoldPriceFetchException
          ? error.shopName
          : source.shopName;
      final reason =
          error is GoldPriceFetchException ? error.reason : 'unknown';
      // Keep what actually went wrong (e.g. a SocketException or
      // HandshakeException message) instead of collapsing it to "unknown".
      final detail = error is GoldPriceFetchException
          ? error.detail
          : _shorten(error.toString());

      _states[shopName] = ShopPriceState(
        status: GoldPriceStatus.error,
        data: _states[shopName]?.data,
        errorReason: reason,
        errorDetail: detail,
      );
      notifyListeners();
    });
  }

  static String _shorten(String text) =>
      text.length <= 120 ? text : '${text.substring(0, 120)}…';
}
