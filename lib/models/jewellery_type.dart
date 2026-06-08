class JewelleryType {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  JewelleryType({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  JewelleryType copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JewelleryType(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory JewelleryType.fromJson(Map<String, dynamic> json) {
    return JewelleryType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}
