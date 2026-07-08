import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../providers/gold_price_notifier.dart';
import '../services/hive_service.dart';
import '../services/market_value_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';
import 'sketch_border.dart';

class JewelleryCard extends StatelessWidget {
  final JewelleryDisplayItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const JewelleryCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
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
    final states = context.watch<GoldPriceNotifier>().allStates;
    final gl = MarketValueService.gainLoss(jewellery, states);
    final glPct = MarketValueService.gainLossPct(jewellery, states);

    final typeName = jewellery.jewelleryTypeId != null
        ? _nonBlank(HiveService.getJewelleryType(jewellery.jewelleryTypeId!)
            ?.localizedName(l10n.locale))
        : null;
    final ownerName = _nonBlank(item.ownerName);
    // Treat the "—" placeholder (set when an item has no owner) as absent.
    final ownerDisplay = (ownerName == null || ownerName == '—')
        ? null
        : ownerName;
    final brandName = _nonBlank(jewellery.brand);
    final totalPrice = jewellery.totalPrice ?? 0.0;
    final priceText =
        '${item.currencySymbol} ${totalPrice.toStringAsFixed(2)}';
    final purityValue = _nonBlank(jewellery.goldPurity);
    final firstPhoto = jewellery.jewelleryPhoto.isNotEmpty
        ? jewellery.jewelleryPhoto.first
        : null;

    // Single metadata line: "Brand · Type · Owner" (blanks skipped, no
    // "Label:" prefixes; date is intentionally omitted — the list is
    // date-sorted and the date lives on the detail page).
    final metaLine = [?brandName, ?typeName, ?ownerDisplay].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [appTheme.cardShadow],
          ),
          child: SketchBorder(
            radius: 16,
            color: appTheme.border,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _JewelleryThumbnail(
                              base64Photo: firstPhoto,
                              appTheme: appTheme,
                            ),
                          ),
                        ),
                        if (purityValue != null)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: _PurityBadge(
                              purity: purityValue,
                              appTheme: appTheme,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nonBlank(jewellery.name) ?? l10n.untitled,
                          // Inline size override (15) — does not touch the
                          // shared AppTextStyles.title token (16) used elsewhere.
                          style: AppTextStyles.title(appTheme.inkDark)
                              .copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          metaLine,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: appTheme.textBody,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (gl != null &&
                                jewellery.totalPrice != null &&
                                jewellery.totalPrice! > 0)
                              _GlChip(
                                gl: gl,
                                glPct: glPct,
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

/// Compact purity chip overlaid on the top-left of the thumbnail. Uses a
/// solid on-brand background + white text so it stays legible over any photo.
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: appTheme.primaryDark,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        purity,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}

class _GlChip extends StatelessWidget {
  final double gl;
  final double? glPct;
  final AppTheme appTheme;

  const _GlChip({
    required this.gl,
    required this.glPct,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isGain = gl >= 0;
    final color = isGain ? appTheme.success : appTheme.error;
    final label = glPct != null
        ? '${isGain ? '+' : ''}${glPct!.toStringAsFixed(1)}%'
        : '${isGain ? '+' : ''}${gl.toStringAsFixed(0)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGain ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 10,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
