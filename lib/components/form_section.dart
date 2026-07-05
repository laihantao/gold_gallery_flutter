import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_notifier.dart';

/// Small uppercase, letter-spaced label used above a [SectionCard]
/// (e.g. "BASIC INFO", "PRICING", "THEME").
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: appTheme.inkLight,
      ),
    );
  }
}

/// Card container for grouped form/settings content. Gives a consistent
/// surface colour, border, radius and shadow across the app so every screen
/// that groups related fields/actions looks the same.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: appTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appTheme.borderColor.withValues(alpha: 0.4)),
        boxShadow: [appTheme.cardShadow],
      ),
      child: child,
    );
  }
}

/// A [SectionLabel] followed by a [SectionCard], with the standard spacing
/// used throughout Add Product / Settings. Pass [tooltip] to show an info
/// icon next to the label.
class FormSection extends StatelessWidget {
  final String title;
  final Widget child;
  final String? tooltip;
  final EdgeInsetsGeometry cardPadding;

  const FormSection({
    super.key,
    required this.title,
    required this.child,
    this.tooltip,
    this.cardPadding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SectionLabel(title),
            if (tooltip != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: tooltip!,
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: true,
                showDuration: const Duration(seconds: 4),
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: appTheme.textBody.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SectionCard(padding: cardPadding, child: child),
      ],
    );
  }
}
