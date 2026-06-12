import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/gold_price_notifier.dart';
import '../services/gold_price_history_service.dart';
import '../theme/app_theme.dart';

// ── Design tokens ────────────────────────────────────────────────────────────

const double _kLabelRowH = 18;
const double _kPriceRowH = 30;
const double _kFooterRowH = 16;

// Returns compact values for narrow screens (phones), larger for tablets.
double _logoSize(double screenW) => screenW < 400 ? 48 : 64;
double _logoGap(double screenW) => screenW < 400 ? 10 : 16;
EdgeInsets _cardPadding(double screenW) => screenW < 400
    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
    : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

// ── Shared brand price card ──────────────────────────────────────────────────
//
// Used on both the home page (via [GoldPriceCard]) and the history page
// summary. All layout states (loading / error / success) produce identical
// card dimensions so the surrounding scroll view never jumps.

class BrandPriceCard extends StatelessWidget {
  final String shopName;
  final String logoAsset;

  final double? price916;
  final double? price999;
  final double? prevPrice916;
  final double? prevPrice999;
  final DateTime? updatedAt;

  final bool isLoading;
  final bool isError;
  final String? errorReason;

  /// Null → refresh icon shown but dimmed and non-tappable (layout consistency).
  final VoidCallback? onRefresh;
  final VoidCallback? onTap;
  final AppTheme appTheme;

  static final _stampFmt = DateFormat('d MMMM yy, HH:mm');

  const BrandPriceCard({
    super.key,
    required this.shopName,
    required this.logoAsset,
    required this.appTheme,
    this.price916,
    this.price999,
    this.prevPrice916,
    this.prevPrice999,
    this.updatedAt,
    this.isLoading = false,
    this.isError = false,
    this.errorReason,
    this.onRefresh,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isStale = isError && (price916 != null || price999 != null);
    final screenW = MediaQuery.of(context).size.width;

    return Material(
      color: appTheme.backgroundSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: _cardPadding(screenW),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appTheme.borderColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Logo(
                logo: logoAsset,
                size: _logoSize(screenW),
                fallbackColor: appTheme.accentSecondary,
              ),
              SizedBox(width: _logoGap(screenW)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NameRow(
                      shopName: shopName,
                      isLoading: isLoading,
                      isError: isError,
                      onRefresh: onRefresh,
                      appTheme: appTheme,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: _kLabelRowH,
                      child: _LabelRow(appTheme: appTheme),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: _kPriceRowH,
                      child: _PriceRow(
                        price916: price916,
                        price999: price999,
                        prevPrice916: prevPrice916,
                        prevPrice999: prevPrice999,
                        isLoading: isLoading,
                        isStale: isStale,
                        appTheme: appTheme,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: _kFooterRowH,
                      child: _FooterRow(
                        hasData: price916 != null || price999 != null,
                        isLoading: isLoading,
                        isError: isError,
                        errorReason: errorReason,
                        updatedAt: updatedAt,
                        stampFmt: _stampFmt,
                        appTheme: appTheme,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Home-page convenience wrapper ────────────────────────────────────────────
//
// Converts [ShopPriceState] to [BrandPriceCard] params so callers in
// [GoldPriceSection] don't need to know the internal mapping.

class GoldPriceCard extends StatelessWidget {
  final String shopName;
  final String logoAsset;
  final ShopPriceState state;
  final AppTheme appTheme;
  final VoidCallback? onRetry;
  final VoidCallback? onTap;

  const GoldPriceCard({
    super.key,
    required this.shopName,
    required this.logoAsset,
    required this.state,
    required this.appTheme,
    this.onRetry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    final prev = GoldPriceHistoryService.previousPoint(shopName);
    final resolvedLogo =
        logoAsset.isNotEmpty ? logoAsset : (data?.logoAsset ?? '');

    return BrandPriceCard(
      shopName: shopName,
      logoAsset: resolvedLogo,
      price916: data?.price916,
      price999: data?.price999,
      prevPrice916: prev?.price916,
      prevPrice999: prev?.price999,
      updatedAt: data?.fetchedAt,
      isLoading: state.status == GoldPriceStatus.loading,
      isError: state.status == GoldPriceStatus.error,
      errorReason: state.errorReason,
      onRefresh: onRetry,
      onTap: onTap,
      appTheme: appTheme,
    );
  }
}

// ── Row 1: Brand name + always-visible refresh button ────────────────────────
//
// A fixed-width SizedBox on the left mirrors the refresh button on the right
// so the shop name text stays truly centred regardless of button state.

class _NameRow extends StatelessWidget {
  final String shopName;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onRefresh;
  final AppTheme appTheme;

  const _NameRow({
    required this.shopName,
    required this.isLoading,
    required this.isError,
    required this.onRefresh,
    required this.appTheme,
  });

  static const double _btnW = 28;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: _btnW), // balance weight
        Expanded(
          child: Text(
            shopName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appTheme.textHeading,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        SizedBox(width: _btnW, child: _buildBtn()),
      ],
    );
  }

  Widget _buildBtn() {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: appTheme.accentPrimary,
          ),
        ),
      );
    }

    final color = isError
        ? appTheme.accentPrimary
        : appTheme.textBody.withValues(
            alpha: onRefresh != null ? 0.35 : 0.15,
          );

    return GestureDetector(
      onTap: onRefresh,
      child: Icon(Icons.refresh_rounded, size: 17, color: color),
    );
  }
}

// ── Row 2: "916" / "999" labels ──────────────────────────────────────────────

class _LabelRow extends StatelessWidget {
  final AppTheme appTheme;
  const _LabelRow({required this.appTheme});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: appTheme.textBody.withValues(alpha: 0.65),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    );
    return Row(
      children: [
        Expanded(child: Center(child: Text('916', style: style))),
        Expanded(child: Center(child: Text('999', style: style))),
      ],
    );
  }
}

// ── Row 3: Prices ────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final double? price916;
  final double? price999;
  final double? prevPrice916;
  final double? prevPrice999;
  final bool isLoading;
  final bool isStale;
  final AppTheme appTheme;

  const _PriceRow({
    required this.price916,
    required this.price999,
    required this.prevPrice916,
    required this.prevPrice999,
    required this.isLoading,
    required this.isStale,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Row(
        children: [
          Expanded(child: _Spinner(color: appTheme.accentPrimary)),
          Expanded(child: _Spinner(color: appTheme.accentPrimary)),
        ],
      );
    }

    final priceColor = isStale
        ? appTheme.textBody.withValues(alpha: 0.6)
        : appTheme.priceHighlight;
    final mutedColor = appTheme.textBody.withValues(alpha: 0.5);

    return Row(
      children: [
        Expanded(
          child: _PriceCell(
            price: price916,
            prevPrice: prevPrice916,
            priceColor: priceColor,
            mutedColor: mutedColor,
          ),
        ),
        Expanded(
          child: _PriceCell(
            price: price999,
            prevPrice: prevPrice999,
            priceColor: priceColor,
            mutedColor: mutedColor,
          ),
        ),
      ],
    );
  }
}

// ── Row 4: Footer ─────────────────────────────────────────────────────────────

class _FooterRow extends StatelessWidget {
  final bool hasData;
  final bool isLoading;
  final bool isError;
  final String? errorReason;
  final DateTime? updatedAt;
  final DateFormat stampFmt;
  final AppTheme appTheme;

  const _FooterRow({
    required this.hasData,
    required this.isLoading,
    required this.isError,
    required this.errorReason,
    required this.updatedAt,
    required this.stampFmt,
    required this.appTheme,
  });

  String _friendlyError(String? reason) {
    if (reason == 'timeout') return 'Request timed out';
    if (reason == 'parse') return 'Could not read price';
    if (reason != null &&
        (reason.startsWith('http_') || reason.startsWith('proxy_'))) {
      return 'Site unavailable';
    }
    return 'Fetch failed';
  }

  @override
  Widget build(BuildContext context) {
    if (isError && !hasData) {
      return Center(
        child: Text(
          _friendlyError(errorReason),
          style: TextStyle(
            color: const Color(0xFFE06666).withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (isLoading || updatedAt == null) return const SizedBox.shrink();

    final label = (isError ? 'Last · ' : '') + stampFmt.format(updatedAt!);

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        style: TextStyle(
          color: appTheme.textBody.withValues(alpha: 0.45),
          fontSize: 10.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Price cell ────────────────────────────────────────────────────────────────
//
// The price text is always centred in its column via a [Stack].
// The delta badge is anchored to the right edge so it never shifts the price.

class _PriceCell extends StatelessWidget {
  final double? price;
  final double? prevPrice;
  final Color priceColor;
  final Color mutedColor;

  const _PriceCell({
    required this.price,
    required this.prevPrice,
    required this.priceColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final priceText =
        price == null ? '—' : 'RM ${price!.toStringAsFixed(0)}';
    final hasDelta = price != null && prevPrice != null;

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          priceText,
          style: TextStyle(
            color: priceColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hasDelta)
          Align(
            alignment: Alignment.centerRight,
            child: _DeltaChip(
              current: price!,
              previous: prevPrice!,
              mutedColor: mutedColor,
            ),
          ),
      ],
    );
  }
}

// ── Delta chip ────────────────────────────────────────────────────────────────

class _DeltaChip extends StatelessWidget {
  final double current;
  final double previous;
  final Color mutedColor;

  const _DeltaChip({
    required this.current,
    required this.previous,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;

    if (diff.abs() < 0.5) {
      return Icon(Icons.remove, size: 12, color: mutedColor);
    }

    final up = diff > 0;
    final color =
        up ? const Color(0xFF3FB66E) : const Color(0xFFE06666);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 11,
          color: color,
        ),
        Text(
          'RM${diff.abs().toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final String logo;
  final double size;
  final Color fallbackColor;

  const _Logo({
    required this.logo,
    required this.size,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: logo.isEmpty
          ? Icon(Icons.store, size: size, color: fallbackColor)
          : Image.asset(
              logo,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.store, size: size, color: fallbackColor),
            ),
    );
  }
}

// ── Spinner ───────────────────────────────────────────────────────────────────

class _Spinner extends StatelessWidget {
  final Color color;
  const _Spinner({required this.color});

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      );
}
