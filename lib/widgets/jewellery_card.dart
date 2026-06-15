import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';
import 'sketch_border.dart';

class JewelleryCard extends StatelessWidget {
  final JewelleryDisplayItem item;
  final VoidCallback? onTap;

  const JewelleryCard({
    super.key,
    required this.item,
    this.onTap,
  });

  double _imageSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scaled = width >= 600 ? 80.0 : 72.0;
    return scaled.clamp(60.0, 80.0);
  }

  String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;
    final jewellery = item.jewellery;
    final imageSize = _imageSize(context);

    final typeName = jewellery.jewelleryTypeId != null
        ? _nonBlank(HiveService.getJewelleryType(jewellery.jewelleryTypeId!)
            ?.localizedName(l10n.locale))
        : null;
    final dateText = DateFormat('dd/MM/yyyy').format(jewellery.date);
    final totalPrice = jewellery.totalPrice ?? 0.0;
    final priceText =
        '${item.currencySymbol} ${totalPrice.toStringAsFixed(2)}';
    final purity = _nonBlank(jewellery.goldPurity) ?? '—';
    final firstPhoto = jewellery.jewelleryPhoto.isNotEmpty
        ? jewellery.jewelleryPhoto.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [appTheme.cardShadow],
          ),
          child: SketchBorder(
            radius: 16,
            color: appTheme.border,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: appTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: _JewelleryThumbnail(
                        base64Photo: firstPhoto,
                        appTheme: appTheme,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nonBlank(jewellery.name) ?? l10n.untitled,
                          style: AppTextStyles.title(appTheme.inkDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _MetaGrid(
                          appTheme: appTheme,
                          entries: [
                            _MetaEntry(l10n.rowBrand,
                                _nonBlank(jewellery.brand) ?? '—'),
                            _MetaEntry(l10n.rowOwner, item.ownerName),
                            _MetaEntry(l10n.labelType, typeName ?? '—'),
                            _MetaEntry(l10n.labelDate, dateText),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _PurityBadge(
                              purity: purity,
                              appTheme: appTheme,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: appTheme.primary,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: appTheme.primaryDark,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                priceText,
                                style: AppTextStyles.priceSmall(Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JewelleryThumbnail extends StatelessWidget {
  final String? base64Photo;
  final AppTheme appTheme;

  const _JewelleryThumbnail({
    required this.base64Photo,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (base64Photo == null || base64Photo!.isEmpty) {
      return ColoredBox(
        color: appTheme.backgroundSubtle,
        child: Center(
          child: Icon(
            Icons.diamond_outlined,
            color: appTheme.accentSecondary,
            size: 28,
          ),
        ),
      );
    }

    try {
      final bytes = base64Decode(base64Photo!);
      return Image.memory(
        bytes,
        key: ValueKey('thumb_$base64Photo'),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return ColoredBox(
            color: appTheme.backgroundSubtle,
            child: Center(
              child: Icon(
                Icons.diamond_outlined,
                color: appTheme.accentSecondary,
                size: 28,
              ),
            ),
          );
        },
      );
    } catch (_) {
      return ColoredBox(
        color: appTheme.backgroundSubtle,
        child: Center(
          child: Icon(
            Icons.diamond_outlined,
            color: appTheme.accentSecondary,
            size: 28,
          ),
        ),
      );
    }
  }
}

class _MetaEntry {
  final String label;
  final String value;

  const _MetaEntry(this.label, this.value);
}

class _MetaGrid extends StatelessWidget {
  final AppTheme appTheme;
  final List<_MetaEntry> entries;

  const _MetaGrid({
    required this.appTheme,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: entries
              .map(
                (entry) => SizedBox(
                  width: itemWidth,
                  child: _MetaCell(
                    label: entry.label,
                    value: entry.value,
                    appTheme: appTheme,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetaCell extends StatelessWidget {
  final String label;
  final String value;
  final AppTheme appTheme;

  const _MetaCell({
    required this.label,
    required this.value,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: appTheme.textBody.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: appTheme.textHeading.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurityBadge extends StatelessWidget {
  final String purity;
  final AppTheme appTheme;

  const _PurityBadge({
    required this.purity,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: appTheme.accentPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: appTheme.accentPrimary.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        purity,
        style: TextStyle(
          color: appTheme.accentSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
