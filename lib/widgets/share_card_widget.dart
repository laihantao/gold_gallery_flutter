import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/jewellery.dart';
import '../theme/app_theme.dart';

class ShareCardWidget extends StatelessWidget {
  final Jewellery jewellery;
  final String? ownerName;
  final double? currentValue;
  final double? gainLoss;
  final double? gainLossPct;
  final String currencySymbol;
  final AppTheme appTheme;

  const ShareCardWidget({
    super.key,
    required this.jewellery,
    required this.ownerName,
    required this.currentValue,
    required this.gainLoss,
    required this.gainLossPct,
    required this.currencySymbol,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isGain = (gainLoss ?? 0) >= 0;
    final gainColor = isGain ? const Color(0xFF3DAA3D) : const Color(0xFFCC4444);
    final hasPhoto =
        jewellery.jewelleryPhoto.isNotEmpty && jewellery.jewelleryPhoto.first.isNotEmpty;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top accent bar ──
          Container(
            height: 5,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [appTheme.primary, appTheme.primaryDark],
              ),
            ),
          ),

          // ── Photo ──
          if (hasPhoto)
            ClipRRect(
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.file(
                  File(jewellery.jewelleryPhoto.first),
                  fit: BoxFit.cover,
                  errorBuilder: (_, err, stack) => _NoPhoto(appTheme: appTheme),
                ),
              ),
            )
          else
            _NoPhoto(appTheme: appTheme),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + purity badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        jewellery.name,
                        style: GoogleFonts.nunito(
                          color: appTheme.inkDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: appTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        jewellery.goldPurity,
                        style: GoogleFonts.nunito(
                          color: appTheme.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  jewellery.brand,
                  style: GoogleFonts.nunito(
                    color: appTheme.inkMid,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: appTheme.border),
                const SizedBox(height: 12),

                // ── Stats row ──
                Row(
                  children: [
                    _StatChip(
                      label: 'Weight',
                      value: jewellery.weight != null
                          ? '${jewellery.weight!.toStringAsFixed(2)}g'
                          : '—',
                      appTheme: appTheme,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Purchased',
                      value: DateFormat('d MMM yyyy').format(jewellery.date),
                      appTheme: appTheme,
                    ),
                    if (ownerName != null) ...[
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Owner',
                        value: ownerName!,
                        appTheme: appTheme,
                      ),
                    ],
                  ],
                ),

                if (currentValue != null) ...[
                  const SizedBox(height: 12),
                  // ── Market value card ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: appTheme.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: appTheme.border.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Market Value',
                              style: GoogleFonts.nunito(
                                color: appTheme.inkLight,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '$currencySymbol ${currentValue!.toStringAsFixed(2)}',
                              style: GoogleFonts.nunito(
                                color: appTheme.inkDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if (gainLoss != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: gainColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: gainColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGain
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: gainColor,
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  gainLossPct != null
                                      ? '${isGain ? '+' : ''}${gainLossPct!.toStringAsFixed(1)}%'
                                      : '${isGain ? '+' : ''}$currencySymbol ${gainLoss!.toStringAsFixed(0)}',
                                  style: GoogleFonts.nunito(
                                    color: gainColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                // ── Footer watermark ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.diamond_outlined,
                        color: appTheme.primary, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      'Gold Gallery',
                      style: GoogleFonts.caveat(
                        color: appTheme.inkLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final AppTheme appTheme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: appTheme.primaryBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: appTheme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                color: appTheme.inkLight,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: GoogleFonts.nunito(
                color: appTheme.inkDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoPhoto extends StatelessWidget {
  final AppTheme appTheme;
  const _NoPhoto({required this.appTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: appTheme.primaryLight,
      child: Center(
        child: Icon(Icons.diamond_outlined,
            color: appTheme.primary.withValues(alpha: 0.4), size: 48),
      ),
    );
  }
}
