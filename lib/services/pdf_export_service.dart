import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/hive_service.dart';

class PdfExportService {
  static Future<void> exportInventory() async {
    final allItems = HiveService.getAllJewellery();
    final types = HiveService.getAllJewelleryTypes();
    final users = HiveService.getAllUsers();
    final currencySymbol =
        HiveService.getCurrencyByCode('MYR')?.symbol ?? 'RM';

    final typeMap = {for (final t in types) t.id: t.name};
    final userMap = {for (final u in users) u.id: u.name};

    final totalValue =
        allItems.fold<double>(0, (sum, j) => sum + (j.totalPrice ?? 0));
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final pdf = pw.Document(title: 'Aurum Jewellery Inventory');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Aurum — Jewellery Inventory',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Generated: $dateStr',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.amber300, thickness: 1.5),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                _summaryChip('Total Items', '${allItems.length}'),
                pw.SizedBox(width: 24),
                _summaryChip(
                  'Portfolio Value',
                  '$currencySymbol ${totalValue.toStringAsFixed(2)}',
                ),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.0), // Name
              1: const pw.FlexColumnWidth(1.5), // Type
              2: const pw.FlexColumnWidth(2.0), // Brand
              3: const pw.FlexColumnWidth(1.0), // Purity
              4: const pw.FlexColumnWidth(1.5), // Owner
              5: const pw.FlexColumnWidth(2.0), // Price
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.amber100),
                children: [
                  _headerCell('Name'),
                  _headerCell('Type'),
                  _headerCell('Brand'),
                  _headerCell('Purity'),
                  _headerCell('Owner'),
                  _headerCell('Price ($currencySymbol)'),
                ],
              ),
              // Data rows
              ...allItems.asMap().entries.map((entry) {
                final i = entry.key;
                final j = entry.value;
                final bg = i.isOdd ? PdfColors.grey50 : PdfColors.white;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _dataCell(j.name.isNotEmpty ? j.name : 'Untitled'),
                    _dataCell(j.jewelleryTypeId != null
                        ? typeMap[j.jewelleryTypeId] ?? '—'
                        : '—'),
                    _dataCell(j.brand.isNotEmpty ? j.brand : '—'),
                    _dataCell(
                        j.goldPurity.isNotEmpty ? j.goldPurity : '—'),
                    _dataCell(
                        j.ownerId != null ? userMap[j.ownerId] ?? '—' : '—'),
                    _dataCell(j.totalPrice != null
                        ? j.totalPrice!.toStringAsFixed(2)
                        : '0.00'),
                  ],
                );
              }),
            ],
          ),
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}  •  Aurum Jewellery Tracker',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'aurum_inventory_$dateStr.pdf',
    );
  }

  static pw.Widget _summaryChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.amber300, width: 0.5),
      ),
      child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(
            text: '$label: ',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown800,
            ),
          ),
        ]),
      ),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _dataCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }
}
