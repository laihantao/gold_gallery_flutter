import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/gold_price.dart';
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
  final GoldPriceService _service = GoldPriceService();
  final Box<GoldPrice> _box = Hive.box<GoldPrice>('goldPriceBox');

  Map<String, ShopPriceState> _states = {};

  bool get isAnyLoading =>
      _states.values.any((state) => state.status == GoldPriceStatus.loading);

  ShopPriceState stateFor(String shopName) =>
      _states[shopName] ?? const ShopPriceState(status: GoldPriceStatus.idle);

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

    final futures = _service.fetchAll();
    for (final future in futures) {
      future.then((price) {
        _states[price.shopName] = ShopPriceState(
          status: GoldPriceStatus.success,
          data: price,
        );
        _box.put(price.shopName, price);
        notifyListeners();
      }).catchError((Object error) {
        final shopName =
            error is GoldPriceFetchException ? error.shopName : 'Unknown';
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
}
