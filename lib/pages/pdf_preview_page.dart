import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../theme/theme_notifier.dart';

class PdfPreviewPage extends StatefulWidget {
  final Uint8List bytes;
  final String filename;

  const PdfPreviewPage({
    super.key,
    required this.bytes,
    required this.filename,
  });

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  // null while rasterizing, empty list means raster produced no pages
  List<Uint8List>? _pages;
  bool _isSaving = false;
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _rasterize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _rasterize() async {
    final pages = <Uint8List>[];
    // dpi: 150 balances sharpness with memory on mobile
    await for (final raster in Printing.raster(widget.bytes, dpi: 150)) {
      pages.add(await raster.toPng());
    }
    if (mounted) setState(() => _pages = pages);
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final nameWithoutExt = widget.filename.endsWith('.pdf')
          ? widget.filename.substring(0, widget.filename.length - 4)
          : widget.filename;
      await FileSaver.instance.saveAs(
        name: nameWithoutExt,
        bytes: widget.bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final pages = _pages;
    final total = pages?.length ?? 0;

    return Scaffold(
      appBar: AppHeader(
        title: pages != null && total > 0
            ? 'Page ${_currentPage + 1} of $total'
            : 'Preview',
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.download_outlined,
                      color: appTheme.inkDark, size: 24),
                  tooltip: 'Save to device',
                  onPressed: _onSave,
                ),
        ],
      ),
      body: switch (pages) {
        null => const Center(child: CircularProgressIndicator()),
        [] => const Center(child: Text('No content to preview.')),
        _ => PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: pages.length,
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: MemoryImage(pages[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4.0,
              filterQuality: FilterQuality.high,
              // Prevent hero transition conflict
              heroAttributes:
                  PhotoViewHeroAttributes(tag: 'pdf_page_$index'),
            ),
            onPageChanged: (index) =>
                setState(() => _currentPage = index),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration:
                BoxDecoration(color: appTheme.primaryBg),
          ),
      },
    );
  }
}
