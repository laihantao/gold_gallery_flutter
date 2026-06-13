import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import 'package:provider/provider.dart';

/// Standard icon sizes used across the app.
class OutlineIconSize {
  OutlineIconSize._();
  static const double appBar = 24;
  static const double bottomNav = 26;
  static const double cardAction = 20;
  static const double fab = 28;
  static const double small = 18;
}

/// Cute outline (stroke-only) icon following the Aurum icon rules.
///
/// Always feed it an `Icons.*_outlined` variant. Colour follows state:
///   * default  → theme.inkMid
///   * active   → theme.primary
///   * disabled → theme.border
class OutlineIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool active;
  final bool disabled;

  /// Explicit override; when null the colour is derived from state.
  final Color? color;

  const OutlineIcon(
    this.icon, {
    super.key,
    this.size = OutlineIconSize.cardAction,
    this.active = false,
    this.disabled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final AurumTheme theme = context.watch<ThemeNotifier>().currentTheme;
    Color resolved;
    if (color != null) {
      resolved = color!;
    } else if (disabled) {
      resolved = theme.border;
    } else if (active) {
      resolved = theme.primary;
    } else {
      resolved = theme.inkMid;
    }
    return Icon(icon, size: size, color: resolved);
  }
}
