class Currency {
  final int id;
  final String name;
  final String symbol;
  final String code;

  Currency({
    required this.id,
    required this.name,
    required this.symbol,
    required this.code,
  });

  Currency copyWith({
    int? id,
    String? name,
    String? symbol,
    String? code,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      code: code ?? this.code,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'code': code,
    };
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    final symbol = json['symbol'] as String? ?? 'RM';
    return Currency(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      symbol: symbol,
      code: json['code'] as String? ?? _defaultCodeForSymbol(symbol),
    );
  }

  static String _defaultCodeForSymbol(String symbol) {
    return switch (symbol.toUpperCase()) {
      'RM' => 'MYR',
      'SGD' => 'SGD',
      'RMB' => 'CNY',
      _ => symbol.toUpperCase(),
    };
  }
}
