import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';

/// Aurum typography system.
///
///  * APP TITLE / DISPLAY  → Fredoka One (rounded chunky, cartoon feel)
///  * BODY / LABELS        → Nunito (soft rounded sans)
///  * HANDWRITTEN ACCENT   → Caveat (pencil handwriting, notebook annotation)
///  * PRICES / NUMBERS     → Space Mono (ledger/receipt typewriter)
///
/// For [AppLocale.zhCN], body/label styles switch to ZCOOL KuaiLe — a cute,
/// chunky typeface that covers the full CJK block with a pixel-art flavour.
/// Sizes are scaled down ~1pt to compensate for ZCOOL KuaiLe's larger ink area.
/// Price/decorative styles are intentionally unchanged (numbers are language-
/// agnostic; Caveat is only used for Latin theme labels).
class AppTextStyles {
  AppTextStyles._();

  // ── Display / titles (locale-aware) ─────────────────────────────────────────

  static TextStyle appTitle(Color c, {AppLocale locale = AppLocale.en}) =>
      locale == AppLocale.zhCN
          ? GoogleFonts.zcoolKuaiLe(
              fontSize: 22, fontWeight: FontWeight.w700, color: c)
          : GoogleFonts.fredoka(
              fontSize: 24, fontWeight: FontWeight.w700, color: c);

  static TextStyle display(Color c, {AppLocale locale = AppLocale.en}) =>
      locale == AppLocale.zhCN
          ? GoogleFonts.zcoolKuaiLe(
              fontSize: 26, fontWeight: FontWeight.w700, color: c)
          : GoogleFonts.fredoka(
              fontSize: 28, fontWeight: FontWeight.w700, color: c);

  static TextStyle headline(Color c, {AppLocale locale = AppLocale.en}) =>
      locale == AppLocale.zhCN
          ? GoogleFonts.zcoolKuaiLe(
              fontSize: 18, fontWeight: FontWeight.w700, color: c)
          : GoogleFonts.fredoka(
              fontSize: 20, fontWeight: FontWeight.w700, color: c);

  // ── Body / labels (locale-aware) ────────────────────────────────────────────

  static TextStyle title(Color c, {AppLocale locale = AppLocale.en}) =>
      locale == AppLocale.zhCN
          ? GoogleFonts.zcoolKuaiLe(
              fontSize: 15, fontWeight: FontWeight.w700, color: c)
          : GoogleFonts.nunito(
              fontSize: 16, fontWeight: FontWeight.w700, color: c);

  static TextStyle body(Color c, {AppLocale locale = AppLocale.en}) =>
      locale == AppLocale.zhCN
          ? GoogleFonts.zcoolKuaiLe(
              fontSize: 13, fontWeight: FontWeight.w400, color: c)
          : GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w400, color: c);

  static TextStyle bodyBold(Color c, {AppLocale locale = AppLocale.en}) =>
      locale == AppLocale.zhCN
          ? GoogleFonts.zcoolKuaiLe(
              fontSize: 13, fontWeight: FontWeight.w700, color: c)
          : GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w700, color: c);

  static TextStyle caption(Color c, {AppLocale locale = AppLocale.en}) =>
      locale == AppLocale.zhCN
          ? GoogleFonts.zcoolKuaiLe(fontSize: 10, color: c)
          : GoogleFonts.nunito(fontSize: 11, color: c);

  // ── Decorative / numbers (locale-independent) ────────────────────────────────
  // Caveat is only used for Latin labels; prices are always digits.

  static TextStyle handNote(Color c) =>
      GoogleFonts.caveat(fontSize: 15, color: c);

  static TextStyle price(Color c) =>
      GoogleFonts.spaceMono(fontSize: 20, fontWeight: FontWeight.bold, color: c);

  static TextStyle priceSmall(Color c) =>
      GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.bold, color: c);

  static TextStyle amount(Color c) =>
      GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.bold, color: c);
}
