import '../models/jewellery.dart';
import '../providers/gold_price_notifier.dart';

class MarketValueService {
  /// Gold price strictly for the item's own brand.
  /// Returns null if the brand's price hasn't been fetched yet — the UI will
  /// then show a hint rather than silently using another brand's price.
  static double? goldPriceFor(
      Jewellery j, Map<String, ShopPriceState> states) {
    final brandState = states[j.brand];
    if (brandState?.status != GoldPriceStatus.success) return null;
    final data = brandState!.data;
    if (data == null) return null;
    final price = j.goldPurity == '999' ? data.price999 : data.price916;
    return (price != null && price > 0) ? price : null;
  }

  /// Vendor name used for display — always the item's own brand.
  static String? vendorNameFor(
      Jewellery j, Map<String, ShopPriceState> states) {
    final price = goldPriceFor(j, states);
    return price != null ? j.brand : null;
  }

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

  /// Name of the vendor whose price was selected by [bestGoldPrice].
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

  /// Gold-only current value = weight × brand price (excludes labor fees).
  /// Used for buyback estimation.
  static double? currentValue(
      Jewellery j, Map<String, ShopPriceState> states) {
    if (j.weight == null || j.weight! <= 0) return null;
    final price = goldPriceFor(j, states);
    if (price == null) return null;
    return j.weight! * price;
  }

  /// Current value including labor fees — for apples-to-apples comparison
  /// against totalPrice (which also includes labor fees).
  static double? currentValueWithLabor(
      Jewellery j, Map<String, ShopPriceState> states) {
    final goldVal = currentValue(j, states);
    if (goldVal == null) return null;
    return goldVal + (j.laborFees ?? 0);
  }

  /// Gain/loss = (currentGoldValue + laborFees) − totalPrice.
  /// Both sides include labor fees so the delta reflects pure gold price movement.
  static double? gainLoss(Jewellery j, Map<String, ShopPriceState> states) {
    final curr = currentValueWithLabor(j, states);
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
