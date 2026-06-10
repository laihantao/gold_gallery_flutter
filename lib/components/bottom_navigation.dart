import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({super.key, 
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: appTheme.backgroundSurface,
        border: Border(
          top: BorderSide(
            color: appTheme.borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomNavItem(
              icon: Icons.home,
              label: 'Home',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
              appTheme: appTheme,
            ),
            _BottomNavItem(
              icon: Icons.shopping_bag,
              label: 'Listing',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
              appTheme: appTheme,
            ),
            _BottomNavItem(
              icon: Icons.add,
              label: 'Add',
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
              isCenter: true,
              appTheme: appTheme,
            ),
            _BottomNavItem(
              icon: Icons.person,
              label: 'Users',
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
              appTheme: appTheme,
            ),
            _BottomNavItem(
              icon: Icons.settings,
              label: 'Settings',
              isActive: currentIndex == 4,
              onTap: () => onTap(4),
              appTheme: appTheme,
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: isCenter
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: appTheme.accentPrimary,
                  width: 2,
                ),
              )
            : BoxDecoration(
                border: Border.all(
                  color: isActive
                      ? appTheme.accentPrimary
                      : appTheme.borderColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? appTheme.accentPrimary : appTheme.textBody,
              size: isCenter ? 28 : 24,
            ),
            if (!isCenter) ...[
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? appTheme.accentPrimary : appTheme.textBody,
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
