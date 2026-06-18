import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../providers/gold_price_notifier.dart';
import '../services/collection_service.dart';
import '../services/hive_service.dart';
import '../services/market_value_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';
import '../widgets/jewellery_image_viewer.dart';
import '../widgets/share_card_widget.dart';

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

  double _buybackMargin = 0.03;

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

    final notifier = context.watch<GoldPriceNotifier>();
    final states = notifier.allStates;

    return Scaffold(
      appBar: AppHeader(
        title: jewellery!.name,
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: appTheme.inkDark, size: 22),
            tooltip: 'Share',
            onPressed: () => _showShareDialog(context, appTheme, states),
          ),
        ],
      ),
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
                  const SizedBox(height: 16),
                  _buildMarketValueSection(appTheme, states),
                  const SizedBox(height: 16),
                  _buildCollectionSection(context, appTheme),
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

  Widget _buildCollectionSection(BuildContext context, AppTheme appTheme) {
    if (jewellery == null) return const SizedBox.shrink();
    final collectionNotifier = context.watch<CollectionNotifier>();
    final collections = collectionNotifier.collections;
    final jId = jewellery!.id;
    final memberOf =
        collections.where((c) => c.jewelleryIds.contains(jId)).toList();

    return Container(
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appTheme.border),
        boxShadow: [appTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(Icons.folder_outlined,
                    color: appTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Collections',
                  style: TextStyle(
                    color: appTheme.inkDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showAddToCollectionSheet(
                      context, jId, collectionNotifier, appTheme),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            color: appTheme.primaryDark, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: appTheme.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: appTheme.border.withValues(alpha: 0.5)),
          if (memberOf.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Not in any collection yet.',
                style: TextStyle(
                    color: appTheme.inkLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: memberOf
                    .map(
                      (c) => Chip(
                        label: Text(c.name,
                            style: TextStyle(
                                color: appTheme.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        backgroundColor: appTheme.primaryLight,
                        side: BorderSide(
                            color: appTheme.border.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onDeleted: () => collectionNotifier
                            .removeFromCollection(c.id, jId),
                        deleteIconColor: appTheme.inkLight,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddToCollectionSheet(BuildContext context, int jewelleryId,
      CollectionNotifier collectionNotifier, AppTheme appTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: appTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        color: appTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Add to Collection',
                      style: TextStyle(
                        color: appTheme.inkDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: appTheme.border),
              if (collectionNotifier.collections.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No collections yet. Create one from the Listing tab.',
                    style: TextStyle(
                        color: appTheme.inkLight, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...collectionNotifier.collections.map(
                  (c) {
                    final isIn =
                        collectionNotifier.isInCollection(c.id, jewelleryId);
                    return ListTile(
                      leading: Icon(
                        isIn
                            ? Icons.folder_rounded
                            : Icons.folder_outlined,
                        color:
                            isIn ? appTheme.primary : appTheme.inkMid,
                      ),
                      title: Text(c.name,
                          style: TextStyle(
                              color: appTheme.inkDark, fontSize: 13)),
                      trailing: isIn
                          ? Icon(Icons.check_circle_rounded,
                              color: appTheme.primary, size: 20)
                          : null,
                      onTap: () async {
                        if (isIn) {
                          await collectionNotifier.removeFromCollection(
                              c.id, jewelleryId);
                        } else {
                          await collectionNotifier.addToCollection(
                              c.id, jewelleryId);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarketValueSection(
      AppTheme appTheme, Map<String, ShopPriceState> states) {
    final j = jewellery!;
    if (j.weight == null || j.weight! <= 0) return const SizedBox.shrink();

    final currentVal = MarketValueService.currentValue(j, states);
    final gl = MarketValueService.gainLoss(j, states);
    final glPct = MarketValueService.gainLossPct(j, states);
    final vendorName = MarketValueService.bestVendorName(j.goldPurity, states);
    final sym = currency?.symbol ?? 'RM';

    final isGain = (gl ?? 0) >= 0;
    final gainColor = isGain ? const Color(0xFF3DAA3D) : const Color(0xFFCC4444);

    final buybackVal =
        currentVal != null ? currentVal * (1 - _buybackMargin) : null;

    return Container(
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appTheme.border),
        boxShadow: [appTheme.cardShadow],
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(Icons.show_chart_rounded,
                    color: appTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Market Value',
                  style: TextStyle(
                    color: appTheme.inkDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (vendorName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: appTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vendorName,
                      style: TextStyle(
                          color: appTheme.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  Text(
                    'No price data',
                    style: TextStyle(color: appTheme.inkLight, fontSize: 10),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: appTheme.border.withValues(alpha: 0.5)),

          if (currentVal == null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: appTheme.inkLight, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fetch gold prices on the Home tab to see market value.',
                      style: TextStyle(
                          color: appTheme.inkLight,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // ── Value rows ──
            _MvRow(
              label: 'Current Value',
              value: '$sym ${currentVal.toStringAsFixed(2)}',
              valueColor: appTheme.inkDark,
              appTheme: appTheme,
            ),
            if (j.totalPrice != null)
              _MvRow(
                label: 'Purchase Cost',
                value: '$sym ${j.totalPrice!.toStringAsFixed(2)}',
                valueColor: appTheme.inkDark,
                appTheme: appTheme,
              ),
            if (gl != null)
              _MvRow(
                label: 'Gain / Loss',
                value:
                    '${isGain ? '+' : ''}$sym ${gl.toStringAsFixed(2)}  (${glPct != null ? '${isGain ? '+' : ''}${glPct.toStringAsFixed(1)}%' : '—'})',
                valueColor: gainColor,
                prefixIcon: isGain
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                prefixColor: gainColor,
                bold: true,
                appTheme: appTheme,
              ),

            Divider(
                height: 1, color: appTheme.border.withValues(alpha: 0.5)),

            // ── Buyback estimator ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Est. Buyback',
                        style: TextStyle(
                          color: appTheme.textBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        buybackVal != null
                            ? '$sym ${buybackVal.toStringAsFixed(2)}'
                            : '—',
                        style: TextStyle(
                          color: appTheme.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor: appTheme.primary,
                            inactiveTrackColor:
                                appTheme.border.withValues(alpha: 0.6),
                            thumbColor: appTheme.primaryDark,
                            overlayColor:
                                appTheme.primary.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: _buybackMargin,
                            min: 0.0,
                            max: 0.10,
                            divisions: 20,
                            onChanged: (v) =>
                                setState(() => _buybackMargin = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${(_buybackMargin * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: appTheme.inkMid,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Drag to adjust buyback discount margin',
                    style: TextStyle(
                        color: appTheme.inkLight,
                        fontSize: 10,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showShareDialog(BuildContext context, AppTheme appTheme,
      Map<String, ShopPriceState> states) async {
    final gl = MarketValueService.gainLoss(jewellery!, states);
    final glPct = MarketValueService.gainLossPct(jewellery!, states);
    final currentVal = MarketValueService.currentValue(jewellery!, states);
    final sym = currency?.symbol ?? 'RM';

    final shareCardKey = GlobalKey();

    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: shareCardKey,
              child: ShareCardWidget(
                jewellery: jewellery!,
                ownerName: owner?.name,
                currentValue: currentVal,
                gainLoss: gl,
                gainLossPct: glPct,
                currencySymbol: sym,
                appTheme: appTheme,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Share'),
                    onPressed: () async {
                      try {
                        final boundary = shareCardKey.currentContext!
                            .findRenderObject()! as RenderRepaintBoundary;
                        final image =
                            await boundary.toImage(pixelRatio: 3.0);
                        final byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png);
                        final pngBytes = byteData!.buffer.asUint8List();
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [
                              XFile.fromData(pngBytes,
                                  mimeType: 'image/png',
                                  name: 'gold_item.png')
                            ],
                            text:
                                '✦ ${jewellery!.name} — ${jewellery!.goldPurity} gold',
                          ),
                        );
                      } catch (_) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      }
                    },
                  ),
                ),
              ],
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

// ── Market Value row helper ───────────────────────────────────────────────────

class _MvRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final AppTheme appTheme;
  final IconData? prefixIcon;
  final Color? prefixColor;
  final bool bold;

  const _MvRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.appTheme,
    this.prefixIcon,
    this.prefixColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: appTheme.textBody,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, color: prefixColor, size: 14),
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
