import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/export_settings.dart';
import '../models/jewellery.dart';
import '../services/hive_service.dart';

/// Certificate-style PDF export: cream + gold, serif typography, dashed gold
/// dividers (证书风格). Visual target: pocket-gold-pdf-redesign.html.
///
/// Dimensions are the HTML reference's px values scaled ×0.75 so an A4 page
/// (595pt) matches the 794px-wide design exactly.
class PdfExportService {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static final PdfColor _paper = PdfColor.fromHex('#F8F3E6');
  static final PdfColor _gold = PdfColor.fromHex('#A9812E');
  static final PdfColor _goldDeep = PdfColor.fromHex('#876418');
  static final PdfColor _ink = PdfColor.fromHex('#3B3325');
  static final PdfColor _muted = PdfColor.fromHex('#8E8266');
  static final PdfColor _tint = PdfColor.fromHex('#F1E7CA');
  // Gold pre-blended onto paper at 55% / 42% opacity — flat colors keep the
  // document free of transparency graphic states.
  static final PdfColor _line = PdfColor.fromHex('#CDB481');
  static final PdfColor _dash = PdfColor.fromHex('#D7C399');

  static const _dashedSide =
      pw.BorderSide(width: 0.75, style: pw.BorderStyle.dashed);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Generates a PDF from [settings] and returns the raw bytes.
  static Future<Uint8List> generatePdf(ExportSettings settings) async {
    final fontResults = await Future.wait([
      PdfGoogleFonts.cormorantGaramondMedium(),
      PdfGoogleFonts.cormorantGaramondMediumItalic(),
      PdfGoogleFonts.cormorantGaramondSemiBold(),
      PdfGoogleFonts.cormorantGaramondSemiBoldItalic(),
      PdfGoogleFonts.notoSerifSCRegular(),
      PdfGoogleFonts.notoSerifSCSemiBold(),
    ]);
    final serif = fontResults[0];
    final serifItalic = fontResults[1];
    final serifSemiBold = fontResults[2];
    final serifSemiBoldItalic = fontResults[3];
    final cjk = fontResults[4];
    final cjkSemiBold = fontResults[5];

    final allItems = HiveService.getAllJewellery();
    final types = HiveService.getAllJewelleryTypes();
    final users = HiveService.getAllUsers();
    final currencySymbol =
        HiveService.getCurrencyByCode('MYR')?.symbol ?? 'RM';

    final typeMap = {for (final t in types) t.id: t.name};
    final userMap = {for (final u in users) u.id: u.name};

    // ── Filter ──────────────────────────────────────────────────────────────
    final filtered = allItems.where((j) {
      // User filter: null-owner items always pass.
      if (j.ownerId != null &&
          !settings.selectedUserIds.contains(j.ownerId)) {
        return false;
      }
      // Date range filter.
      if (settings.fromDate != null &&
          j.date.isBefore(settings.fromDate!)) {
        return false;
      }
      if (settings.toDate != null) {
        final dayAfter =
            settings.toDate!.add(const Duration(days: 1));
        if (!j.date.isBefore(dayAfter)) return false;
      }
      return true;
    }).toList();

    // Sort: by type name asc, then date desc.
    filtered.sort((a, b) {
      final ta = typeMap[a.jewelleryTypeId] ?? '';
      final tb = typeMap[b.jewelleryTypeId] ?? '';
      final c = ta.compareTo(tb);
      return c != 0 ? c : b.date.compareTo(a.date);
    });

    // Decode base64 thumbnails for product-card format, downscaled so the
    // exported file stays small.
    final thumbnails = <int, Uint8List?>{};
    if (settings.format == ExportFormat.productCard &&
        settings.includePhotos) {
      for (final j in filtered) {
        if (j.jewelleryPhoto.isNotEmpty) {
          try {
            thumbnails[j.id] =
                await _downscaleImage(base64Decode(j.jewelleryPhoto.first));
          } catch (_) {
            thumbnails[j.id] = null;
          }
        }
      }
    }

    // ── Formatting helpers ──────────────────────────────────────────────────
    final moneyFmt = NumberFormat('#,##0.00');
    String fmtMoney(double? v) => moneyFmt.format(v ?? 0);
    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final generatedStr = DateFormat('d MMM yyyy').format(DateTime.now());
    final totalValue =
        filtered.fold<double>(0, (s, j) => s + (j.totalPrice ?? 0));

    // ── Shared text styles ──────────────────────────────────────────────────
    final remarkStyle = pw.TextStyle(
        font: serifItalic,
        fontSize: 7.9,
        color: _muted,
        fontFallback: [cjk]);

    // ── Small building blocks ───────────────────────────────────────────────
    pw.Widget diamond(double size, PdfColor color) => pw.Transform.rotateBox(
        angle: math.pi / 4,
        child: pw.Container(width: size, height: size, color: color));

    pw.Widget solidLine() => pw.Container(height: 0.75, color: _line);

    pw.Widget dashedLine() => pw.Container(
          height: 0.75,
          decoration: pw.BoxDecoration(
            border: pw.Border(
                bottom: _dashedSide.copyWith(color: _dash)),
          ),
        );

    // ── Page chrome: certificate double frame (background of every page) ────
    pw.Widget buildBackground(pw.Context _) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            color: _paper,
            padding: const pw.EdgeInsets.all(19.5),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _line, width: 0.75),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              padding: const pw.EdgeInsets.all(3.75),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: _dash,
                      width: 0.75,
                      style: pw.BorderStyle.dashed),
                  borderRadius: pw.BorderRadius.circular(10.5),
                ),
              ),
            ),
          ),
        );

    // ── Header (every page): brand, rule, date, summary strip ───────────────
    pw.Widget buildHeader(pw.Context _) {
      pw.Widget summaryCell(String label, pw.TextSpan value,
          {bool leftDivider = false}) {
        return pw.Expanded(
          child: pw.Container(
            decoration: leftDivider
                ? pw.BoxDecoration(
                    border: pw.Border(
                        left: _dashedSide.copyWith(color: _dash)))
                : null,
            child: pw.Column(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 2.5),
                child: pw.Text(label,
                    style: pw.TextStyle(
                        font: cjk,
                        fontSize: 8.25,
                        color: _muted,
                        letterSpacing: 2.5)),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(text: value, textAlign: pw.TextAlign.center),
            ]),
          ),
        );
      }

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('Pocket Gold',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  font: serifSemiBoldItalic,
                  fontSize: 28.5,
                  color: _gold,
                  letterSpacing: 0.6)),
          pw.SizedBox(height: 6),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 5.6),
            child: pw.Text('珠宝库存清单',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    font: cjkSemiBold,
                    fontSize: 9,
                    color: _goldDeep,
                    letterSpacing: 5.6)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 15, bottom: 10.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(child: solidLine()),
                pw.SizedBox(width: 10.5),
                diamond(5, _gold),
                pw.SizedBox(width: 10.5),
                pw.Expanded(child: solidLine()),
              ],
            ),
          ),
          pw.Text('生成于 $generatedStr',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  font: cjk,
                  fontSize: 8.25,
                  color: _muted,
                  letterSpacing: 1.15,
                  fontFallback: [serif])),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 19.5, bottom: 22.5),
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            decoration: pw.BoxDecoration(
              color: _tint,
              border: pw.Border.all(
                  color: _dash, width: 0.75, style: pw.BorderStyle.dashed),
              borderRadius: pw.BorderRadius.circular(9),
            ),
            child: pw.Row(children: [
              summaryCell(
                '总数量',
                pw.TextSpan(children: [
                  pw.TextSpan(
                      text: '${filtered.length}',
                      style: pw.TextStyle(
                          font: serifSemiBold,
                          fontSize: 19.5,
                          color: _goldDeep)),
                  pw.TextSpan(
                      text: ' 件',
                      style: pw.TextStyle(
                          font: cjk, fontSize: 10.5, color: _muted)),
                ]),
              ),
              summaryCell(
                '总价值',
                pw.TextSpan(children: [
                  pw.TextSpan(
                      text: '$currencySymbol ',
                      style: pw.TextStyle(
                          font: serif, fontSize: 10.5, color: _muted)),
                  pw.TextSpan(
                      text: fmtMoney(totalValue),
                      style: pw.TextStyle(
                          font: serifSemiBold,
                          fontSize: 19.5,
                          color: _goldDeep)),
                ]),
                leftDivider: true,
              ),
            ]),
          ),
        ],
      );
    }

    // ── Footer (every page) ─────────────────────────────────────────────────
    pw.Widget buildFooter(pw.Context ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 19.5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(child: dashedLine()),
              pw.SizedBox(width: 12),
              pw.Text(
                '第 ${ctx.pageNumber} 页 · 共 ${ctx.pagesCount} 页  —  Pocket Gold Inventory',
                style: pw.TextStyle(
                    font: serifItalic,
                    fontSize: 8.25,
                    color: _muted,
                    letterSpacing: 1,
                    fontFallback: [cjk]),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(child: dashedLine()),
            ],
          ),
        );

    // ── Owner group band (both grouped modes) ───────────────────────────────
    pw.Widget ownerBand(String name, int count, double total,
        {required bool underline, required bool first}) {
      return pw.Container(
        margin: pw.EdgeInsets.only(
            top: first ? 1.5 : 19.5, bottom: underline ? 3 : 9),
        padding: underline ? const pw.EdgeInsets.only(bottom: 6) : null,
        decoration: underline
            ? pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(color: _line, width: 0.75)))
            : null,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                diamond(3.75, _gold),
                pw.SizedBox(width: 7.5),
                pw.Text(name,
                    style: pw.TextStyle(
                        font: serifSemiBoldItalic,
                        fontSize: 15.75,
                        color: _goldDeep,
                        fontFallback: [cjkSemiBold])),
              ],
            ),
            pw.RichText(
                text: pw.TextSpan(children: [
              pw.TextSpan(
                  text: '$count 件 · ',
                  style: pw.TextStyle(
                      font: cjk, fontSize: 8.6, color: _muted)),
              pw.TextSpan(
                  text: '$currencySymbol ${fmtMoney(total)}',
                  style: pw.TextStyle(
                      font: serifSemiBold,
                      fontSize: 10.5,
                      color: _goldDeep)),
            ])),
          ],
        ),
      );
    }

    // Groups items by owner, sorted by owner ID asc (null owner last).
    List<MapEntry<String, List<Jewellery>>> groupByOwner(
        List<Jewellery> items) {
      final grouped = <int?, List<Jewellery>>{};
      for (final j in items) {
        (grouped[j.ownerId] ??= []).add(j);
      }
      final sortedOwners = grouped.keys.toList()
        ..sort((a, b) {
          if (a == null) return 1;
          if (b == null) return -1;
          return a.compareTo(b);
        });
      return [
        for (final id in sortedOwners)
          MapEntry(
              id != null ? (userMap[id] ?? 'User $id') : 'Unassigned',
              grouped[id]!),
      ];
    }

    // ── Table mode ──────────────────────────────────────────────────────────
    List<pw.Widget> buildTableContent(List<Jewellery> items) {
      // Grouped mode: the owner column is redundant inside a group.
      final cols = ExportColumn.values
          .where((c) =>
              settings.columns.contains(c) &&
              !(settings.groupByUser && c == ExportColumn.owner))
          .toList();
      if (cols.isEmpty) return [];

      int flexOf(ExportColumn c) => (c.flex * 10).round();

      pw.Widget headerRow() => pw.Container(
            decoration: pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(color: _line, width: 0.75))),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (final c in cols)
                  pw.Expanded(
                    flex: flexOf(c),
                    child: pw.Padding(
                      padding:
                          const pw.EdgeInsets.fromLTRB(4.5, 0, 4.5, 7.5),
                      child: pw.Column(
                        crossAxisAlignment: c == ExportColumn.price
                            ? pw.CrossAxisAlignment.end
                            : pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_zhLabel(c),
                              style: pw.TextStyle(
                                  font: cjkSemiBold,
                                  fontSize: 9.4,
                                  color: _goldDeep)),
                          pw.SizedBox(height: 1.5),
                          pw.Text(
                              _enLabel(c, currencySymbol).toUpperCase(),
                              style: pw.TextStyle(
                                  font: serif,
                                  fontSize: 6.4,
                                  color: _muted,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );

      pw.Widget cellText(ExportColumn c, Jewellery j) {
        switch (c) {
          case ExportColumn.date:
            return pw.Text(fmtDate(j.date),
                style: pw.TextStyle(
                    font: serif, fontSize: 9.4, color: _muted));
          case ExportColumn.name:
            return pw.Text(j.name.isNotEmpty ? j.name : 'Untitled',
                style: pw.TextStyle(
                    font: cjkSemiBold, fontSize: 8.6, color: _ink));
          case ExportColumn.type:
            return pw.Text(typeMap[j.jewelleryTypeId] ?? '—',
                style: pw.TextStyle(
                    font: cjk, fontSize: 8.6, color: _muted));
          case ExportColumn.brand:
            return pw.Text(j.brand.isNotEmpty ? j.brand : '—',
                style: pw.TextStyle(
                    font: cjk, fontSize: 8.6, color: _muted));
          case ExportColumn.purity:
            return pw.Text(
                j.goldPurity.isNotEmpty ? j.goldPurity : '—',
                style: pw.TextStyle(
                    font: serif,
                    fontSize: 9.4,
                    color: _ink,
                    fontFallback: [cjk]));
          case ExportColumn.owner:
            return pw.Text(
                j.ownerId != null ? (userMap[j.ownerId] ?? '—') : '—',
                style: pw.TextStyle(
                    font: cjk, fontSize: 8.6, color: _muted));
          case ExportColumn.price:
            // Header already says Price (RM) — no currency per row.
            return pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text(fmtMoney(j.totalPrice),
                  style: pw.TextStyle(
                      font: serifSemiBold,
                      fontSize: 10.5,
                      color: _goldDeep)),
            );
          case ExportColumn.remarks:
            final hasRemarks =
                j.remarks != null && j.remarks!.isNotEmpty;
            return pw.Text(hasRemarks ? j.remarks! : '—',
                style: remarkStyle);
        }
      }

      pw.Widget dataRow(Jewellery j, {required bool last}) => pw.Container(
            decoration: last
                ? null
                : pw.BoxDecoration(
                    border: pw.Border(
                        bottom: _dashedSide.copyWith(color: _dash))),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final c in cols)
                  pw.Expanded(
                    flex: flexOf(c),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4.5, vertical: 8.25),
                      child: cellText(c, j),
                    ),
                  ),
              ],
            ),
          );

      if (!settings.groupByUser) {
        return [
          // Keep the header attached to the first row across page breaks.
          pw.Column(children: [
            headerRow(),
            if (items.isNotEmpty)
              dataRow(items.first, last: items.length == 1),
          ]),
          for (int i = 1; i < items.length; i++)
            dataRow(items[i], last: i == items.length - 1),
        ];
      }

      final widgets = <pw.Widget>[];
      var firstGroup = true;
      for (final group in groupByOwner(items)) {
        final ownerItems = group.value;
        final ownerTotal = ownerItems.fold<double>(
            0, (s, j) => s + (j.totalPrice ?? 0));
        // Band + header + first row stay together so a band is never
        // orphaned at the bottom of a page.
        widgets.add(pw.Column(children: [
          ownerBand(group.key, ownerItems.length, ownerTotal,
              underline: true, first: firstGroup),
          headerRow(),
          dataRow(ownerItems.first, last: ownerItems.length == 1),
        ]));
        for (int i = 1; i < ownerItems.length; i++) {
          widgets.add(
              dataRow(ownerItems[i], last: i == ownerItems.length - 1));
        }
        firstGroup = false;
      }
      return widgets;
    }

    // ── Card mode ───────────────────────────────────────────────────────────
    List<pw.Widget> buildCardContent(List<Jewellery> items) {
      // Fields in the 2-column grid (name and remarks handled separately;
      // grouped mode drops the owner row inside cards).
      final gridCols = ExportColumn.values
          .where((c) =>
              settings.columns.contains(c) &&
              c != ExportColumn.name &&
              c != ExportColumn.remarks &&
              !(settings.groupByUser && c == ExportColumn.owner))
          .toList();

      pw.Widget kvValue(ExportColumn c, Jewellery j) {
        switch (c) {
          case ExportColumn.date:
            return pw.Text(fmtDate(j.date),
                style: pw.TextStyle(
                    font: serif, fontSize: 9.4, color: _ink));
          case ExportColumn.purity:
            return pw.Text(
                j.goldPurity.isNotEmpty ? j.goldPurity : '—',
                style: pw.TextStyle(
                    font: serif,
                    fontSize: 9.4,
                    color: _ink,
                    fontFallback: [cjk]));
          case ExportColumn.price:
            return pw.Text(
                '$currencySymbol ${fmtMoney(j.totalPrice)}',
                style: pw.TextStyle(
                    font: serifSemiBold,
                    fontSize: 10.9,
                    color: _goldDeep));
          case ExportColumn.type:
            return pw.Text(typeMap[j.jewelleryTypeId] ?? '—',
                style: pw.TextStyle(
                    font: cjkSemiBold, fontSize: 8.25, color: _ink));
          case ExportColumn.brand:
            return pw.Text(j.brand.isNotEmpty ? j.brand : '—',
                style: pw.TextStyle(
                    font: cjkSemiBold, fontSize: 8.25, color: _ink));
          case ExportColumn.owner:
            return pw.Text(
                j.ownerId != null ? (userMap[j.ownerId] ?? '—') : '—',
                style: pw.TextStyle(
                    font: cjkSemiBold, fontSize: 8.25, color: _ink));
          case ExportColumn.name:
          case ExportColumn.remarks:
            return pw.SizedBox();
        }
      }

      pw.Widget kvCell(ExportColumn c, Jewellery j,
          {required bool underline}) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4.9),
          decoration: underline
              ? pw.BoxDecoration(
                  border: pw.Border(
                      bottom: _dashedSide.copyWith(color: _dash)))
              : null,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(_zhLabel(c, card: true),
                  style: pw.TextStyle(
                      font: cjk,
                      fontSize: 8.25,
                      color: _muted,
                      letterSpacing: 0.8)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Align(
                    alignment: pw.Alignment.bottomRight,
                    child: kvValue(c, j)),
              ),
            ],
          ),
        );
      }

      pw.Widget placeholderThumb() => pw.Container(
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [
                  PdfColor.fromInt(0xFFEADFBF),
                  PdfColor.fromInt(0xFFD9C48C),
                  PdfColor.fromInt(0xFFE7DAB4),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
            child: pw.Center(
                child: diamond(7.5, PdfColor.fromInt(0xFFAC8F4C))),
          );

      pw.Widget thumb(Uint8List? bytes) => pw.Container(
            width: 78,
            height: 78,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line, width: 0.75),
              borderRadius: pw.BorderRadius.circular(6.75),
            ),
            padding: const pw.EdgeInsets.all(2.25),
            child: pw.ClipRRect(
              horizontalRadius: 4.5,
              verticalRadius: 4.5,
              child: bytes != null
                  ? pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover)
                  : placeholderThumb(),
            ),
          );

      pw.Widget buildCard(Jewellery j) {
        final remarksVal = settings.columns.contains(ExportColumn.remarks) &&
                j.remarks != null &&
                j.remarks!.isNotEmpty
            ? j.remarks!
            : null;

        // Pair up grid fields; the last row's cells get no underline.
        final rowCount = (gridCols.length + 1) ~/ 2;
        final gridRows = <pw.Widget>[];
        for (int r = 0; r < rowCount; r++) {
          final left = gridCols[r * 2];
          final right =
              r * 2 + 1 < gridCols.length ? gridCols[r * 2 + 1] : null;
          final lastRow = r == rowCount - 1;
          gridRows.add(pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                  child: kvCell(left, j, underline: !lastRow)),
              pw.SizedBox(width: 21),
              pw.Expanded(
                child: right != null
                    ? kvCell(right, j, underline: !lastRow)
                    : pw.SizedBox(),
              ),
            ],
          ));
        }

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10.5),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
                color: _dash, width: 0.75, style: pw.BorderStyle.dashed),
            borderRadius: pw.BorderRadius.circular(9),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (settings.includePhotos) ...[
                thumb(thumbnails[j.id]),
                pw.SizedBox(width: 13.5),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    if (settings.columns.contains(ExportColumn.name))
                      pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 6.75),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(
                                bottom:
                                    _dashedSide.copyWith(color: _dash))),
                        child: pw.Text(
                            j.name.isNotEmpty ? j.name : 'Untitled',
                            style: pw.TextStyle(
                                font: serifSemiBold,
                                fontSize: 13,
                                color: _ink,
                                fontFallback: [cjkSemiBold])),
                      ),
                    pw.SizedBox(height: 1.5),
                    ...gridRows,
                    if (remarksVal != null)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 6.75),
                        padding: const pw.EdgeInsets.only(top: 6),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(
                                top: _dashedSide.copyWith(color: _dash))),
                        child: pw.RichText(
                            text: pw.TextSpan(children: [
                          pw.TextSpan(
                              text: '备注 · ',
                              style: pw.TextStyle(
                                  font: cjk,
                                  fontSize: 7.9,
                                  color: _muted,
                                  letterSpacing: 0.8)),
                          pw.TextSpan(
                              text: remarksVal, style: remarkStyle),
                        ])),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      if (!settings.groupByUser) {
        return [for (final j in items) buildCard(j)];
      }

      final widgets = <pw.Widget>[];
      var firstGroup = true;
      for (final group in groupByOwner(items)) {
        final ownerItems = group.value;
        final ownerTotal = ownerItems.fold<double>(
            0, (s, j) => s + (j.totalPrice ?? 0));
        // Band + first card stay together to avoid an orphaned band.
        widgets.add(pw.Column(children: [
          ownerBand(group.key, ownerItems.length, ownerTotal,
              underline: false, first: firstGroup),
          buildCard(ownerItems.first),
        ]));
        widgets.addAll(ownerItems.skip(1).map(buildCard));
        firstGroup = false;
      }
      return widgets;
    }

    // ── Assemble document ───────────────────────────────────────────────────
    final pdf = pw.Document(title: 'Pocket Gold Inventory');

    pdf.addPage(
      pw.MultiPage(
        maxPages: 200,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          // paper margin 19.5 + frame 0.75 + gap 3.75 + frame 0.75 + padding
          margin: const pw.EdgeInsets.fromLTRB(60.75, 57.75, 60.75, 47.25),
          theme: pw.ThemeData.withFont(base: cjk, bold: cjkSemiBold),
          buildBackground: buildBackground,
        ),
        header: buildHeader,
        footer: buildFooter,
        build: (_) => settings.format == ExportFormat.table
            ? buildTableContent(filtered)
            : buildCardContent(filtered),
      ),
    );

    return pdf.save();
  }

  /// Opens the native "Save As" document picker so the user can choose where
  /// to save the PDF. Returns the saved path, or null if the user cancelled.
  static Future<String?> savePdf(Uint8List bytes, String filename) async {
    final nameWithoutExt = filename.endsWith('.pdf')
        ? filename.substring(0, filename.length - 4)
        : filename;
    return FileSaver.instance.saveAs(
      name: nameWithoutExt,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _zhLabel(ExportColumn col, {bool card = false}) {
    return switch (col) {
      ExportColumn.date => card ? '购买日期' : '日期',
      ExportColumn.name => '名称',
      ExportColumn.type => '类型',
      ExportColumn.brand => '品牌',
      ExportColumn.purity => '纯度',
      ExportColumn.owner => '拥有者',
      ExportColumn.price => '价格',
      ExportColumn.remarks => '备注',
    };
  }

  static String _enLabel(ExportColumn col, String currency) {
    if (col == ExportColumn.price) return 'Price ($currency)';
    return col.label;
  }

  /// Re-encodes [bytes] with the longest side capped at [maxDim] px so
  /// embedded photos don't bloat the file. Falls back to the original bytes.
  static Future<Uint8List> _downscaleImage(Uint8List bytes,
      {int maxDim = 400}) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final w = descriptor.width;
      final h = descriptor.height;
      if (w <= maxDim && h <= maxDim) return bytes;

      final scale = maxDim / (w > h ? w : h);
      final codec = await descriptor.instantiateCodec(
        targetWidth: (w * scale).round(),
        targetHeight: (h * scale).round(),
      );
      final frame = await codec.getNextFrame();
      final data =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      return data != null ? data.buffer.asUint8List() : bytes;
    } catch (_) {
      return bytes;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
