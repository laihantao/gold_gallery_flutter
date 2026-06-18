class Collection {
  final String id;
  final String name;
  final List<int> jewelleryIds;
  final DateTime createdAt;

  const Collection({
    required this.id,
    required this.name,
    required this.jewelleryIds,
    required this.createdAt,
  });

  Collection copyWith({String? name, List<int>? jewelleryIds}) {
    return Collection(
      id: id,
      name: name ?? this.name,
      jewelleryIds: jewelleryIds ?? this.jewelleryIds,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'jewelleryIds': jewelleryIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        name: json['name'] as String,
        jewelleryIds: (json['jewelleryIds'] as List<dynamic>)
            .map((e) => e as int)
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
