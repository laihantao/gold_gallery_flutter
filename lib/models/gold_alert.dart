class GoldAlert {
  final String shopName;
  final String purity; // '916' or '999'
  final double targetPrice;
  final bool alertAbove; // true = trigger when price >= target
  final bool isActive;
  final String id; // shopName|purity|above|target

  const GoldAlert({
    required this.shopName,
    required this.purity,
    required this.targetPrice,
    required this.alertAbove,
    this.isActive = true,
  }) : id = '$shopName|$purity|$alertAbove|$targetPrice';

  GoldAlert copyWith({bool? isActive, double? targetPrice, bool? alertAbove}) {
    return GoldAlert(
      shopName: shopName,
      purity: purity,
      targetPrice: targetPrice ?? this.targetPrice,
      alertAbove: alertAbove ?? this.alertAbove,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        'purity': purity,
        'targetPrice': targetPrice,
        'alertAbove': alertAbove,
        'isActive': isActive,
      };

  factory GoldAlert.fromJson(Map<String, dynamic> json) => GoldAlert(
        shopName: json['shopName'] as String,
        purity: json['purity'] as String,
        targetPrice: (json['targetPrice'] as num).toDouble(),
        alertAbove: json['alertAbove'] as bool,
        isActive: json['isActive'] as bool? ?? true,
      );
}

class TriggeredAlert {
  final GoldAlert alert;
  final double currentPrice;
  const TriggeredAlert({required this.alert, required this.currentPrice});
}
