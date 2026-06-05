import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';
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
    setState(() {
      _currentImageIndex = _pageController.page?.round() ?? 0;
    });
  }

  void _loadData() {
    jewellery = HiveService.getJewellery(widget.jeweleryId);
    if (jewellery != null) {
      payer = jewellery!.payerId != null ? HiveService.getUser(jewellery!.payerId!) : null;
      owner = jewellery!.ownerId != null ? HiveService.getUser(jewellery!.ownerId!) : null;
      brand = HiveService.getAllBrands().cast<Brand?>().firstWhere(
            (b) => b?.name == jewellery!.brand,
            orElse: () => null,
          );
      jewelleryType = jewellery!.jewelleryTypeId != null
          ? HiveService.getJewelleryType(jewellery!.jewelleryTypeId!)
          : null;
      currency = HiveService.getCurrency(1);
      setState(() {});
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
          child: Text('Jewellery not found', style: TextStyle(color: appTheme.textBody)),
        ),
      );
    }

    return Scaffold(
      appBar: AppHeader(title: jewellery!.name),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo section
            if (jewellery!.jewelleryPhoto != null && jewellery!.jewelleryPhoto!.isNotEmpty)
              Column(
                children: [
                  // Main image viewer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 300,
                      child: GestureDetector(
                        onTap: () {
                          GoRouter.of(context).push(
                            '/photo-viewer',
                            extra: {
                              'imagePaths': jewellery!.jewelleryPhoto!,
                              'initialIndex': _currentImageIndex,
                            },
                          );
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: jewellery!.jewelleryPhoto!.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: appTheme.backgroundSubtle,
                                child: _buildDetailsImageWidget(
                                  jewellery!.jewelleryPhoto![index],
                                  appTheme,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Thumbnail row
                  if (jewellery!.jewelleryPhoto!.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(
                            jewellery!.jewelleryPhoto!.length,
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
                                          : appTheme.borderColor.withValues(alpha: 0.3),
                                      width: _currentImageIndex == index ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildDetailsImageWidget(
                                      jewellery!.jewelleryPhoto![index],
                                      appTheme,
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
                ],
              ),
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
                              extra: {
                                'mode': 'edit',
                                'id': jewellery!.id,
                              },
                            );
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
            child: Text('Cancel', style: TextStyle(color: appTheme.accentSecondary)),
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
    final List<MapEntry<String, String>> rows = [];
    
    // Build row data
    rows.add(MapEntry('Product Name', jewellery!.name));
    rows.add(MapEntry('Purity', jewellery!.goldPurity));
    rows.add(MapEntry('Brand', jewellery!.brand));
    if (jewelleryType != null) rows.add(MapEntry('Type', jewelleryType!.name));
    if (payer != null) rows.add(MapEntry('Payer', payer!.name));
    if (owner != null) rows.add(MapEntry('Owner', owner!.name));
    rows.add(MapEntry('Date of Purchase', '${jewellery!.date.day}/${jewellery!.date.month}/${jewellery!.date.year}'));
    if (jewellery!.weight != null) rows.add(MapEntry('Weight', '${jewellery!.weight} g'));
    if (jewellery!.size != null) rows.add(MapEntry('Size', '${jewellery!.size}'));
    if (jewellery!.measurement != null) rows.add(MapEntry('Measurement Unit', '${jewellery!.measurement}'));
    if (jewellery!.pricePerGram != null) rows.add(MapEntry('Price Per Gram', '${currency?.symbol ?? 'RM'} ${jewellery!.pricePerGram}'));
    if (jewellery!.laborFees != null) rows.add(MapEntry('Labor Fees', '${currency?.symbol ?? 'RM'} ${jewellery!.laborFees}'));
    if (jewellery!.totalPrice != null) rows.add(MapEntry('Total Price', '${currency?.symbol ?? 'RM'} ${jewellery!.totalPrice}'));
    if (jewellery!.purchaseLocation != null) rows.add(MapEntry('Purchase Location', jewellery!.purchaseLocation!));
    if (jewellery!.remarks != null && jewellery!.remarks!.isNotEmpty) rows.add(MapEntry('Remarks', jewellery!.remarks!));

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(6),
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: appTheme.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      children: List.generate(
        rows.length,
        (index) {
          final isAlternate = index % 2 == 1;
          final backgroundColor = isAlternate ? appTheme.backgroundSubtle : appTheme.backgroundSurface;
          
          return TableRow(
            decoration: BoxDecoration(color: backgroundColor),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    rows[index].key,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: appTheme.textBody,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        },
      ),
    );
  }

  Widget _buildDetailsImageWidget(String imagePath, AppTheme appTheme) {
    try {
      // Try to decode as base64 (new format)
      final bytes = base64Decode(imagePath);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
        },
      );
    } catch (e) {
      // If not base64, try to load as file path (legacy format)
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
            },
          );
        }
      } catch (_) {}
      
      return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
    }
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
