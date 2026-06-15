import '../l10n/app_localizations.dart';

/// One splash-screen tagline with a translation for every supported [AppLocale].
///
/// The JSON shape mirrors the [AppLocale.name] values so that adding a new
/// locale to the app automatically picks up its translation — no code change
/// needed here.
///
/// JSON example:
/// ```json
/// {
///   "id": "every_piece_tells_a_story",
///   "en":   "Every piece tells a story",
///   "zhCN": "每件珠宝，都有故事",
///   "ms":   "Setiap perhiasan punya cerita"
/// }
/// ```
class SplashCaption {
  final String id;
  final Map<AppLocale, String> _translations;

  const SplashCaption._({
    required this.id,
    required this._translations,
  });

  factory SplashCaption.fromJson(Map<String, dynamic> json) {
    final translations = <AppLocale, String>{};

    for (final locale in AppLocale.values) {
      final value = json[locale.name] as String?;
      if (value != null && value.isNotEmpty) {
        translations[locale] = value;
      }
    }

    return SplashCaption._(
      id: json['id'] as String,
      translations: translations,
    );
  }

  /// Returns the caption for [locale].
  ///
  /// Falls back to English if the requested locale has no translation,
  /// then to the first available translation, then to an empty string.
  String forLocale(AppLocale locale) =>
      _translations[locale] ??
      _translations[AppLocale.en] ??
      _translations.values.firstOrNull ??
      '';

  @override
  String toString() => 'SplashCaption(id: $id)';
}
