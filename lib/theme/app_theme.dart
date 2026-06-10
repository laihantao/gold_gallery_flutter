import 'package:flutter/material.dart';

// Gold Honey #B8860B constant across all themes
const Color goldPrice = Color(0xFFB8860B);

// ==================== GOLD THEME ====================
class GoldTheme {
  static const Color backgroundPrimary = Color(0xFF0D0B07); // Obsidian
  static const Color backgroundSurface = Color(0xFF2E2A1F); // Card BG
  static const Color backgroundSubtle = Color(0xFF242019); // Dark Surface
  static const Color borderColor = Color(0xFF8B6914); // Antique Gold
  static const Color accentPrimary = Color(0xFFC9961E); // Gold Mid
  static const Color accentSecondary = Color(0xFFE8B84B); // Bright Gold
  static const Color textHeading = Color(0xFFF5D07A); // Pale Gold
  static const Color textBody = Color(0xFFA89B78); // Warm Muted
  static const Color priceHighlight = Color(0xFFFFE066); // Vivid lemon-gold

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: accentPrimary,
        onPrimary: backgroundPrimary,
        secondary: accentSecondary,
        onSecondary: backgroundPrimary,
        surface: backgroundSurface,
        onSurface: textHeading,
        error: Colors.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSurface,
        foregroundColor: textHeading,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: backgroundSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 1),
        ),
      ),
    );
  }
}

// ==================== BLUSH THEME ====================
class BlushTheme {
  static const Color backgroundPrimary = Color(0xFFFFFBFC); // Petal White
  static const Color backgroundSurface = Color(0xFFFDF0F3); // Blush Mist
  static const Color backgroundSubtle = Color(0xFFFAE3EA); // Rose Petal
  static const Color borderColor = Color(0xFFF2C4D0); // Soft Carnation
  static const Color accentPrimary = Color(0xFFE896B0); // Dusky Rose
  static const Color accentSecondary = Color(0xFFE896B0); // Dusky Rose
  static const Color textHeading = Color(0xFF7A3550); // Deep Rose
  static const Color textBody = Color(0xFFC47A92); // Warm Pink Muted
  static const Color priceHighlight = Color(0xFF9E1B4D); // Vivid rose on light surfaces

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: accentPrimary,
        onPrimary: Colors.white,
        secondary: accentSecondary,
        onSecondary: Colors.white,
        surface: backgroundSurface,
        onSurface: textHeading,
        error: Colors.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSurface,
        foregroundColor: textHeading,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: backgroundSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 1),
        ),
      ),
    );
  }
}

// ==================== SKY (Powder Blue) THEME ====================
class SkyTheme {
  static const Color backgroundPrimary = Color(0xFFF8FBFF); // Porcelain
  static const Color backgroundSurface = Color(0xFFEFF5FC); // Sky Mist
  static const Color backgroundSubtle = Color(0xFFD8EBFA); // Powder Blue
  static const Color borderColor = Color(0xFFBDD5EC); // Serenity
  static const Color accentPrimary = Color(0xFF5A8FB5); // Calm Mid Blue
  static const Color accentSecondary = Color(0xFF8ABCDF); // Calm Sky
  static const Color textHeading = Color(0xFF1E4F7A); // Deep Navy
  static const Color textBody = Color(0xFF5A8FB5); // Steel Blue Muted
  static const Color priceHighlight = Color(0xFF0D47A1); // Vivid blue on light surfaces

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: accentPrimary,
        onPrimary: Colors.white,
        secondary: accentSecondary,
        onSecondary: Colors.white,
        surface: backgroundSurface,
        onSurface: textHeading,
        error: Colors.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSurface,
        foregroundColor: textHeading,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: backgroundSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 1),
        ),
      ),
    );
  }
}

enum AppTheme {
  gold('gold', 'Gold'),
  blush('blush', 'Blush'),
  sky('sky', 'Sky');

  final String id;
  final String label;

  const AppTheme(this.id, this.label);

  ThemeData toThemeData() {
    return switch (this) {
      AppTheme.gold => GoldTheme.buildTheme(),
      AppTheme.blush => BlushTheme.buildTheme(),
      AppTheme.sky => SkyTheme.buildTheme(),
    };
  }

  Color get backgroundPrimary {
    return switch (this) {
      AppTheme.gold => GoldTheme.backgroundPrimary,
      AppTheme.blush => BlushTheme.backgroundPrimary,
      AppTheme.sky => SkyTheme.backgroundPrimary,
    };
  }

  Color get backgroundSurface {
    return switch (this) {
      AppTheme.gold => GoldTheme.backgroundSurface,
      AppTheme.blush => BlushTheme.backgroundSurface,
      AppTheme.sky => SkyTheme.backgroundSurface,
    };
  }

  Color get backgroundSubtle {
    return switch (this) {
      AppTheme.gold => GoldTheme.backgroundSubtle,
      AppTheme.blush => BlushTheme.backgroundSubtle,
      AppTheme.sky => SkyTheme.backgroundSubtle,
    };
  }

  Color get borderColor {
    return switch (this) {
      AppTheme.gold => GoldTheme.borderColor,
      AppTheme.blush => BlushTheme.borderColor,
      AppTheme.sky => SkyTheme.borderColor,
    };
  }

  Color get accentPrimary {
    return switch (this) {
      AppTheme.gold => GoldTheme.accentPrimary,
      AppTheme.blush => BlushTheme.accentPrimary,
      AppTheme.sky => SkyTheme.accentPrimary,
    };
  }

  Color get accentSecondary {
    return switch (this) {
      AppTheme.gold => GoldTheme.accentSecondary,
      AppTheme.blush => BlushTheme.accentSecondary,
      AppTheme.sky => SkyTheme.accentSecondary,
    };
  }

  Color get textHeading {
    return switch (this) {
      AppTheme.gold => GoldTheme.textHeading,
      AppTheme.blush => BlushTheme.textHeading,
      AppTheme.sky => SkyTheme.textHeading,
    };
  }

  Color get textBody {
    return switch (this) {
      AppTheme.gold => GoldTheme.textBody,
      AppTheme.blush => BlushTheme.textBody,
      AppTheme.sky => SkyTheme.textBody,
    };
  }

  Color get priceHighlight {
    return switch (this) {
      AppTheme.gold => GoldTheme.priceHighlight,
      AppTheme.blush => BlushTheme.priceHighlight,
      AppTheme.sky => SkyTheme.priceHighlight,
    };
  }
}
