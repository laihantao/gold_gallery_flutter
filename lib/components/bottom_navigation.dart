import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';

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

    return Container(
      color: appTheme.primary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BottomNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                appTheme: appTheme,
              ),
              _BottomNavItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Listing',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                appTheme: appTheme,
              ),
              _BottomNavItem(
                icon: Icons.add_circle_outline,
                label: 'Add',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                isCenter: true,
                appTheme: appTheme,
              ),
              _BottomNavItem(
                icon: Icons.person_outline,
                label: 'Users',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                appTheme: appTheme,
              ),
              _BottomNavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
                appTheme: appTheme,
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
  final bool isCenter;
  final AppTheme appTheme;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isCenter = false,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    final Color active = Colors.white;
    final Color inactive = Colors.white.withValues(alpha: 0.6);
    final Color iconColor = isActive ? active : inactive;

    if (isCenter) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: appTheme.accent,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption(iconColor).copyWith(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
