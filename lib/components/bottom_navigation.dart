import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';

/// Bottom navigation bar — used as [Scaffold.bottomNavigationBar].
///
/// Index mapping:
///   0 → Home (Gold Price)
///   1 → Dashboard
///   2 → + Add (centre FAB — handled by Scaffold, not this widget)
///   3 → Listing
///   4 → Settings
class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return BottomAppBar(
      color: appTheme.primary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 4,
      padding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              // Left: Home, Dashboard
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomNavItem(
                      icon: Icons.home_outlined,
                      label: l10n.navHome,
                      isActive: currentIndex == 0,
                      onTap: () => onTap(0),
                      appTheme: appTheme,
                      locale: l10n.locale,
                    ),
                    _BottomNavItem(
                      icon: Icons.dashboard_outlined,
                      label: l10n.navDashboard,
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1),
                      appTheme: appTheme,
                      locale: l10n.locale,
                    ),
                  ],
                ),
              ),
              // Gap for the centre FAB
              const SizedBox(width: 72),
              // Right: Listing, Settings
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomNavItem(
                      icon: Icons.shopping_bag_outlined,
                      label: l10n.navListing,
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3),
                      appTheme: appTheme,
                      locale: l10n.locale,
                    ),
                    _BottomNavItem(
                      icon: Icons.settings_outlined,
                      label: l10n.navSettings,
                      isActive: currentIndex == 4,
                      onTap: () => onTap(4),
                      appTheme: appTheme,
                      locale: l10n.locale,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final AppTheme appTheme;
  final AppLocale locale;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.appTheme,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final Color active = Colors.white;
    final Color inactive = Colors.white.withValues(alpha: 0.6);
    final Color iconColor = isActive ? active : inactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption(iconColor, locale: locale).copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
