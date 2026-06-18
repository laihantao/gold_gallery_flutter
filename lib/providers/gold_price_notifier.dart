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

  const ShopPriceState({
    required this.status,
    this.data,
    this.errorReason,
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

  Future<void> fetchAll() async {
    for (final source in GoldPriceService.sources) {
      _states[source.shopName] = ShopPriceState(
        status: GoldPriceStatus.loading,
        data: _states[source.shopName]?.data,
      );
    }

    notifyListeners();

    for (final source in GoldPriceService.sources) {
      _fetchSource(source);
    }
  }

  /// Re-fetch a single shop, e.g. from a per-card "Retry" action.
  Future<void> retry(String shopName) async {
    final source = GoldPriceService.sources.firstWhere(
      (s) => s.shopName == shopName,
      orElse: () => GoldPriceService.sources.first,
    );

    _states[shopName] = ShopPriceState(
      status: GoldPriceStatus.loading,
      data: _states[shopName]?.data,
    );
    notifyListeners();

    _fetchSource(source);
  }

  void _fetchSource(GoldPriceSource source) {
    source.fetch().then((price) {
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

      _states[shopName] = ShopPriceState(
        status: GoldPriceStatus.error,
        data: _states[shopName]?.data,
        errorReason: reason,
      );
      notifyListeners();
    });
  }
}
