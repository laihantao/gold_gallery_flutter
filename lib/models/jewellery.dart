class Jewellery {
  final int id;
  final DateTime date;
  final String name;
  final int? payerId;
  final int? ownerId;
  final double? size;
  final String? measurementUnit;
  final int? jewelleryTypeId;
  final String brand;
  final String goldPurity;
  final int? pricePerGram;
  final double? weight;
  final double? laborFees;
  final double? totalPrice;
  final String? purchaseLocation;
  final List<String> jewelleryPhoto;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  Jewellery({
    required this.id,
    required this.date,
    required this.name,
    this.payerId,
    this.ownerId,
    this.size,
    this.measurementUnit,
    this.jewelleryTypeId,
    required this.brand,
    required this.goldPurity,
    this.pricePerGram,
    this.weight,
    this.laborFees,
    this.totalPrice,
    this.purchaseLocation,
    required this.jewelleryPhoto,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  Jewellery copyWith({
    int? id,
    DateTime? date,
    String? name,
    int? payerId,
    int? ownerId,
    double? size,
    String? measurementUnit,
    int? jewelleryTypeId,
    String? brand,
    String? goldPurity,
    int? pricePerGram,
    double? weight,
    double? laborFees,
    double? totalPrice,
    String? purchaseLocation,
    List<String>? jewelleryPhoto,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Jewellery(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      payerId: payerId ?? this.payerId,
      ownerId: ownerId ?? this.ownerId,
      size: size ?? this.size,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      jewelleryTypeId: jewelleryTypeId ?? this.jewelleryTypeId,
      brand: brand ?? this.brand,
      goldPurity: goldPurity ?? this.goldPurity,
      pricePerGram: pricePerGram ?? this.pricePerGram,
      weight: weight ?? this.weight,
      laborFees: laborFees ?? this.laborFees,
      totalPrice: totalPrice ?? this.totalPrice,
      purchaseLocation: purchaseLocation ?? this.purchaseLocation,
      jewelleryPhoto: jewelleryPhoto ?? this.jewelleryPhoto,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'name': name,
      'payerId': payerId,
      'ownerId': ownerId,
      'size': size,
      'measurementUnit': measurementUnit,
      'jewelleryTypeId': jewelleryTypeId,
      'brand': brand,
      'goldPurity': goldPurity,
      'pricePerGram': pricePerGram,
      'weight': weight,
      'laborFees': laborFees,
      'totalPrice': totalPrice,
      'purchaseLocation': purchaseLocation,
      'jewelleryPhoto': jewelleryPhoto,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Jewellery.fromJson(Map<String, dynamic> json) {
    return Jewellery(
      id: json['id'] ?? 0,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      name: json['name'] ?? '',
      payerId: json['payerId'],
      ownerId: json['ownerId'],
      size: json['size'] != null ? (json['size'] as num).toDouble() : null,
      measurementUnit: json['measurementUnit'],
      jewelleryTypeId: json['jewelleryTypeId'],
      brand: json['brand'] ?? '',
      goldPurity: json['goldPurity'] ?? '916',
      pricePerGram: json['pricePerGram'],
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      laborFees: json['laborFees'] != null
          ? (json['laborFees'] as num).toDouble()
          : null,
      totalPrice: json['totalPrice'] != null
          ? (json['totalPrice'] as num).toDouble()
          : null,
      purchaseLocation: json['purchaseLocation'],
      jewelleryPhoto: json['jewelleryPhoto'] != null
          ? List<String>.from(json['jewelleryPhoto'] ?? [])
          : [],
      remarks: json['remarks'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
