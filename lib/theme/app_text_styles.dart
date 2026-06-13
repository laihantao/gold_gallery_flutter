import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aurum typography system.
///
///  * APP TITLE / DISPLAY  → Fredoka One (rounded chunky, cartoon feel)
///  * BODY / LABELS        → Nunito (soft rounded sans)
///  * HANDWRITTEN ACCENT   → Caveat (pencil handwriting, notebook annotation)
///  * PRICES / NUMBERS     → Space Mono (ledger/receipt typewriter)
class AppTextStyles {
  AppTextStyles._();

  // Display / titles — Fredoka (bold weight gives Fredoka One feel)
  static TextStyle appTitle(Color c) =>
      GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.w700, color: c);

  static TextStyle display(Color c) =>
      GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w700, color: c);

  static TextStyle headline(Color c) =>
      GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w700, color: c);

  // Body / labels — Nunito
  static TextStyle title(Color c) =>
      GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: c);

  static TextStyle body(Color c) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: c);

  static TextStyle bodyBold(Color c) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: c);

  static TextStyle caption(Color c) => GoogleFonts.nunito(fontSize: 11, color: c);

  // Handwritten accent — Caveat
  static TextStyle handNote(Color c) => GoogleFonts.caveat(fontSize: 15, color: c);

  // Prices / amounts / numbers — Space Mono
  static TextStyle price(Color c) =>
      GoogleFonts.spaceMono(fontSize: 20, fontWeight: FontWeight.bold, color: c);

  static TextStyle priceSmall(Color c) =>
      GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.bold, color: c);

  // For negative/positive amounts (ref image: red)
  static TextStyle amount(Color c) =>
      GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.bold, color: c);
}
