import 'package:flutter/material.dart';

/// Aurum colour palettes.
///
/// Three "coloured notebooks":
///   * [ParchmentColors] — warm cream / champagne-gold (DEFAULT)
///   * [SkyColors]       — soft blue watercolour field notes
///   * [BlushColors]     — rose pink keepsake diary
///
/// This is the ONLY place raw `Color(0xFF...)` literals should live.

// ── Theme A: Parchment (DEFAULT) ── 暖米/奶白 · anchored on #F5F0E0 ──
class ParchmentColors {
  // Backgrounds
  static const primaryBg = Color(0xFFF5F0E0); // warm cream beige (#F5F0E0)
  static const surface = Color(0xFFFEFCF8); // barely-warm white (cards pop)
  static const headerBg = Color(0xFFD4A843); // warm golden header/nav
  static const patternColor = Color(0xFFC8A860); // subtle warm watermark

  // Accent
  static const primary = Color(0xFFBF9E52); // champagne gold (desaturated)
  static const primaryDark = Color(0xFF8C6A28); // deep amber-brown
  static const primaryLight = Color(0xFFEAE2C8); // light beige chip bg
  static const accent = Color(0xFF3D2B1F); // deep espresso (FAB / + button)

  // Text
  static const inkDark = Color(0xFF28200E); // near-black warm brown
  static const inkMid = Color(0xFF5C4A38); // body text
  static const inkLight = Color(0xFF9A8468); // caption / metadata

  // UI
  static const border = Color(0xFFD8CEBC); // warm beige border
  static const divider = Color(0xFFE8E2D0); // list divider
  static const shadow = Color(0xFFA88A40); // warm amber shadow

  // Status
  static const success = Color(0xFF7BAE6E);
  static const warning = Color(0xFFBF9E52);
  static const error = Color(0xFFFF6B6B);
  static const errorLight = Color(0xFFFFEEEE);
}

// ── Theme B: Sky ── 浅蓝/粉蓝水彩 ──
class SkyColors {
  static const primaryBg = Color(0xFFF0F6FF);
  static const surface = Color(0xFFFFFFFF);
  static const headerBg = Color(0xFF7EC8E3);
  static const patternColor = Color(0xFFB8DCF0);

  static const primary = Color(0xFF7EC8E3);
  static const primaryDark = Color(0xFF4DA8C8);
  static const primaryLight = Color(0xFFCCEAF5);
  static const accent = Color(0xFFA0D4B8); // mint green accent

  static const inkDark = Color(0xFF1A2E3A);
  static const inkMid = Color(0xFF4A6880);
  static const inkLight = Color(0xFF8AAABB);

  static const border = Color(0xFFBDD8E8);
  static const divider = Color(0xFFD8EDF5);
  static const shadow = Color(0xFF8ABCD4);

  static const success = Color(0xFF7BAE6E);
  static const warning = Color(0xFFF5C842);
  static const error = Color(0xFFFF6B6B);
  static const errorLight = Color(0xFFFFEEEE);
}

// ── Theme C: Blush ── 浅粉/玫瑰米 ──
class BlushColors {
  static const primaryBg = Color(0xFFFFF0F4);
  static const surface = Color(0xFFFFFFFF);
  static const headerBg = Color(0xFFFFAABB);
  static const patternColor = Color(0xFFFFCCD8);

  static const primary = Color(0xFFFFAABB);
  static const primaryDark = Color(0xFFE0708A);
  static const primaryLight = Color(0xFFFFDDE5);
  static const accent = Color(0xFFFFCC88); // peach accent

  static const inkDark = Color(0xFF2C1A20);
  static const inkMid = Color(0xFF6B4050);
  static const inkLight = Color(0xFFA88090);

  static const border = Color(0xFFEEC8D0);
  static const divider = Color(0xFFF5DDE2);
  static const shadow = Color(0xFFE8A0B0);

  static const success = Color(0xFF7BAE6E);
  static const warning = Color(0xFFF5C842);
  static const error = Color(0xFFFF6B6B);
  static const errorLight = Color(0xFFFFEEEE);
}
