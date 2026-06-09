import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';

class DetailsPage extends StatefulWidget {
  final int jeweleryId;

  const DetailsPage({Key? key, required this.jeweleryId}) : super(key: key);

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  Jewellery? jewellery;
  User? payer;
  User? owner;
  Brand? brand;
  JewelleryType? jewelleryType;
  Currency? currency;
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (!mounted) return;
    setState(() {
      _currentImageIndex = _pageController.page?.round() ?? 0;
    });
  }

  void _loadData() {
    jewellery = HiveService.getJewellery(widget.jeweleryId);
    if (jewellery != null) {
      payer = jewellery!.payerId != null
          ? HiveService.getUser(jewellery!.payerId!)
          : null;
      owner = jewellery!.ownerId != null
          ? HiveService.getUser(jewellery!.ownerId!)
          : null;
      brand = HiveService.getAllBrands().cast<Brand?>().firstWhere(
        (b) => b?.name == jewellery!.brand,
        orElse: () => null,
      );
      jewelleryType = jewellery!.jewelleryTypeId != null
          ? HiveService.getJewelleryType(jewellery!.jewelleryTypeId!)
          : null;
      currency = HiveService.getCurrency(1);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _refreshData() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = _getAppTheme(context);

    if (jewellery == null) {
      return Scaffold(
        appBar: AppHeader(title: 'Details'),
        body: Center(
          child: Text(
            'Jewellery not found',
            style: TextStyle(color: appTheme.textBody),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppHeader(title: jewellery!.name),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fix: Image section - Always render, with fallback for no images
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 300,
                child: GestureDetector(
                  onTap: jewellery!.jewelleryPhoto.isNotEmpty
                      ? () {
                          GoRouter.of(context).push(
                            '/photo-viewer',
                            extra: {
                              'imagePaths': jewellery!.jewelleryPhoto,
                              'initialIndex': _currentImageIndex,
                            },
                          );
                        }
                      : null,
                  child: jewellery!.jewelleryPhoto.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: jewellery!.jewelleryPhoto.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: appTheme.backgroundSubtle,
                                child: _buildDetailsImageWidget(
                                  jewellery!.jewelleryPhoto[index],
                                  appTheme,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: appTheme.backgroundSubtle,
                            child: Image.asset(
                              'assets/images/defaults/default_jewellery.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image,
                                    color: appTheme.accentSecondary,
                                    size: 80,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // Fix: Thumbnail row only shows if images exist
            if (jewellery!.jewelleryPhoto.isNotEmpty &&
                jewellery!.jewelleryPhoto.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(
                      jewellery!.jewelleryPhoto.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentImageIndex == index
                                    ? appTheme.accentPrimary
                                    : appTheme.borderColor.withValues(
                                        alpha: 0.3,
                                      ),
                                width: _currentImageIndex == index ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildDetailsImageWidget(
                                jewellery!.jewelleryPhoto[index],
                                appTheme,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailsTable(appTheme),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Edit',
                          onPressed: () async {
                            await GoRouter.of(context).push(
                              '/add-product',
                              extra: {'mode': 'edit', 'id': jewellery!.id},
                            );
                            // Fix: Added mounted check to prevent setState after deactivation
                            if (!mounted) return;
                            _refreshData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GhostButton(
                          label: 'Delete',
                          onPressed: () {
                            _showDeleteConfirmation(context, appTheme);
                          },
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
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppTheme appTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Jewellery',
          style: TextStyle(color: appTheme.textHeading),
        ),
        content: Text(
          'Are you sure you want to delete this jewellery?',
          style: TextStyle(color: appTheme.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => GoRouter.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: appTheme.accentSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              HiveService.deleteJewellery(jewellery!.id);
              GoRouter.of(context).pop();
              GoRouter.of(context).go('/listing');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  AppTheme _getAppTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
    if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
    if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
    return AppTheme.gold;
  }

  Widget _buildDetailsTable(AppTheme appTheme) {
    // Fix: Reordered fields to match required sequence and show dashes for empty values
    final List<MapEntry<String, String>> rows = [];
    final sizeText = jewellery!.size != null
        ? [
            jewellery!.size.toString(),
            if (jewellery!.measurementUnit?.trim().isNotEmpty == true)
              jewellery!.measurementUnit!.trim(),
          ].join(' ')
        : '—';

    // Build row data in correct order
    rows.add(MapEntry('Name', jewellery!.name));
    rows.add(
      MapEntry(
        'Date of Purchase',
        DateFormat('dd/MM/yyyy').format(jewellery!.date),
      ),
    );
    rows.add(MapEntry('Brand', jewellery!.brand));
    rows.add(MapEntry('Purity', jewellery!.goldPurity));
    rows.add(MapEntry('Owner', owner?.name ?? '—'));
    rows.add(MapEntry('Payer', payer?.name ?? '—'));
    rows.add(MapEntry('Jewellery Type', jewelleryType?.name ?? '—'));
    rows.add(MapEntry('Size', sizeText));
    rows.add(MapEntry('Currency', currency?.name ?? '—'));
    rows.add(
      MapEntry(
        'Price Per Gram',
        jewellery!.pricePerGram != null
            ? '${currency?.symbol ?? 'RM'} ${jewellery!.pricePerGram}'
            : '—',
      ),
    );
    rows.add(
      MapEntry(
        'Weight',
        jewellery!.weight != null ? '${jewellery!.weight} g' : '—',
      ),
    );
    rows.add(
      MapEntry(
        'Labor Fees',
        jewellery!.laborFees != null
            ? '${currency?.symbol ?? 'RM'} ${jewellery!.laborFees}'
            : '—',
      ),
    );
    rows.add(
      MapEntry(
        'Total Price',
        jewellery!.totalPrice != null
            ? '${currency?.symbol ?? 'RM'} ${jewellery!.totalPrice}'
            : '—',
      ),
    );
    rows.add(MapEntry('Purchase Location', jewellery!.purchaseLocation ?? '—'));
    rows.add(
      MapEntry(
        'Remarks',
        jewellery!.remarks?.isNotEmpty == true ? jewellery!.remarks! : '—',
      ),
    );

    return Table(
      columnWidths: const {0: FlexColumnWidth(4), 1: FlexColumnWidth(6)},
      border: TableBorder(
        horizontalInside: BorderSide(
          color: appTheme.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      children: List.generate(rows.length, (index) {
        final isAlternate = index % 2 == 1;
        final backgroundColor = isAlternate
            ? appTheme.backgroundSubtle
            : appTheme.backgroundSurface;

        return TableRow(
          decoration: BoxDecoration(color: backgroundColor),
          children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  rows[index].key,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: appTheme.textBody,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  rows[index].value,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: appTheme.textHeading,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Uint8List? _decodeBase64ImageBytes(String imagePath) {
    final source = imagePath.trim();
    final commaIndex = source.indexOf(',');
    final payload = source.startsWith('data:image') && commaIndex >= 0
        ? source.substring(commaIndex + 1)
        : source;

    if (payload.length < 100 ||
        payload.startsWith('file:') ||
        payload.contains(r'\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(payload)) {
      return null;
    }

    if (payload.startsWith('/') && !payload.startsWith('/9j/')) {
      return null;
    }

    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  Widget _buildDetailsImageWidget(
    String imagePath,
    AppTheme appTheme, {
    BoxFit fit = BoxFit.cover,
  }) {
    // Fix: Check if path is an asset first
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
        },
      );
    }

    final bytes = _decodeBase64ImageBytes(imagePath);
    if (bytes != null) {
      return SizedBox.expand(
        child: Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
          },
        ),
      );
    }

    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return SizedBox.expand(
          child: Image.file(
            file,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.image,
                color: appTheme.accentSecondary,
                size: 48,
              );
            },
          ),
        );
      }
    } catch (_) {}

    return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final AppTheme appTheme;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.appTheme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: appTheme.accentPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? appTheme.textHeading,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
