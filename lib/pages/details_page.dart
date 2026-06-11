import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';
import '../widgets/jewellery_image_viewer.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
      currency = jewellery!.currencyId != null
          ? HiveService.getCurrency(jewellery!.currencyId!)
          : HiveService.getCurrencyByCode('MYR');
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
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

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
            Padding(
              padding: const EdgeInsets.all(16),
              child: JewelleryImageViewer(
                imagePaths: jewellery!.jewelleryPhoto,
                appTheme: appTheme,
                onImageTap: jewellery!.jewelleryPhoto.isNotEmpty
                    ? (index) {
                        GoRouter.of(context).push(
                          '/photo-viewer',
                          extra: {
                            'imagePaths': jewellery!.jewelleryPhoto,
                            'initialIndex': index,
                          },
                        );
                      }
                    : null,
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
                    color: rows[index].key == 'Total Price'
                        ? appTheme.priceHighlight
                        : appTheme.textHeading,
                    fontSize: rows[index].key == 'Total Price' ? 15 : 12,
                    fontWeight: rows[index].key == 'Total Price'
                        ? FontWeight.w600
                        : FontWeight.normal,
                    letterSpacing:
                        rows[index].key == 'Total Price' ? 0.3 : 0,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

}
