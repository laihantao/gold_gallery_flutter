import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/export_settings.dart';
import '../models/jewellery.dart';
import '../services/hive_service.dart';

class PdfExportService {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// Generates a PDF from [settings] and returns the raw bytes.
  static Future<Uint8List> generatePdf(ExportSettings settings) async {
    final fontRegular = await PdfGoogleFonts.notoSansSCRegular();
    final fontBold = await PdfGoogleFonts.notoSansSCBold();

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

    // Decode base64 thumbnails for product-card format.
    // Photos are stored as base64 strings, not file paths.
    final thumbnails = <int, Uint8List?>{};
    if (settings.format == ExportFormat.productCard &&
        settings.includePhotos) {
      for (final j in filtered) {
        if (j.jewelleryPhoto.isNotEmpty) {
          try {
            thumbnails[j.id] = base64Decode(j.jewelleryPhoto.first);
          } catch (_) {
            thumbnails[j.id] = null;
          }
        }
      }
    }

    // ── PDF colours / styles ────────────────────────────────────────────────
    final gold = PdfColor.fromHex('#D4A843');
    final goldLight = PdfColor.fromHex('#FFF8E1');
    final inkDark = PdfColor.fromHex('#28200E');
    final inkMid = PdfColor.fromHex('#5C4A38');

    final baseStyle = pw.TextStyle(font: fontRegular, fontSize: 7.5);

    // ── Date string helpers ─────────────────────────────────────────────────
    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final now = DateTime.now();
    final todayStr = fmtDate(now);

    // ── Build page content ──────────────────────────────────────────────────
    pw.Widget buildHeader(pw.Context _) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Aurum',
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 22, color: gold)),
                  pw.Text('Jewellery Inventory',
                      style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 11,
                          color: inkMid)),
                ],
              ),
              pw.Text('Generated: $todayStr',
                  style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 9,
                      color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: gold, thickness: 1.5),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            _chip('Total Items', '${filtered.length}', fontRegular,
                fontBold, goldLight, gold),
            pw.SizedBox(width: 12),
            _chip(
                'Portfolio Value',
                '$currencySymbol ${filtered.fold<double>(0, (s, j) => s + (j.totalPrice ?? 0)).toStringAsFixed(2)}',
                fontRegular,
                fontBold,
                goldLight,
                gold),
          ]),
          pw.SizedBox(height: 10),
        ],
      );
    }

    pw.Widget buildFooter(pw.Context ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}  |  Pocket Gold Inventory',
              style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 8,
                  color: PdfColors.grey500),
            ),
          ],
        );

    // ── Table format ────────────────────────────────────────────────────────
    List<pw.Widget> buildTableContent(List<Jewellery> items) {
      final cols = ExportColumn.values
          .where((c) => settings.columns.contains(c))
          .toList();

      Map<int, pw.TableColumnWidth> colWidths = {
        for (int i = 0; i < cols.length; i++)
          i: pw.FlexColumnWidth(cols[i].flex)
      };

      pw.TableRow headerRow() => pw.TableRow(
            decoration: pw.BoxDecoration(color: goldLight),
            children: [
              for (final c in cols)
                _hCell(_colHeader(c, currencySymbol), fontBold, inkDark, goldLight),
            ],
          );

      List<pw.TableRow> dataRows(List<Jewellery> rows) =>
          rows.asMap().entries.map((e) {
            final i = e.key;
            final j = e.value;
            final bg = i.isOdd
                ? const PdfColor(0.97, 0.97, 0.97)
                : PdfColors.white;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                for (final c in cols)
                  _cellForColumn(c, j, typeMap, userMap,
                      currencySymbol, fmtDate, baseStyle, bg),
              ],
            );
          }).toList();

      if (!settings.groupByUser) {
        return [
          pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: colWidths,
            children: [headerRow(), ...dataRows(items)],
          ),
        ];
      }

      // Group by user: one table per owner, sorted by user ID asc.
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

      final widgets = <pw.Widget>[];
      for (final ownerId in sortedOwners) {
        final ownerName =
            ownerId != null ? (userMap[ownerId] ?? 'User $ownerId') : 'Unassigned';
        final ownerItems = grouped[ownerId]!;
        final ownerTotal =
            ownerItems.fold<double>(0, (s, j) => s + (j.totalPrice ?? 0));

        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 16, bottom: 4),
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: goldLight,
              border: pw.Border(
                  left: pw.BorderSide(color: gold, width: 3)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(ownerName,
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 10, color: inkDark)),
                pw.Text(
                    '${ownerItems.length} item${ownerItems.length == 1 ? '' : 's'} • $currencySymbol ${ownerTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 9,
                        color: inkMid)),
              ],
            ),
          ),
        );

        widgets.add(
          pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: colWidths,
            children: [headerRow(), ...dataRows(ownerItems)],
          ),
        );
      }
      return widgets;
    }

    // ── Product card format ─────────────────────────────────────────────────
    // Mirrors the app's JewelleryCard layout:
    // left: photo | right: name (title) + 2-col info grid + remarks
    List<pw.Widget> buildCardContent(List<Jewellery> items) {
      // Fields shown in the 2-column grid (name and remarks handled separately).
      final gridCols = ExportColumn.values
          .where((c) =>
              settings.columns.contains(c) &&
              c != ExportColumn.name &&
              c != ExportColumn.remarks)
          .toList();

      // Build (left, right?) pairs for the 2-column grid.
      final pairs = <List<ExportColumn>>[];
      for (int i = 0; i < gridCols.length; i += 2) {
        pairs.add([
          gridCols[i],
          if (i + 1 < gridCols.length) gridCols[i + 1],
        ]);
      }

      pw.Widget infoCell(ExportColumn col, Jewellery j) {
        final val =
            _valueForColumn(col, j, typeMap, userMap, currencySymbol, fmtDate);
        return pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
                text: '${col.label}: ',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 7.5, color: inkMid)),
            pw.TextSpan(
                text: val,
                style: pw.TextStyle(
                    font: fontRegular, fontSize: 7.5, color: inkDark)),
          ]),
        );
      }

      pw.Widget buildCard(Jewellery j) {
        final thumb = thumbnails[j.id];
        final hasPhoto = settings.includePhotos && thumb != null;
        final showPhoto = settings.includePhotos;

        final remarksVal = settings.columns.contains(ExportColumn.remarks)
            ? _valueForColumn(
                ExportColumn.remarks, j, typeMap, userMap, currencySymbol, fmtDate)
            : null;

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ── Photo column ──
              if (showPhoto)
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    color: hasPhoto
                        ? null
                        : const PdfColor(0.93, 0.93, 0.93),
                    // borderRadius omitted: pdf package forbids borderRadius
                    // with a non-uniform Border (only right side set here).
                    border: pw.Border(
                        right: pw.BorderSide(
                            color: PdfColors.grey300, width: 0.5)),
                  ),
                  child: hasPhoto
                      ? pw.Image(pw.MemoryImage(thumb),
                          fit: pw.BoxFit.cover, width: 80, height: 80)
                      : pw.Center(
                          child: pw.Text('—',
                              style: pw.TextStyle(
                                  font: fontRegular,
                                  fontSize: 18,
                                  color: PdfColors.grey400)),
                        ),
                ),

              // ── Info column ──
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Name title
                      if (settings.columns.contains(ExportColumn.name))
                        pw.Text(
                          j.name.isNotEmpty ? j.name : 'Untitled',
                          style: pw.TextStyle(
                              font: fontBold, fontSize: 9.5, color: inkDark),
                        ),

                      if (pairs.isNotEmpty) ...[
                        pw.SizedBox(height: 5),
                        pw.Divider(
                            color: PdfColors.grey300, thickness: 0.5),
                        pw.SizedBox(height: 4),

                        // 2-column info grid
                        ...pairs.map((pair) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Row(
                                children: [
                                  pw.Expanded(
                                      child: infoCell(pair[0], j)),
                                  if (pair.length > 1)
                                    pw.Expanded(
                                        child: infoCell(pair[1], j))
                                  else
                                    pw.Expanded(child: pw.SizedBox()),
                                ],
                              ),
                            )),
                      ],

                      // Remarks — full width at bottom
                      if (remarksVal != null && remarksVal != '-') ...[
                        pw.SizedBox(height: 4),
                        pw.Divider(
                            color: PdfColors.grey300, thickness: 0.5),
                        pw.SizedBox(height: 3),
                        pw.RichText(
                          text: pw.TextSpan(children: [
                            pw.TextSpan(
                                text: 'Remarks: ',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 7,
                                    color: inkMid)),
                            pw.TextSpan(
                                text: remarksVal,
                                style: pw.TextStyle(
                                    font: fontRegular,
                                    fontSize: 7,
                                    color: inkDark)),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (!settings.groupByUser) {
        return [for (final j in items) buildCard(j)];
      }

      // Group by user.
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

      final widgets = <pw.Widget>[];
      for (final ownerId in sortedOwners) {
        final ownerName = ownerId != null
            ? (userMap[ownerId] ?? 'User $ownerId')
            : 'Unassigned';
        final ownerItems = grouped[ownerId]!;
        final ownerTotal =
            ownerItems.fold<double>(0, (s, j) => s + (j.totalPrice ?? 0));

        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: goldLight,
              border: pw.Border(left: pw.BorderSide(color: gold, width: 3)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(ownerName,
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 10, color: inkDark)),
                pw.Text(
                    '${ownerItems.length} item${ownerItems.length == 1 ? '' : 's'} • $currencySymbol ${ownerTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        font: fontRegular, fontSize: 9, color: inkMid)),
              ],
            ),
          ),
        );
        widgets.addAll(ownerItems.map(buildCard));
      }
      return widgets;
    }

    // ── Assemble document ───────────────────────────────────────────────────
    final pdf = pw.Document(title: 'Pocket Gold Inventory');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
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

  static String _colHeader(ExportColumn col, String currency) {
    if (col == ExportColumn.price) return 'Price ($currency)';
    return col.label;
  }

  static String _valueForColumn(
    ExportColumn col,
    Jewellery j,
    Map<int?, String> typeMap,
    Map<int?, String> userMap,
    String currency,
    String Function(DateTime) fmtDate,
  ) {
    return switch (col) {
      ExportColumn.date => fmtDate(j.date),
      ExportColumn.name =>
        j.name.isNotEmpty ? j.name : 'Untitled',
      ExportColumn.type =>
        typeMap[j.jewelleryTypeId] ?? '-',
      ExportColumn.brand =>
        j.brand.isNotEmpty ? j.brand : '-',
      ExportColumn.purity =>
        j.goldPurity.isNotEmpty ? j.goldPurity : '-',
      ExportColumn.owner =>
        j.ownerId != null ? (userMap[j.ownerId] ?? '-') : '-',
      ExportColumn.price =>
        j.totalPrice != null
            ? '$currency ${j.totalPrice!.toStringAsFixed(2)}'
            : '$currency 0.00',
      ExportColumn.remarks =>
        (j.remarks != null && j.remarks!.isNotEmpty) ? j.remarks! : '-',
    };
  }

  static pw.Widget _cellForColumn(
    ExportColumn col,
    Jewellery j,
    Map<int?, String> typeMap,
    Map<int?, String> userMap,
    String currency,
    String Function(DateTime) fmtDate,
    pw.TextStyle style,
    PdfColor bg,
  ) {
    final text = _valueForColumn(col, j, typeMap, userMap, currency, fmtDate);
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _hCell(
      String text, pw.Font fontBold, PdfColor color, PdfColor bg) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          style: pw.TextStyle(font: fontBold, fontSize: 8, color: color)),
    );
  }

  static pw.Widget _chip(
    String label,
    String value,
    pw.Font fontRegular,
    pw.Font fontBold,
    PdfColor bg,
    PdfColor border,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: border, width: 0.5),
      ),
      child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 9,
                  color: PdfColors.grey700)),
          pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: PdfColors.brown800)),
        ]),
      ),
    );
  }
}
