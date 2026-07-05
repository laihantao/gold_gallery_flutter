import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  /// Forces the gold/theme header background on or off, independent of
  /// [showBackButton]. By default, only root tab pages (no back button) get
  /// the coloured header; pass `true` here to give a pushed sub-page the same
  /// coloured header while still keeping its back arrow.
  final bool? colored;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
    this.colored,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final locale = context.l10n.locale;

    final bool colored = this.colored ?? !showBackButton;
    final Color bg = colored ? appTheme.headerBg : appTheme.surface;
    final Color fg = appTheme.inkDark;

    return AppBar(
      title: Text(title, style: AppTextStyles.appTitle(fg, locale: locale)),
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
