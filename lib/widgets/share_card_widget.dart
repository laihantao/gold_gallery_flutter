import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/jewellery.dart';
import '../theme/app_theme.dart';

class ShareCardWidget extends StatelessWidget {
  final Jewellery jewellery;
  final String? ownerName;
  final String currencySymbol;
  final AppTheme appTheme;

  const ShareCardWidget({
    super.key,
    required this.jewellery,
    required this.ownerName,
    required this.currencySymbol,
    required this.appTheme,
  });

  Widget _buildPhoto() {
    const double h = 180;
    if (jewellery.jewelleryPhoto.isEmpty ||
        jewellery.jewelleryPhoto.first.isEmpty) {
      return _NoPhoto(appTheme: appTheme);
    }
    final path = jewellery.jewelleryPhoto.first;

    if (path.startsWith('assets/')) {
      return SizedBox(
        height: h,
        width: double.infinity,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          width: double.infinity,
          height: h,
        ),
      );
    }

    if (File(path).existsSync()) {
      return SizedBox(
        height: h,
        width: double.infinity,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: h,
          errorBuilder: (_, _, _) => _NoPhoto(appTheme: appTheme),
        ),
      );
    }

    // Try as base64
    try {
      final bytes = base64Decode(path);
      return SizedBox(
        height: h,
        width: double.infinity,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: h,
          errorBuilder: (_, _, _) => _NoPhoto(appTheme: appTheme),
        ),
      );
    } catch (_) {
      return _NoPhoto(appTheme: appTheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTotal =
        jewellery.totalPrice != null && jewellery.totalPrice! > 0;

    return Container(
      width: 320,
      clipBehavior: Clip.antiAlias,
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [appTheme.primary, appTheme.primaryDark],
              ),
            ),
          ),

          // ── Photo ──
          _buildPhoto(),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
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

                // ── Total Paid card ──
                if (hasTotal) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: appTheme.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: appTheme.border.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Paid',
                              style: GoogleFonts.nunito(
                                color: appTheme.inkLight,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '$currencySymbol ${jewellery.totalPrice!.toStringAsFixed(2)}',
                              style: GoogleFonts.nunito(
                                color: appTheme.inkDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (jewellery.pricePerGram != null) ...[
                              Text(
                                'Price / g',
                                style: GoogleFonts.nunito(
                                  color: appTheme.inkLight,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '$currencySymbol ${jewellery.pricePerGram}',
                                style: GoogleFonts.nunito(
                                  color: appTheme.inkMid,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (jewellery.laborFees != null &&
                                jewellery.laborFees! > 0) ...[
                              if (jewellery.pricePerGram != null)
                                const SizedBox(height: 6),
                              Text(
                                'Labor Cost',
                                style: GoogleFonts.nunito(
                                  color: appTheme.inkLight,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '$currencySymbol ${jewellery.laborFees!.toStringAsFixed(2)}',
                                style: GoogleFonts.nunito(
                                  color: appTheme.inkMid,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                // ── Footer ──
                Row(
                  children: [
                    Icon(Icons.diamond_outlined,
                        color: appTheme.primary, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      'Pocket Gold',
                      style: GoogleFonts.caveat(
                        color: appTheme.inkLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Generated ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                      style: GoogleFonts.nunito(
                        color: appTheme.inkLight,
                        fontSize: 9,
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
          border:
              Border.all(color: appTheme.border.withValues(alpha: 0.5)),
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
