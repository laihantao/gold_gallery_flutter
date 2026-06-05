import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PurityBadge extends StatelessWidget {
  final String purity;

  const PurityBadge({super.key, required this.purity});

  @override
  Widget build(BuildContext context) {
    final appTheme = _getAppTheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: appTheme.accentSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        purity,
        style: TextStyle(
          color: appTheme.backgroundPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.04,
        ),
      ),
    );
  }

  AppTheme _getAppTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
    if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
    if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
    return AppTheme.gold;
  }
}

class PriceText extends StatelessWidget {
  final double? price;
  final String? currencySymbol;
  final TextStyle? style;

  const PriceText({super.key, 
    this.price,
    this.currencySymbol = 'RM',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final displayPrice = price ?? 0;
    final displaySymbol = currencySymbol ?? 'RM';

    return Text(
      '$displaySymbol $displayPrice',
      style: style ??
          TextStyle(
            color: goldPrice,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
    );
  }
}
