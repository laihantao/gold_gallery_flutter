import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Warm gold accent kept for legacy price text. Sourced from the palette.
const Color goldPrice = ParchmentColors.primaryDark;

/// Internal bundle of every colour role for one theme.
class _Palette {
  final Color primaryBg, surface, headerBg, patternColor;
  final Color primary, primaryDark, primaryLight, accent;
  final Color inkDark, inkMid, inkLight;
  final Color border, divider, shadow;
  final Color success, warning, error, errorLight;

  const _Palette({
    required this.primaryBg,
    required this.surface,
    required this.headerBg,
    required this.patternColor,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.inkDark,
    required this.inkMid,
    required this.inkLight,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.error,
    required this.errorLight,
  });
}

const _parchment = _Palette(
  primaryBg: ParchmentColors.primaryBg,
  surface: ParchmentColors.surface,
  headerBg: ParchmentColors.headerBg,
  patternColor: ParchmentColors.patternColor,
  primary: ParchmentColors.primary,
  primaryDark: ParchmentColors.primaryDark,
  primaryLight: ParchmentColors.primaryLight,
  accent: ParchmentColors.accent,
  inkDark: ParchmentColors.inkDark,
  inkMid: ParchmentColors.inkMid,
  inkLight: ParchmentColors.inkLight,
  border: ParchmentColors.border,
  divider: ParchmentColors.divider,
  shadow: ParchmentColors.shadow,
  success: ParchmentColors.success,
  warning: ParchmentColors.warning,
  error: ParchmentColors.error,
  errorLight: ParchmentColors.errorLight,
);

const _sky = _Palette(
  primaryBg: SkyColors.primaryBg,
  surface: SkyColors.surface,
  headerBg: SkyColors.headerBg,
  patternColor: SkyColors.patternColor,
  primary: SkyColors.primary,
  primaryDark: SkyColors.primaryDark,
  primaryLight: SkyColors.primaryLight,
  accent: SkyColors.accent,
  inkDark: SkyColors.inkDark,
  inkMid: SkyColors.inkMid,
  inkLight: SkyColors.inkLight,
  border: SkyColors.border,
  divider: SkyColors.divider,
  shadow: SkyColors.shadow,
  success: SkyColors.success,
  warning: SkyColors.warning,
  error: SkyColors.error,
  errorLight: SkyColors.errorLight,
);

const _blush = _Palette(
  primaryBg: BlushColors.primaryBg,
  surface: BlushColors.surface,
  headerBg: BlushColors.headerBg,
  patternColor: BlushColors.patternColor,
  primary: BlushColors.primary,
  primaryDark: BlushColors.primaryDark,
  primaryLight: BlushColors.primaryLight,
  accent: BlushColors.accent,
  inkDark: BlushColors.inkDark,
  inkMid: BlushColors.inkMid,
  inkLight: BlushColors.inkLight,
  border: BlushColors.border,
  divider: BlushColors.divider,
  shadow: BlushColors.shadow,
  success: BlushColors.success,
  warning: BlushColors.warning,
  error: BlushColors.error,
  errorLight: BlushColors.errorLight,
);

/// The three Aurum themes — each a "coloured notebook".
///
/// Parchment is the default (golden honey treasure journal).
enum AurumTheme {
  parchment('parchment', 'Parchment'),
  sky('sky', 'Sky'),
  blush('blush', 'Blush');

  final String id;
  final String label;
  const AurumTheme(this.id, this.label);

  /// Locale-aware theme name for display in the settings sheet.
  String localizedLabel(AppLocale locale) => switch (this) {
        AurumTheme.parchment => switch (locale) {
          AppLocale.en => 'Parchment',
          AppLocale.zhCN => '羊皮纸',
          AppLocale.ms => 'Perkamen',
        },
        AurumTheme.sky => switch (locale) {
          AppLocale.en => 'Sky',
          AppLocale.zhCN => '天蓝',
          AppLocale.ms => 'Langit',
        },
        AurumTheme.blush => switch (locale) {
          AppLocale.en => 'Blush',
          AppLocale.zhCN => '玫瑰',
          AppLocale.ms => 'Merona',
        },
      };

  _Palette get _p => switch (this) {
        AurumTheme.parchment => _parchment,
        AurumTheme.sky => _sky,
        AurumTheme.blush => _blush,
      };

  // ── New palette roles ──
  Color get primaryBg => _p.primaryBg;
  Color get surface => _p.surface;
  Color get headerBg => _p.headerBg;
  Color get patternColor => _p.patternColor;
  Color get primary => _p.primary;
  Color get primaryDark => _p.primaryDark;
  Color get primaryLight => _p.primaryLight;
  Color get accent => _p.accent;
  Color get inkDark => _p.inkDark;
  Color get inkMid => _p.inkMid;
  Color get inkLight => _p.inkLight;
  Color get border => _p.border;
  Color get divider => _p.divider;
  Color get shadow => _p.shadow;
  Color get success => _p.success;
  Color get warning => _p.warning;
  Color get error => _p.error;
  Color get errorLight => _p.errorLight;

  // ── Legacy aliases (so existing screens keep compiling) ──
  Color get backgroundPrimary => _p.primaryBg;
  Color get backgroundSurface => _p.surface;
  Color get backgroundSubtle => _p.primaryLight;
  Color get borderColor => _p.border;
  Color get accentPrimary => _p.primary;
  Color get accentSecondary => _p.primaryDark;
  Color get textHeading => _p.inkDark;
  Color get textBody => _p.inkMid;
  Color get priceHighlight => _p.primaryDark;

  /// Standard card shadow used across the app.
  BoxShadow get cardShadow => BoxShadow(
        color: _p.shadow.withValues(alpha: 0.15),
        blurRadius: 8,
        offset: const Offset(2, 4),
      );

  ThemeData toThemeData() {
    final p = _p;

    final baseText = GoogleFonts.nunitoTextTheme().apply(
      bodyColor: p.inkMid,
      displayColor: p.inkDark,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: p.primaryBg,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: p.primary,
        onPrimary: Colors.white,
        secondary: p.accent,
        onSecondary: Colors.white,
        surface: p.surface,
        onSurface: p.inkDark,
        error: p.error,
        onError: Colors.white,
      ),
      textTheme: baseText,
      dividerColor: p.divider,
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 0.8,
        space: 1,
      ),

      // ── AppBar (colored header) ──
      appBarTheme: AppBarTheme(
        backgroundColor: p.headerBg,
        foregroundColor: p.inkDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.inkDark, size: 24),
        titleTextStyle: AppTextStyles.appTitle(p.inkDark),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border, width: 1),
        ),
      ),

      // ── Primary (pill) button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(p.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          overlayColor:
              WidgetStatePropertyAll(p.primaryDark.withValues(alpha: 0.2)),
          elevation: const WidgetStatePropertyAll(2),
          shadowColor:
              WidgetStatePropertyAll(p.shadow.withValues(alpha: 0.25)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          ),
          textStyle:
              WidgetStatePropertyAll(AppTextStyles.bodyBold(Colors.white)),
          shape: WidgetStatePropertyAll(
            StadiumBorder(side: BorderSide(color: p.primaryDark, width: 1.5)),
          ),
        ),
      ),

      // ── Secondary (outlined) button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStatePropertyAll(p.primary),
          side:
              WidgetStatePropertyAll(BorderSide(color: p.primary, width: 1.5)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          ),
          textStyle: WidgetStatePropertyAll(AppTextStyles.bodyBold(p.primary)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),

      // ── Text button ──
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(p.inkMid),
          textStyle: WidgetStatePropertyAll(AppTextStyles.body(p.inkMid)),
        ),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(side: BorderSide(color: p.primaryDark, width: 1.5)),
      ),

      // ── Input fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: AppTextStyles.body(p.inkLight),
        labelStyle: AppTextStyles.body(p.inkMid),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.error, width: 1.2),
        ),
      ),

      // ── Chips / filter tags ──
      chipTheme: ChipThemeData(
        backgroundColor: p.primaryLight,
        selectedColor: p.primary,
        side: BorderSide(color: p.primary, width: 1),
        shape: const StadiumBorder(),
        labelStyle: AppTextStyles.caption(p.inkDark),
        secondaryLabelStyle: AppTextStyles.caption(Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.inkDark,
        contentTextStyle: AppTextStyles.body(Colors.white),
        actionTextColor: p.primary,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTextStyles.headline(p.inkDark),
        contentTextStyle: AppTextStyles.body(p.inkMid),
      ),

      // ── Bottom sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      iconTheme: IconThemeData(color: p.inkMid),
    );
  }
}

/// Backwards-compatible alias. The canonical enum is [AurumTheme]; existing
/// screens still refer to the type as `AppTheme`.
typedef AppTheme = AurumTheme;
