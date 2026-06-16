import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../painters/bg_pattern_painter.dart';
import '../widgets/gold_price_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(title: l10n.homeTitle, showBackButton: false),
      body: PatternedBackground(
        patternColor: appTheme.patternColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              GoldPriceSection(),
            ],
          ),
        ),
      ),
    );
  }
}
