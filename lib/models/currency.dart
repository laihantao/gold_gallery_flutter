class Currency {
  final int id;
  final String name;
  final String symbol;

  Currency({
    required this.id,
    required this.name,
    required this.symbol,
  });

  Currency copyWith({
    int? id,
    String? name,
    String? symbol,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
    };
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
    );
  }
}
