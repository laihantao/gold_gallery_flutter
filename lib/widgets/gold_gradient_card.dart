import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The "gold gradient" used on premium value cards (Portfolio Overview,
/// Market Value): a 4-stop diagonal gradient from the theme's `primaryDark`
/// through `primary`, a lightened highlight, and back to a slightly
/// transparent `primaryDark`.
LinearGradient goldGradient(AurumTheme appTheme) {
  final highlight = Color.lerp(appTheme.primary, Colors.white, 0.20)!;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      appTheme.primaryDark,
      appTheme.primary,
      highlight,
      appTheme.primaryDark.withValues(alpha: 0.90),
    ],
    stops: const [0.0, 0.38, 0.62, 1.0],
  );
}

/// Diagonal white shimmer overlay paired with [goldGradient]. Fills its
/// parent — wrap in a `Positioned.fill` inside a `Stack`.
class GoldGradientShimmer extends StatelessWidget {
  const GoldGradientShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: 0.13),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
