class Jewellery {
  final int id;
  final DateTime date;
  final String name;
  final int? payerId;
  final int? ownerId;
  final double? size;
  final double? measurement;
  final int? jewelleryTypeId;
  final String brand;
  final String goldPurity;
  final int? pricePerGram;
  final double? weight;
  final double? laborFees;
  final double? totalPrice;
  final String? purchaseLocation;
  final List<String>? jewelleryPhoto;
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
    this.measurement,
    this.jewelleryTypeId,
    required this.brand,
    required this.goldPurity,
    this.pricePerGram,
    this.weight,
    this.laborFees,
    this.totalPrice,
    this.purchaseLocation,
    this.jewelleryPhoto,
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
    double? measurement,
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
      measurement: measurement ?? this.measurement,
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
      'measurement': measurement,
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
      id: json['id'],
      date: DateTime.parse(json['date']),
      name: json['name'],
      payerId: json['payerId'],
      ownerId: json['ownerId'],
      size: json['size']?.toDouble(),
      measurement: json['measurement']?.toDouble(),
      jewelleryTypeId: json['jewelleryTypeId'],
      brand: json['brand'],
      goldPurity: json['goldPurity'],
      pricePerGram: json['pricePerGram'],
      weight: json['weight']?.toDouble(),
      laborFees: json['laborFees']?.toDouble(),
      totalPrice: json['totalPrice']?.toDouble(),
      purchaseLocation: json['purchaseLocation'],
      jewelleryPhoto: List<String>.from(json['jewelleryPhoto'] ?? []),
      remarks: json['remarks'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
