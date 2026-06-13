import 'package:flutter/material.dart';

/// Aurum colour palettes.
///
/// Three "coloured notebooks":
///   * [ParchmentColors] — golden honey treasure journal (DEFAULT)
///   * [SkyColors]       — soft blue watercolour field notes
///   * [BlushColors]     — rose pink keepsake diary
///
/// This is the ONLY place raw `Color(0xFF...)` literals should live.

// ── Theme A: Parchment (DEFAULT) ── 浅黄/奶油暖色 ──
class ParchmentColors {
  // Backgrounds
  static const primaryBg = Color(0xFFFDF8EE); // warm cream
  static const surface = Color(0xFFFFFFFF); // card white
  static const headerBg = Color(0xFFCBA840); // muted honey gold header
  static const patternColor = Color(0xFFC9A038); // watermark pattern color

  // Accent
  static const primary = Color(0xFFCBA840); // warm honey gold (softer)
  static const primaryDark = Color(0xFFA07B20); // deep amber border/pressed
  static const primaryLight = Color(0xFFF5E8B0); // chip background / tag
  static const accent = Color(0xFFFF8C7A); // coral pink (+ new button)

  // Text
  static const inkDark = Color(0xFF2C2116); // near-black warm brown
  static const inkMid = Color(0xFF6B5744); // body text
  static const inkLight = Color(0xFFA89070); // caption / metadata

  // UI
  static const border = Color(0xFFE0D0B0); // card border
  static const divider = Color(0xFFEEE4D0); // list divider
  static const shadow = Color(0xFFBD9838); // warm shadow

  // Status
  static const success = Color(0xFF7BAE6E);
  static const warning = Color(0xFFCBA840);
  static const error = Color(0xFFFF6B6B);
  static const errorLight = Color(0xFFFFEEEE); // error row bg tint
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
