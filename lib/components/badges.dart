import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';

/// Small pill tag showing gold purity / karat.
class PurityBadge extends StatelessWidget {
  final String purity;

  const PurityBadge({super.key, required this.purity});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: appTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appTheme.primary, width: 1),
      ),
      child: Text(purity, style: AppTextStyles.caption(appTheme.inkDark)),
    );
  }
}

/// Monospace ledger-style price text.
class PriceText extends StatelessWidget {
  final double? price;
  final String? currencySymbol;
  final TextStyle? style;

  const PriceText({
    super.key,
    this.price,
    this.currencySymbol = 'RM',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final displayPrice = price ?? 0;
    final displaySymbol = currencySymbol ?? 'RM';

    return Text(
      '$displaySymbol $displayPrice',
      style: style ?? AppTextStyles.price(appTheme.primaryDark),
    );
  }
}
