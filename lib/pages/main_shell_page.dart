import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/theme_notifier.dart';
import '../components/bottom_navigation.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'jewellery_listing_page.dart';
import 'settings_page.dart';

/// Exposes tab switching to any descendant page widget without prop-drilling.
class TabScope extends InheritedWidget {
  final void Function(int index) switchTab;

  const TabScope({
    super.key,
    required this.switchTab,
    required super.child,
  });

  static TabScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabScope>();

  @override
  bool updateShouldNotify(TabScope old) => switchTab != old.switchTab;
}

/// Persistent shell that owns the bottom nav bar and FAB.
/// The four main tabs animate inside via [AnimatedSwitcher].
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _index = 0;

  // Incremented whenever the FAB add-product push returns, so tab pages
  // that need to refresh (Dashboard, Listing) can react via didUpdateWidget.
  int _refreshNonce = 0;

  void _switchTab(int newIndex) {
    if (newIndex == _index) return;
    setState(() => _index = newIndex);
  }

  Future<void> _onFabPressed() async {
    await GoRouter.of(context).push('/add-product', extra: {'mode': 'add'});
    if (!mounted) return;
    setState(() => _refreshNonce++);
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const HomePage(key: ValueKey('home'));
      case 1:
        return DashboardPage(
          key: const ValueKey('dashboard'),
          refreshNonce: _refreshNonce,
        );
      case 3:
        return JewelleryListingPage(
          key: const ValueKey('listing'),
          refreshNonce: _refreshNonce,
        );
      case 4:
        return const SettingsPage(key: ValueKey('settings'));
      default:
        return const HomePage(key: ValueKey('home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return TabScope(
      switchTab: _switchTab,
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          ),
          child: _buildTab(_index),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'main_shell_fab',
          onPressed: _onFabPressed,
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
          currentIndex: _index,
          onTap: _switchTab,
        ),
      ),
    );
  }
}
