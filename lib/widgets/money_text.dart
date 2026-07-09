import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/privacy_notifier.dart';

/// Renders a monetary [amount] (already formatted, e.g. "RM 9,114.19"), masking
/// it to "••••" while [PrivacyNotifier.valuesHidden] is true. Watches the
/// notifier so it flips reactively everywhere it is used.
class MoneyText extends StatelessWidget {
  final String amount;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  static const String mask = '••••';

  @override
  Widget build(BuildContext context) {
    final hidden = context.watch<PrivacyNotifier>().valuesHidden;
    return Text(
      hidden ? mask : amount,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
