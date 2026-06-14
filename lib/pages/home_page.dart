import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';
import '../painters/bg_pattern_painter.dart';
import '../widgets/gold_price_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Scaffold(
      appBar: AppHeader(title: 'Gold Price Today', showBackButton: false),
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
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () =>
            GoRouter.of(context).push('/add-product', extra: {'mode': 'add'}),
        backgroundColor: appTheme.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 1:
        GoRouter.of(context).go('/dashboard');
      case 3:
        GoRouter.of(context).go('/listing');
      case 4:
        GoRouter.of(context).go('/settings');
    }
  }
}
