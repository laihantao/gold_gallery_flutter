import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/jewellery.dart';

/// Fixed "certificate of ownership" palette — deliberately independent of
/// [AurumTheme] so the shared image keeps the same premium gold-on-parchment
/// look no matter which in-app theme the owner has selected.
const Color kCertBg = Color(0xFFFBF6EA);
const Color kCertFrame = Color(0xFFD8C79A);
const Color kCertGold = Color(0xFFA8863B);
const Color kCertGoldMuted = Color(0xFFB7A05C);
const Color kCertInkDark = Color(0xFF2B2620);
const Color kCertInkMuted = Color(0xFF8C8172);
const Color kCertChipBg = Color(0xFFF6F0E0);
const Color kCertFooterMuted = Color(0xFFB0A48F);
const Color kCertButtonBg = Color(0xFFFDFCF8);
const Color kCertShareGradientTop = Color(0xFFC9A85A);
const Color kCertShareGradientBottom = Color(0xFFB4913F);

class ShareCardWidget extends StatelessWidget {
  final Jewellery jewellery;
  final String? ownerName;
  final String currencySymbol;

  const ShareCardWidget({
    super.key,
    required this.jewellery,
    required this.ownerName,
    required this.currencySymbol,
  });

  Widget _buildPhoto() {
    if (jewellery.jewelleryPhoto.isEmpty ||
        jewellery.jewelleryPhoto.first.isEmpty) {
      return const _NoPhoto();
    }
    final path = jewellery.jewelleryPhoto.first;

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _NoPhoto(),
      );
    }

    // Try as base64
    try {
      final bytes = base64Decode(path);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _NoPhoto(),
      );
    } catch (_) {
      return const _NoPhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasTotal = jewellery.totalPrice != null && jewellery.totalPrice! > 0;
    final hasLabor = jewellery.laborFees != null && jewellery.laborFees! > 0;

    final specRows = <(String, String)>[
      (l10n.rowPurity, l10n.purityGoldLabel(jewellery.goldPurity)),
      (
        l10n.rowWeight,
        jewellery.weight != null
            ? '${jewellery.weight!.toStringAsFixed(2)} g'
            : '—',
      ),
      (
        l10n.purchasedDateLabel,
        DateFormat('d MMM yyyy').format(jewellery.date),
      ),
      if (ownerName != null) (l10n.rowOwner, ownerName!),
      if (jewellery.pricePerGram != null)
        (l10n.rowPricePerGram, '$currencySymbol ${jewellery.pricePerGram}'),
      if (hasLabor)
        (
          l10n.rowLaborFees,
          '$currencySymbol ${jewellery.laborFees!.toStringAsFixed(2)}',
        ),
    ];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCertBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          border: Border.all(color: kCertFrame, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Header ──
            Text(
              'Pocket Gold',
              style: GoogleFonts.playfairDisplay(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: kCertGold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.certificateOfOwnership,
              style: GoogleFonts.nunito(
                fontSize: 9.5,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: kCertGoldMuted,
              ),
            ),
            const SizedBox(height: 14),

            // ── Framed photo ──
            Container(
              width: 190,
              height: 135,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(color: kCertFrame, width: 1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: _buildPhoto(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Name ──
            Text(
              jewellery.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: kCertInkDark,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              jewellery.brand.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
                color: kCertInkMuted,
              ),
            ),
            const SizedBox(height: 14),

            // ── Spec table ──
            for (var i = 0; i < specRows.length; i++)
              _SpecRow(
                label: specRows[i].$1,
                value: specRows[i].$2,
                showDivider: i != specRows.length - 1,
              ),

            // ── Total Paid ──
            if (hasTotal) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: kCertChipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.totalPaidCaps,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: kCertInkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currencySymbol ${jewellery.totalPrice!.toStringAsFixed(2)}',
                      style: GoogleFonts.cormorantGaramond(
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                        color: kCertGold,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Footer ──
            const SizedBox(height: 12),
            Text(
              l10n.generatedOn(DateFormat('d MMM yyyy').format(DateTime.now())),
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                color: kCertFooterMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _SpecRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(fontSize: 12.5, color: kCertInkMuted),
              ),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: kCertInkDark,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const _DottedLine(color: kCertFrame),
      ],
    );
  }
}

class _DottedLine extends StatelessWidget {
  final Color color;
  const _DottedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 3.0;
        const dashSpace = 3.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
            .floor();
        return SizedBox(
          height: 1,
          width: double.infinity,
          child: Row(
            children: List.generate(
              dashCount,
              (_) => Container(
                width: dashWidth,
                height: 1,
                margin: const EdgeInsets.only(right: dashSpace),
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoPhoto extends StatelessWidget {
  const _NoPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kCertChipBg,
      child: Center(
        child: Icon(
          Icons.diamond_outlined,
          color: kCertGold.withValues(alpha: 0.4),
          size: 36,
        ),
      ),
    );
  }
}
