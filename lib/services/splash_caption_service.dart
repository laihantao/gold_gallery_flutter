import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/splash_caption.dart';

/// Loads [SplashCaption] entries from the bundled JSON asset and vends one
/// random caption per app launch.
///
/// ## Lifecycle
///
/// Call [initialize] **once** in `main()` before `runApp()`, alongside the
/// other app-init steps.  After that, [pickRandom] is synchronous and safe
/// to call from any widget or service — no BuildContext needed.
///
/// ## Adding captions
///
/// Edit `assets/data/splash_captions.json`.  No Dart code changes required.
///
/// ## Adding a locale
///
/// Add the locale to [AppLocale] (in `app_localizations.dart`) and add the
/// matching key to every JSON object.  [SplashCaption.fromJson] reads all
/// [AppLocale.values] automatically.
class SplashCaptionService {
  SplashCaptionService._(); // static-only — not instantiable

  static const String _assetPath = 'assets/data/splash_captions.json';

  static List<SplashCaption> _captions = const [];
  static final Random _rng = Random();

  // ── Initialization ────────────────────────────────────────────────────────

  /// Loads caption data from the asset bundle.
  ///
  /// Idempotent — subsequent calls are no-ops.
  static Future<void> initialize() async {
    if (_captions.isNotEmpty) return;

    final raw = await rootBundle.loadString(_assetPath);
    final list = json.decode(raw) as List<dynamic>;

    _captions = List.unmodifiable(
      list.map((e) => SplashCaption.fromJson(e as Map<String, dynamic>)),
    );

    assert(
      _captions.isNotEmpty,
      'splash_captions.json must contain at least one entry.',
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns a randomly chosen [SplashCaption].
  ///
  /// Throws [StateError] if [initialize] has not been awaited first.
  static SplashCaption pickRandom() {
    if (_captions.isEmpty) {
      throw StateError(
        'SplashCaptionService.initialize() must complete before pickRandom(). '
        'Ensure it is awaited in main() before runApp().',
      );
    }
    return _captions[_rng.nextInt(_captions.length)];
  }

  /// Read-only view of every loaded caption (useful for tests and previews).
  static List<SplashCaption> get all => _captions;
}
