import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';
import '../widgets/jewellery_image_viewer.dart';

// Enum tag lets the table style rows without comparing translated label strings.
enum _RowTag { regular, totalPrice }

class _DetailRow {
  final String label;
  final String value;
  final _RowTag tag;

  const _DetailRow(this.label, this.value,
      [this.tag = _RowTag.regular]);
}

class DetailsPage extends StatefulWidget {
  final int jeweleryId;

  const DetailsPage({super.key, required this.jeweleryId});

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
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    if (jewellery == null) {
      return Scaffold(
        appBar: AppHeader(title: l10n.detailsTitle),
        body: Center(
          child: Text(
            l10n.jewelleryNotFound,
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
                  _buildDetailsTable(appTheme, l10n),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: l10n.editButton,
                          onPressed: () async {
                            await GoRouter.of(context).push(
                              '/add-product',
                              extra: {'mode': 'edit', 'id': jewellery!.id},
                            );
                            if (!mounted) return;
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GhostButton(
                          label: l10n.deleteButton,
                          onPressed: () =>
                              _showDeleteConfirmation(context, appTheme, l10n),
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

  void _showDeleteConfirmation(
      BuildContext context, AppTheme appTheme, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTitle,
            style: TextStyle(color: appTheme.textHeading)),
        content: Text(l10n.deleteConfirm,
            style: TextStyle(color: appTheme.textBody)),
        actions: [
          TextButton(
            onPressed: () => GoRouter.of(context).pop(),
            child: Text(l10n.cancelButton,
                style: TextStyle(color: appTheme.accentSecondary)),
          ),
          TextButton(
            onPressed: () {
              HiveService.deleteJewellery(jewellery!.id);
              GoRouter.of(context).pop();
              GoRouter.of(context).go('/listing');
            },
            child: Text(l10n.deleteButton,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTable(AppTheme appTheme, AppLocalizations l10n) {
    final sym = currency?.symbol ?? 'RM';

    final sizeText = jewellery!.size != null
        ? [
            jewellery!.size.toString(),
            if (jewellery!.measurementUnit?.trim().isNotEmpty == true)
              jewellery!.measurementUnit!.trim(),
          ].join(' ')
        : '—';

    final rows = <_DetailRow>[
      _DetailRow(l10n.rowName, jewellery!.name),
      _DetailRow(l10n.rowDateOfPurchase,
          DateFormat('dd/MM/yyyy').format(jewellery!.date)),
      _DetailRow(l10n.rowBrand, jewellery!.brand),
      _DetailRow(l10n.rowPurity, jewellery!.goldPurity),
      _DetailRow(l10n.rowOwner, owner?.name ?? '—'),
      _DetailRow(l10n.rowPayer, payer?.name ?? '—'),
      _DetailRow(l10n.rowJewelleryType, jewelleryType?.name ?? '—'),
      _DetailRow(l10n.rowSize, sizeText),
      _DetailRow(l10n.rowCurrency, currency?.name ?? '—'),
      _DetailRow(
        l10n.rowPricePerGram,
        jewellery!.pricePerGram != null
            ? '$sym ${jewellery!.pricePerGram}'
            : '—',
      ),
      _DetailRow(
        l10n.rowWeight,
        jewellery!.weight != null ? '${jewellery!.weight} g' : '—',
      ),
      _DetailRow(
        l10n.rowLaborFees,
        jewellery!.laborFees != null
            ? '$sym ${jewellery!.laborFees!.toStringAsFixed(2)}'
            : '—',
      ),
      _DetailRow(
        l10n.rowTotalPrice,
        jewellery!.totalPrice != null
            ? '$sym ${jewellery!.totalPrice!.toStringAsFixed(2)}'
            : '—',
        _RowTag.totalPrice,
      ),
      _DetailRow(l10n.rowPurchaseLocation,
          jewellery!.purchaseLocation ?? '—'),
      _DetailRow(
        l10n.rowRemarks,
        jewellery!.remarks?.isNotEmpty == true ? jewellery!.remarks! : '—',
      ),
    ];

    return Table(
      columnWidths: const {0: FlexColumnWidth(4), 1: FlexColumnWidth(6)},
      border: TableBorder(
        horizontalInside: BorderSide(
          color: appTheme.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      children: List.generate(rows.length, (index) {
        final row = rows[index];
        final isAlt = index % 2 == 1;
        final isTotalPrice = row.tag == _RowTag.totalPrice;

        return TableRow(
          decoration: BoxDecoration(
            color: isAlt
                ? appTheme.backgroundSubtle
                : appTheme.backgroundSurface,
          ),
          children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Text(
                  row.label,
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
                    horizontal: 12, vertical: 10),
                child: Text(
                  row.value,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: isTotalPrice
                        ? appTheme.priceHighlight
                        : appTheme.textHeading,
                    fontSize: isTotalPrice ? 15 : 12,
                    fontWeight: isTotalPrice
                        ? FontWeight.w600
                        : FontWeight.normal,
                    letterSpacing: isTotalPrice ? 0.3 : 0,
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
