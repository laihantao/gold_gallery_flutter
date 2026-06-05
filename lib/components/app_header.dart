import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const AppHeader({super.key, 
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = _getAppTheme(context);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.backgroundSurface,
        border: Border(
          bottom: BorderSide(
            color: appTheme.borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: appTheme.textHeading,
            fontWeight: FontWeight.w500,
            fontSize: 18,
            letterSpacing: 0.04,
          ),
        ),
        backgroundColor: appTheme.backgroundSurface,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: appTheme.textHeading),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              )
            : null,
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);

  AppTheme _getAppTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
    if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
    if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
    return AppTheme.gold;
  }
}
