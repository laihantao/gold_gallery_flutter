import '../models/jewellery.dart';
import '../providers/gold_price_notifier.dart';

class MarketValueService {
  /// The most recently fetched successful price for [purity] across all vendors.
  static double? bestGoldPrice(
      String purity, Map<String, ShopPriceState> states) {
    double? bestPrice;
    DateTime? bestTime;

    for (final state in states.values) {
      if (state.status != GoldPriceStatus.success) continue;
      final data = state.data;
      if (data == null) continue;

      final price = purity == '999' ? data.price999 : data.price916;
      if (price == null || price <= 0) continue;

      final fetchedAt = data.fetchedAt;
      if (bestTime == null ||
          (fetchedAt != null && fetchedAt.isAfter(bestTime))) {
        bestPrice = price;
        bestTime = fetchedAt;
      }
    }
    return bestPrice;
  }

  /// Name of the vendor whose price was selected.
  static String? bestVendorName(
      String purity, Map<String, ShopPriceState> states) {
    String? bestVendor;
    DateTime? bestTime;

    for (final entry in states.entries) {
      final state = entry.value;
      if (state.status != GoldPriceStatus.success) continue;
      final data = state.data;
      if (data == null) continue;

      final price = purity == '999' ? data.price999 : data.price916;
      if (price == null || price <= 0) continue;

      final fetchedAt = data.fetchedAt;
      if (bestTime == null ||
          (fetchedAt != null && fetchedAt.isAfter(bestTime))) {
        bestVendor = entry.key;
        bestTime = fetchedAt;
      }
    }
    return bestVendor;
  }

  /// Current market value = weight × bestGoldPrice.
  static double? currentValue(
      Jewellery j, Map<String, ShopPriceState> states) {
    if (j.weight == null || j.weight! <= 0) return null;
    final price = bestGoldPrice(j.goldPurity, states);
    if (price == null) return null;
    return j.weight! * price;
  }

  /// Gain/loss = currentValue − totalPrice (positive = gain).
  static double? gainLoss(Jewellery j, Map<String, ShopPriceState> states) {
    final curr = currentValue(j, states);
    if (curr == null) return null;
    if (j.totalPrice == null || j.totalPrice! <= 0) return null;
    return curr - j.totalPrice!;
  }

  /// Gain/loss as a percentage of purchase cost.
  static double? gainLossPct(
      Jewellery j, Map<String, ShopPriceState> states) {
    final gl = gainLoss(j, states);
    if (gl == null) return null;
    if (j.totalPrice == null || j.totalPrice! <= 0) return null;
    return (gl / j.totalPrice!) * 100;
  }
}
