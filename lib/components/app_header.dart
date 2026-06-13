import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    // Main screens (no back button) use the warm coloured header;
    // detail screens use a clean white surface header.
    final bool colored = !showBackButton;
    final Color bg = colored ? appTheme.headerBg : appTheme.surface;
    final Color fg = appTheme.inkDark;

    return AppBar(
      title: Text(title, style: AppTextStyles.appTitle(fg)),
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_outlined, color: fg, size: 24),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
