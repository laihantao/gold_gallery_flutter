import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../services/pdf_export_service.dart';
import '../theme/theme_notifier.dart';

class PdfPreviewPage extends StatelessWidget {
  final Uint8List bytes;
  final String filename;

  const PdfPreviewPage({
    super.key,
    required this.bytes,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Scaffold(
      appBar: AppHeader(
        title: 'Preview',
        actions: [
          IconButton(
            icon: Icon(Icons.download_outlined,
                color: appTheme.inkDark, size: 24),
            tooltip: 'Save to device',
            onPressed: () async {
              final path = await PdfExportService.savePdf(bytes, filename);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    path == 'shared'
                        ? 'PDF shared successfully.'
                        : 'PDF saved to device storage.',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => bytes,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: filename,
        scrollViewDecoration:
            BoxDecoration(color: appTheme.primaryBg),
        previewPageMargin: const EdgeInsets.all(16),
      ),
    );
  }
}
