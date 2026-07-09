import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/update_checker.dart';
import '../theme/theme_notifier.dart';
import '../widgets/update_dialog.dart';
import '../components/bottom_navigation.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'jewellery_listing_page.dart';
import 'settings_page.dart';

/// Exposes tab switching to any descendant page widget without prop-drilling.
///
/// [filterType] / [filterOwnerId] let a caller (e.g. Dashboard's "By
/// Jewellery Type" / "By Owner" cards) jump to the Listing tab pre-filtered,
/// instead of pushing a standalone route that would lose the shell's bottom
/// nav bar.
class TabScope extends InheritedWidget {
  final void Function(int index, {String? filterType, String? filterOwnerId})
  switchTab;

  const TabScope({super.key, required this.switchTab, required super.child});

  static TabScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabScope>();

  @override
  bool updateShouldNotify(TabScope old) => switchTab != old.switchTab;
}

/// Persistent shell that owns the bottom nav bar and FAB.
///
/// The four main tabs live in a lazy [IndexedStack] and are kept alive across
/// switches. Rebuilding a tab from scratch on every switch (the old
/// [AnimatedSwitcher] approach) re-ran each page's data load and re-decoded
/// every base64 image, which showed as a blank-then-flash on landing.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  // Bottom-nav tab indices (2 is the centre FAB, not a tab).
  static const List<int> _tabIndices = [0, 1, 3, 4];

  int _index = 0;
  int _refreshNonce = 0;
  String? _pendingListingType;
  String? _pendingListingOwnerId;

  // Tabs visited at least once — lets the IndexedStack build a tab on first
  // visit, then keep it alive, instead of building all four upfront.
  final Set<int> _visited = {0};

  @override
  void initState() {
    super.initState();
    // Runs after the first frame so it never delays the splash/first paint;
    // silent by design (see UpdateChecker) so a broken manifest or offline
    // device can't surface as a startup crash.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateChecker.checkForUpdateOnStartup();
    if (info == null || !mounted) return;
    await UpdateDialog.show(context, info);
  }

  void _switchTab(int newIndex, {String? filterType, String? filterOwnerId}) {
    if (newIndex == _index && filterType == null && filterOwnerId == null) {
      return;
    }
    setState(() {
      _index = newIndex;
      _pendingListingType = filterType;
      _pendingListingOwnerId = filterOwnerId;
      _visited.add(newIndex);
    });
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
        // Key encodes the pending filter so a filter-driven navigation
        // (Dashboard → filtered Listing) rebuilds with the new filter, while
        // plain tab switches keep the same key and stay alive.
        return JewelleryListingPage(
          key: ValueKey(
            'listing_${_pendingListingType}_$_pendingListingOwnerId',
          ),
          initialType: _pendingListingType,
          initialOwnerId: _pendingListingOwnerId,
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
        body: IndexedStack(
          index: _tabIndices.indexOf(_index),
          children: [
            for (final i in _tabIndices)
              if (_visited.contains(i))
                _buildTab(i)
              else
                const SizedBox.shrink(),
          ],
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
