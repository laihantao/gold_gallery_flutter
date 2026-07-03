import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../widgets/gold_gradient_card.dart';
import '../widgets/share_card_widget.dart';

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

  double _buybackPct = 0.97;
  double? _manualPrice;
  final TextEditingController _manualPriceController = TextEditingController();
  bool _showMoreDetails = false;
  final ValueNotifier<int> _heroPageIndex = ValueNotifier(0);
  late final PageController _heroPageController;
  late final ScrollController _scrollController;
  final ValueNotifier<bool> _heroCollapsed = ValueNotifier(false);
  double _topPad = 0;

  static const double _expandedHeight = 290.0;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _manualPriceController.dispose();
    _heroPageController.dispose();
    _heroPageIndex.dispose();
    _scrollController.dispose();
    _heroCollapsed.dispose();
    super.dispose();
  }

  void _onScroll() {
    final threshold = _expandedHeight - kToolbarHeight - _topPad;
    final collapsed =
        _scrollController.hasClients && _scrollController.offset > threshold;
    if (_heroCollapsed.value != collapsed) _heroCollapsed.value = collapsed;
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
    final j = jewellery!;
    final sym = currency?.symbol ?? 'RM';

    final isBrandSupported = states.containsKey(j.brand);
    final double? effectivePrice = isBrandSupported
        ? MarketValueService.goldPriceFor(j, states)
        : _manualPrice;
    final String? vendorName = isBrandSupported
        ? MarketValueService.vendorNameFor(j, states)
        : (_manualPrice != null ? j.brand : null);
    final bool hasWeight = j.weight != null && j.weight! > 0;
    _topPad = MediaQuery.of(context).padding.top;
    final topPad = _topPad;

    return Scaffold(
      backgroundColor: appTheme.backgroundPrimary,
      bottomNavigationBar: _buildBottomBar(context, appTheme, l10n),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: _expandedHeight,
            pinned: true,
            backgroundColor: appTheme.primaryDark,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            elevation: 0,
            leading: _frostedCircleButton(
              Icons.chevron_left_rounded,
              () => context.pop(),
            ),
            // Collapsed title — fades in once hero is scrolled away
            title: ValueListenableBuilder<bool>(
              valueListenable: _heroCollapsed,
              builder: (_, collapsed, _) => AnimatedOpacity(
                opacity: collapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  j.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            actions: [
              _frostedCircleButton(
                Icons.ios_share_rounded,
                () => _showShareDialog(context, states, l10n),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildHeroBackground(appTheme, j, topPad),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChipsRow(appTheme, j, l10n),
                  const SizedBox(height: 24),
                  _buildSectionLabel(appTheme, l10n.sectionPurchase),
                  _buildPurchaseCard(appTheme, l10n, j, sym),
                  if (j.remarks?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _buildNotesCard(appTheme, j, l10n),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionLabel(appTheme, l10n.sectionMarketValue),
                  _buildMarketValueHero(
                    appTheme,
                    j,
                    sym,
                    effectivePrice,
                    vendorName,
                    isBrandSupported,
                    hasWeight,
                    l10n,
                  ),
                  if (!isBrandSupported && _manualPrice == null) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [appTheme.cardShadow],
                      ),
                      child: _buildManualPriceInput(appTheme, j, sym, l10n),
                    ),
                  ],
                  if (effectivePrice != null && hasWeight) ...[
                    const SizedBox(height: 12),
                    _buildMarketBreakdownCard(
                      appTheme,
                      j,
                      sym,
                      effectivePrice,
                      l10n,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildCollectionSection(context, appTheme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _frostedCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildHeroBackground(AppTheme appTheme, Jewellery j, double topPad) {
    final photos = j.jewelleryPhoto;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photos.isEmpty)
          Container(
            color: appTheme.primaryDark,
            child: Center(
              child: Icon(
                Icons.diamond_outlined,
                color: Colors.white.withValues(alpha: 0.15),
                size: 72,
              ),
            ),
          )
        else
          _DetailHeroGallery(
            imagePaths: photos,
            pageController: _heroPageController,
            pageIndex: _heroPageIndex,
            onTap: (index) => GoRouter.of(context).push(
              '/photo-viewer',
              extra: {'imagePaths': photos, 'initialIndex': index},
            ),
          ),
        // Dark gradient scrim — non-interactive
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  appTheme.primaryDark.withValues(alpha: 0.33),
                  Colors.transparent,
                  appTheme.primaryDark.withValues(alpha: 0.87),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        // Pagination pill — positioned beside share button, disappears on collapse
        if (photos.length > 1)
          Positioned(
            top: topPad + 10,
            right: 62,
            child: ValueListenableBuilder<int>(
              valueListenable: _heroPageIndex,
              builder: (_, idx, _) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${idx + 1} / ${photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        // Expanded title — lives in background so it has no left-padding constraint
        Positioned(
          bottom: 18,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Text(
              j.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                    color: Color(0x88000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick chips ───────────────────────────────────────────────────────────

  Widget _buildChipsRow(AppTheme appTheme, Jewellery j, AppLocalizations l10n) {
    Widget chip(IconData icon, String label, {bool isGold = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isGold ? appTheme.primaryBg : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isGold
                ? appTheme.primary.withValues(alpha: 0.45)
                : appTheme.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isGold ? appTheme.primary : appTheme.inkMid,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isGold ? appTheme.primaryDark : appTheme.inkDark,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(Icons.local_offer_outlined, j.brand, isGold: true),
        chip(Icons.water_drop_outlined, l10n.purityGoldLabel(j.goldPurity)),
        if (j.weight != null) chip(Icons.shopping_bag_outlined, '${j.weight}g'),
      ],
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(AppTheme appTheme, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: appTheme.inkLight,
        ),
      ),
    );
  }

  // ── Purchase card ─────────────────────────────────────────────────────────

  Widget _buildPurchaseCard(
    AppTheme appTheme,
    AppLocalizations l10n,
    Jewellery j,
    String sym,
  ) {
    Widget row(
      String label,
      String value, {
      bool isHighlight = false,
      bool isFirst = false,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(
                  top: BorderSide(
                    color: appTheme.border.withValues(alpha: 0.4),
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: TextStyle(color: appTheme.inkLight, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value,
                style: TextStyle(
                  color: isHighlight
                      ? appTheme.priceHighlight
                      : appTheme.inkDark,
                  fontSize: isHighlight ? 14 : 12.5,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    final sizeText = j.size != null
        ? [
            j.size.toString(),
            if (j.measurementUnit?.trim().isNotEmpty == true)
              j.measurementUnit!.trim(),
          ].join(' ')
        : null;

    final moreFields = <({String label, String value})>[
      (label: l10n.rowName, value: j.name),
      (label: l10n.rowBrand, value: j.brand),
      (label: l10n.rowPurity, value: l10n.purityGoldLabel(j.goldPurity)),
      if (owner != null) (label: l10n.rowOwner, value: owner!.name),
      if (payer != null) (label: l10n.rowPayer, value: payer!.name),
      if (jewelleryType != null)
        (label: l10n.rowJewelleryType, value: jewelleryType!.name),
      if (sizeText != null) (label: l10n.rowSize, value: sizeText),

      if (currency != null) (label: l10n.rowCurrency, value: currency!.name),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [appTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(
            l10n.rowDateOfPurchase,
            DateFormat('dd MMM yyyy').format(j.date),
            isFirst: true,
          ),
          if (j.purchaseLocation?.isNotEmpty == true)
            row(l10n.rowPurchaseLocation, j.purchaseLocation!),
          if (j.pricePerGram != null)
            row(l10n.rowPricePerGram, '$sym ${j.pricePerGram}'),
          if (j.weight != null) row(l10n.rowWeight, '${j.weight}g'),
          if (j.laborFees != null)
            row(l10n.rowLaborFees, '$sym ${j.laborFees!.toStringAsFixed(2)}'),
          row(
            l10n.rowTotalPrice,
            j.totalPrice != null
                ? '$sym ${j.totalPrice!.toStringAsFixed(2)}'
                : '—',
            isHighlight: j.totalPrice != null,
          ),
          GestureDetector(
            onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: appTheme.border.withValues(alpha: 0.4),
                  ),
                ),
                borderRadius: _showMoreDetails
                    ? BorderRadius.zero
                    : const BorderRadius.only(
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
              ),
              child: Row(
                children: [
                  Text(
                    _showMoreDetails
                        ? l10n.lessDetailsLabel
                        : l10n.moreDetailsLabel,
                    style: TextStyle(
                      color: appTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showMoreDetails
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: appTheme.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_showMoreDetails) ...moreFields.map((f) => row(f.label, f.value)),
          if (_showMoreDetails) const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── Notes card ────────────────────────────────────────────────────────────

  Widget _buildNotesCard(
    AppTheme appTheme,
    Jewellery j,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme.primaryBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: appTheme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: appTheme.primary, size: 14),
              const SizedBox(width: 6),
              Text(
                l10n.notesLabel,
                style: TextStyle(
                  color: appTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            j.remarks!,
            style: TextStyle(
              color: appTheme.textBody,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Market value hero (dark card) ─────────────────────────────────────────

  Widget _buildMarketValueHero(
    AppTheme appTheme,
    Jewellery j,
    String sym,
    double? effectivePrice,
    String? vendorName,
    bool isBrandSupported,
    bool hasWeight,
    AppLocalizations l10n,
  ) {
    final double? currentTotal = (effectivePrice != null && hasWeight)
        ? effectivePrice * j.weight! + (j.laborFees ?? 0)
        : null;
    final double? gainLossVal =
        (currentTotal != null && j.totalPrice != null && j.totalPrice! > 0)
        ? currentTotal - j.totalPrice!
        : null;
    final double? gainLossPctVal =
        (gainLossVal != null && j.totalPrice != null && j.totalPrice! > 0)
        ? gainLossVal / j.totalPrice! * 100
        : null;
    final bool isGain = (gainLossVal ?? 0) >= 0;
    final gainColor = isGain ? appTheme.success : appTheme.error;

    String fmt(double v) => '$sym ${v.toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: goldGradient(appTheme),
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: appTheme.shadow.withValues(alpha: 0.50),
            blurRadius: 18,
            offset: const Offset(0, 7),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: appTheme.primaryDark.withValues(alpha: 0.20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: Stack(
          children: [
            // Top-left shimmer — matches _PortfolioCard style
            const Positioned.fill(
              child: GoldGradientShimmer(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: label + brand/price pill
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.currentMarketValueLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: (!isBrandSupported && _manualPrice != null)
                            ? () => setState(() {
                                _manualPrice = null;
                                _manualPriceController.clear();
                              })
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                vendorName != null && effectivePrice != null
                                    ? (isBrandSupported
                                          ? '$vendorName · ${effectivePrice.toStringAsFixed(0)}/g'
                                          : vendorName)
                                    : j.brand,
                                style: TextStyle(
                                  color: appTheme.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (!isBrandSupported &&
                                  _manualPrice != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 9,
                                  color: appTheme.primaryLight,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Body: value or empty state
                  if (!hasWeight) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.addWeightHint,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ] else if (effectivePrice == null) ...[
                    const SizedBox(height: 16),
                    Text(
                      isBrandSupported
                          ? l10n.fetchPricesHint
                          : l10n.noLiveFeedFor(j.brand),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      fmt(currentTotal!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (gainLossVal != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGain
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: gainColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isGain ? '+' : '-'}$sym ${gainLossVal.abs().toStringAsFixed(2)}'
                                  '${gainLossPctVal != null ? ' (${gainLossPctVal >= 0 ? '+' : ''}${gainLossPctVal.toStringAsFixed(1)}%)' : ''}',
                                  style: TextStyle(
                                    color: gainColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (j.totalPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              l10n.vsPaidLabel(fmt(j.totalPrice!)),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Market breakdown card ─────────────────────────────────────────────────

  Widget _buildMarketBreakdownCard(
    AppTheme appTheme,
    Jewellery j,
    String sym,
    double currentPrice,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [appTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: appTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.marketBreakdownLabel,
                  style: TextStyle(
                    color: appTheme.inkDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: appTheme.border.withValues(alpha: 0.4)),
          _buildPriceTable(appTheme, j, sym, currentPrice, l10n),
          Divider(height: 1, color: appTheme.border.withValues(alpha: 0.4)),
          _buildBuybackEstimator(appTheme, j, sym, currentPrice, l10n),
        ],
      ),
    );
  }

  // ── Manual price input ────────────────────────────────────────────────────

  Widget _buildManualPriceInput(
    AppTheme appTheme,
    Jewellery j,
    String sym,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                color: appTheme.inkLight,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.noLivePriceFeedFor(j.brand),
                  style: TextStyle(color: appTheme.inkLight, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.enterTodayPriceHint(j.goldPurity, sym),
            style: TextStyle(
              color: appTheme.textBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _manualPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: appTheme.inkDark, fontSize: 14),
                  decoration: InputDecoration(
                    prefixText: '$sym ',
                    prefixStyle: TextStyle(
                      color: appTheme.inkMid,
                      fontSize: 14,
                    ),
                    hintText: '0.00',
                    hintStyle: TextStyle(color: appTheme.inkLight),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: appTheme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: appTheme.backgroundPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  final v = double.tryParse(
                    _manualPriceController.text.replaceAll(',', ''),
                  );
                  if (v != null && v > 0) {
                    setState(() => _manualPrice = v);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: appTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.applyLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.estimationOnlyHint,
            style: TextStyle(
              color: appTheme.inkLight,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Price table ───────────────────────────────────────────────────────────

  Widget _buildPriceTable(
    AppTheme appTheme,
    Jewellery j,
    String sym,
    double currentPrice,
    AppLocalizations l10n,
  ) {
    final weight = j.weight!;
    final purchasedPg = j.pricePerGram?.toDouble();
    final currentPg = currentPrice;
    final purchasedTotal = j.totalPrice;
    final currentTotal = currentPg * weight + (j.laborFees ?? 0);
    final pgGainLoss = purchasedPg != null ? currentPg - purchasedPg : null;
    final totalGainLoss = purchasedTotal != null
        ? currentTotal - purchasedTotal
        : null;
    final totalGainLossPct =
        (totalGainLoss != null && purchasedTotal != null && purchasedTotal > 0)
        ? totalGainLoss / purchasedTotal * 100
        : null;
    final hasGainLoss = pgGainLoss != null || totalGainLoss != null;
    final referenceGain = totalGainLoss ?? pgGainLoss;
    final isGain = (referenceGain ?? 0) >= 0;
    final gainColor = isGain ? appTheme.success : appTheme.error;

    String fmt(double? v) => v != null ? '$sym ${v.toStringAsFixed(2)}' : '—';
    String fmtGain(double? v) {
      if (v == null) return '—';
      return '${v >= 0 ? '+' : '-'}$sym ${v.abs().toStringAsFixed(2)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          _MvTableRow(
            label: '',
            perGram: l10n.colPerGram,
            total: l10n.colTotal,
            appTheme: appTheme,
            isHeader: true,
          ),
          const SizedBox(height: 8),
          _MvTableRow(
            label: l10n.mvPurchasedLabel,
            perGram: fmt(purchasedPg),
            total: fmt(purchasedTotal),
            appTheme: appTheme,
            dimmed: purchasedPg == null && purchasedTotal == null,
          ),
          const SizedBox(height: 6),
          _MvTableRow(
            label: l10n.mvCurrentLabel,
            perGram: fmt(currentPg),
            total: fmt(currentTotal),
            appTheme: appTheme,
          ),
          if (hasGainLoss) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isGain
                    ? appTheme.success.withValues(alpha: 0.12)
                    : appTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: label | per-gram change | total change
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            Text(
                              l10n.changeLabel,
                              style: TextStyle(
                                color: gainColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              isGain
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 12,
                              color: gainColor,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          fmtGain(pgGainLoss),
                          style: TextStyle(
                            color: gainColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          fmtGain(totalGainLoss),
                          style: TextStyle(
                            color: gainColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  // Row 2: percentage only (right-aligned)
                  if (totalGainLossPct != null) ...[
                    const SizedBox(height: 3),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${totalGainLossPct >= 0 ? '+' : ''}${totalGainLossPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: gainColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Buyback estimator ─────────────────────────────────────────────────────

  Widget _buildBuybackEstimator(
    AppTheme appTheme,
    Jewellery j,
    String sym,
    double currentPrice,
    AppLocalizations l10n,
  ) {
    final weight = j.weight!;
    final buybackVal = currentPrice * weight * _buybackPct;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.estBuybackLabel,
                style: TextStyle(
                  color: appTheme.textBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$sym ${buybackVal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: appTheme.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Formula: price × weight × payout% (no = result, shown in header)
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 11, color: appTheme.inkMid),
              children: [
                TextSpan(text: '$sym ${currentPrice.toStringAsFixed(2)}'),
                TextSpan(
                  text: ' × ',
                  style: TextStyle(color: appTheme.inkLight),
                ),
                TextSpan(
                  text:
                      '${weight % 1 == 0 ? weight.toStringAsFixed(0) : weight.toStringAsFixed(2)}g',
                ),
                TextSpan(
                  text: ' × ',
                  style: TextStyle(color: appTheme.inkLight),
                ),
                TextSpan(text: '${(_buybackPct * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: appTheme.primary,
                    inactiveTrackColor: appTheme.border.withValues(alpha: 0.6),
                    thumbColor: appTheme.primaryDark,
                    overlayColor: appTheme.primary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _buybackPct,
                    min: 0.80,
                    max: 1.00,
                    divisions: 20,
                    onChanged: (v) => setState(() => _buybackPct = v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Shows deduction %, not payout % (e.g. 3% cut → payout 97%)
              SizedBox(
                width: 42,
                child: Text(
                  '-${((1 - _buybackPct) * 100).toStringAsFixed(0)}%',
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
            l10n.buybackHint,
            style: TextStyle(
              color: appTheme.inkLight,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Collections ───────────────────────────────────────────────────────────

  Widget _buildCollectionSection(BuildContext context, AppTheme appTheme) {
    if (jewellery == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final collectionNotifier = context.watch<CollectionNotifier>();
    final collections = collectionNotifier.collections;
    final jId = jewellery!.id;
    final memberOf = collections
        .where((c) => c.jewelleryIds.contains(jId))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                Icon(Icons.folder_outlined, color: appTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  l10n.collectionsLabel,
                  style: TextStyle(
                    color: appTheme.inkDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showAddToCollectionSheet(
                    context,
                    jId,
                    collectionNotifier,
                    appTheme,
                    l10n,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.primaryLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: appTheme.primaryDark,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l10n.addLabel,
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
                l10n.notInAnyCollectionHint,
                style: TextStyle(
                  color: appTheme.inkLight,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
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
                        label: Text(
                          c.name,
                          style: TextStyle(
                            color: appTheme.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: appTheme.primaryLight,
                        side: BorderSide(
                          color: appTheme.border.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onDeleted: () =>
                            collectionNotifier.removeFromCollection(c.id, jId),
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

  // ── Bottom action bar ─────────────────────────────────────────────────────

  Widget _buildBottomBar(
    BuildContext context,
    AppTheme appTheme,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.primaryBg,
        border: Border(top: BorderSide(color: appTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              Expanded(
                flex: 14,
                child: GestureDetector(
                  onTap: () async {
                    await GoRouter.of(context).push(
                      '/add-product',
                      extra: {'mode': 'edit', 'id': jewellery!.id},
                    );
                    if (!mounted) return;
                    _loadData();
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [appTheme.primary, appTheme.primaryDark],
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Center(
                      child: Text(
                        l10n.editButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 10,
                child: GestureDetector(
                  onTap: () => _showDeleteConfirmation(context, appTheme, l10n),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: appTheme.error, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        l10n.deleteButton,
                        style: TextStyle(
                          color: appTheme.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogs (unchanged) ───────────────────────────────────────────────────

  void _showAddToCollectionSheet(
    BuildContext context,
    int jewelleryId,
    CollectionNotifier collectionNotifier,
    AppTheme appTheme,
    AppLocalizations l10n,
  ) {
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
                    Icon(
                      Icons.folder_outlined,
                      color: appTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.addToCollectionTitle,
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
                    l10n.noCollectionsListingHint,
                    style: TextStyle(color: appTheme.inkLight, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...collectionNotifier.collections.map((c) {
                  final isIn = collectionNotifier.isInCollection(
                    c.id,
                    jewelleryId,
                  );
                  return ListTile(
                    leading: Icon(
                      isIn ? Icons.folder_rounded : Icons.folder_outlined,
                      color: isIn ? appTheme.primary : appTheme.inkMid,
                    ),
                    title: Text(
                      c.name,
                      style: TextStyle(color: appTheme.inkDark, fontSize: 13),
                    ),
                    trailing: isIn
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: appTheme.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () async {
                      if (isIn) {
                        await collectionNotifier.removeFromCollection(
                          c.id,
                          jewelleryId,
                        );
                      } else {
                        await collectionNotifier.addToCollection(
                          c.id,
                          jewelleryId,
                        );
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  );
                }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showShareDialog(
    BuildContext context,
    Map<String, ShopPriceState> states,
    AppLocalizations l10n,
  ) async {
    final sym = currency?.symbol ?? 'RM';
    final shareCardKey = GlobalKey();

    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height - 48,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: shareCardKey,
                    child: ShareCardWidget(
                      jewellery: jewellery!,
                      ownerName: owner?.name,
                      currencySymbol: sym,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: kCertButtonBg,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          child: Text(
                            l10n.cancelButton,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: kCertInkDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            kCertShareGradientTop,
                            kCertShareGradientBottom,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kCertShareGradientBottom.withValues(
                              alpha: 0.55,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            try {
                              final boundary =
                                  shareCardKey.currentContext!
                                          .findRenderObject()!
                                      as RenderRepaintBoundary;
                              final image = await boundary.toImage(
                                pixelRatio: 3.0,
                              );
                              final byteData = await image.toByteData(
                                format: ui.ImageByteFormat.png,
                              );
                              final pngBytes = byteData!.buffer.asUint8List();
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pop();
                              await SharePlus.instance.share(
                                ShareParams(
                                  files: [
                                    XFile.fromData(
                                      pngBytes,
                                      mimeType: 'image/png',
                                      name: 'gold_item.png',
                                    ),
                                  ],
                                  text:
                                      '✦ ${jewellery!.name} — ${l10n.purityGoldLabel(jewellery!.goldPurity)}',
                                ),
                              );
                            } catch (_) {
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.ios_share_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.exportShare,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AppTheme appTheme,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.deleteTitle,
          style: TextStyle(color: appTheme.textHeading),
        ),
        content: Text(
          l10n.deleteConfirm,
          style: TextStyle(color: appTheme.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => GoRouter.of(context).pop(),
            child: Text(
              l10n.cancelButton,
              style: TextStyle(color: appTheme.accentSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              HiveService.deleteJewellery(jewellery!.id);
              GoRouter.of(context).pop();
              GoRouter.of(context).go('/');
            },
            child: Text(
              l10n.deleteButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Market Value table row ────────────────────────────────────────────────────

class _MvTableRow extends StatelessWidget {
  final String label;
  final String perGram;
  final String total;
  final AppTheme appTheme;
  final bool isHeader;
  final bool dimmed;

  const _MvTableRow({
    required this.label,
    required this.perGram,
    required this.total,
    required this.appTheme,
    this.isHeader = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveLabelColor = isHeader
        ? appTheme.inkLight
        : dimmed
        ? appTheme.inkLight
        : appTheme.textBody;
    final Color effectiveValColor = isHeader
        ? appTheme.inkLight
        : appTheme.inkDark;
    final double fontSize = isHeader ? 10.0 : 12.0;
    final FontWeight fontWeight = isHeader
        ? FontWeight.w600
        : FontWeight.normal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              color: effectiveLabelColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            perGram,
            style: TextStyle(
              color: effectiveValColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            total,
            style: TextStyle(
              color: effectiveValColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ── Hero gallery (full-bleed swipeable images for SliverAppBar) ───────────────

class _DetailHeroGallery extends StatefulWidget {
  final List<String> imagePaths;
  final PageController pageController;
  final ValueNotifier<int> pageIndex;
  final void Function(int index)? onTap;

  const _DetailHeroGallery({
    required this.imagePaths,
    required this.pageController,
    required this.pageIndex,
    this.onTap,
  });

  @override
  State<_DetailHeroGallery> createState() => _DetailHeroGalleryState();
}

class _DetailHeroGalleryState extends State<_DetailHeroGallery> {
  final Map<String, Uint8List> _decoded = {};

  @override
  void initState() {
    super.initState();
    _decodeAll();
  }

  Future<void> _decodeAll() async {
    for (final path in widget.imagePaths) {
      if (path.startsWith('assets/') || File(path).existsSync()) continue;
      try {
        final bytes = base64Decode(path);
        if (mounted) setState(() => _decoded[path] = bytes);
      } catch (_) {}
    }
  }

  Widget _buildImage(AppTheme appTheme, String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    final bytes = _decoded[path];
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    if (File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Container(
      color: appTheme.primaryDark,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white.withValues(alpha: 0.2),
          size: 48,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    return PageView.builder(
      controller: widget.pageController,
      onPageChanged: (i) => widget.pageIndex.value = i,
      itemCount: widget.imagePaths.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: widget.onTap != null ? () => widget.onTap!(i) : null,
        child: _buildImage(appTheme, widget.imagePaths[i]),
      ),
    );
  }
}
