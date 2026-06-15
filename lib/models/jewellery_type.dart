import '../l10n/app_localizations.dart';

class JewelleryType {
  final int id;
  final String name;    // English — primary key for data consistency & export/import
  final String nameZh;  // Simplified Chinese display name
  final String nameMs;  // Bahasa Melayu display name
  final String iconKey;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  JewelleryType({
    required this.id,
    required this.name,
    this.nameZh = '',
    this.nameMs = '',
    this.iconKey = 'other',
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns the display name for the given locale, falling back to English.
  String localizedName(AppLocale locale) => switch (locale) {
        AppLocale.en => name,
        AppLocale.zhCN => nameZh.isNotEmpty ? nameZh : name,
        AppLocale.ms => nameMs.isNotEmpty ? nameMs : name,
      };

  JewelleryType copyWith({
    int? id,
    String? name,
    String? nameZh,
    String? nameMs,
    String? iconKey,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JewelleryType(
      id: id ?? this.id,
      name: name ?? this.name,
      nameZh: nameZh ?? this.nameZh,
      nameMs: nameMs ?? this.nameMs,
      iconKey: iconKey ?? this.iconKey,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameZh': nameZh,
      'nameMs': nameMs,
      'iconKey': iconKey,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory JewelleryType.fromJson(Map<String, dynamic> json) {
    return JewelleryType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameZh: json['nameZh'] ?? '',
      nameMs: json['nameMs'] ?? '',
      iconKey: json['iconKey'] as String? ?? 'other',
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
