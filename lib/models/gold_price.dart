import 'package:hive/hive.dart';

part 'gold_price.g.dart';

@HiveType(typeId: 10)
class GoldPrice extends HiveObject {
  @HiveField(0)
  String shopName;

  @HiveField(1)
  double? price916;

  @HiveField(2)
  double? price999;

  @HiveField(3)
  DateTime? fetchedAt;

  @HiveField(4)
  String? websiteDate;

  @HiveField(5)
  String? logoAsset;

  GoldPrice({
    required this.shopName,
    this.price916,
    this.price999,
    this.fetchedAt,
    this.websiteDate,
    this.logoAsset,
  });
}
