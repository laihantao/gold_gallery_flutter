import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/gold_price.dart';
import '../providers/gold_price_notifier.dart';
import '../services/gold_price_history_service.dart';
import '../theme/app_theme.dart';

// ── Design tokens ────────────────────────────────────────────────────────────

const double _kFooterRowH = 16;
const double _kDeltaRowH = 15; // reserved height for delta badge row

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

  /// True when the prices come from stored history rather than a live fetch
  /// (no live price yet): shown muted, footer shows the date only.
  final bool fromHistory;

  /// Null → refresh icon shown but dimmed and non-tappable (layout consistency).
  final VoidCallback? onRefresh;
  final VoidCallback? onTap;

  /// When non-null, a bell icon appears above the refresh button.
  final VoidCallback? onAlertTap;
  final bool hasActiveAlert;

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
    this.fromHistory = false,
    this.onRefresh,
    this.onTap,
    this.onAlertTap,
    this.hasActiveAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final isStale =
        fromHistory || (isError && (price916 != null || price999 != null));
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
                      onAlertTap: onAlertTap,
                      hasActiveAlert: hasActiveAlert,
                      appTheme: appTheme,
                    ),
                    const SizedBox(height: 10),
                    _PriceColumns(
                      price916: price916,
                      price999: price999,
                      prevPrice916: prevPrice916,
                      prevPrice999: prevPrice999,
                      isLoading: isLoading,
                      isStale: isStale,
                      appTheme: appTheme,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: _kFooterRowH,
                      child: _FooterRow(
                        hasData: price916 != null || price999 != null,
                        isLoading: isLoading,
                        isError: isError,
                        fromHistory: fromHistory,
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

// ── Which price a card shows ─────────────────────────────────────────────────

/// The price a card shows for a shop, plus the point its delta compares with.
class DisplayedPrice {
  final double? price916;
  final double? price999;
  final DateTime? at;

  /// True when the shown price is a stored history point (e.g. synced from
  /// the sheet) rather than the cached live fetch.
  final bool fromHistory;

  /// The history point from the day before [at], for the delta badge; null
  /// when that day has no record (no delta across a gap).
  final GoldPriceHistoryPoint? previous;

  const DisplayedPrice({
    required this.price916,
    required this.price999,
    required this.at,
    required this.fromHistory,
    required this.previous,
  });
}

/// Picks the newest price the app has for a shop: the cached live fetch, or
/// the latest history point when that is from a later day (e.g. the sheet
/// has days this device's live fetch missed). On the same day the live price
/// wins, since it carries the real fetch time.
///
/// The home card and the history page card both use this, so they always
/// show the same price and date.
DisplayedPrice resolveDisplayedPrice(
  GoldPrice? live,
  List<GoldPriceHistoryPoint> history,
) {
  DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  final liveAt = live?.fetchedAt;
  final latest = history.isNotEmpty ? history.last : null;
  final point = latest != null &&
          (liveAt == null ||
              dayOf(latest.recordedAt).isAfter(dayOf(liveAt)))
      ? latest
      : null;
  final at = point != null ? point.recordedAt : liveAt;

  // Compare with the latest point from an earlier day, but only if it is the
  // day right before — otherwise the badge would show a multi-day change.
  GoldPriceHistoryPoint? previous;
  if (at != null) {
    final day = dayOf(at);
    for (var i = history.length - 1; i >= 0; i--) {
      if (dayOf(history[i].recordedAt).isBefore(day)) {
        if (GoldPriceHistoryService.isDayBefore(history[i].recordedAt, at)) {
          previous = history[i];
        }
        break;
      }
    }
  }

  return DisplayedPrice(
    price916: point != null ? point.price916 : live?.price916,
    price999: point != null ? point.price999 : live?.price999,
    at: at,
    fromHistory: point != null,
    previous: previous,
  );
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
  final VoidCallback? onAlertTap;
  final bool hasActiveAlert;

  const GoldPriceCard({
    super.key,
    required this.shopName,
    required this.logoAsset,
    required this.state,
    required this.appTheme,
    this.onRetry,
    this.onTap,
    this.onAlertTap,
    this.hasActiveAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    final resolvedLogo =
        logoAsset.isNotEmpty ? logoAsset : (data?.logoAsset ?? '');
    final shown = resolveDisplayedPrice(
        data, GoldPriceHistoryService.historyFor(shopName));

    return BrandPriceCard(
      shopName: shopName,
      logoAsset: resolvedLogo,
      price916: shown.price916,
      price999: shown.price999,
      prevPrice916: shown.previous?.price916,
      prevPrice999: shown.previous?.price999,
      updatedAt: shown.at,
      isLoading: state.status == GoldPriceStatus.loading,
      isError: state.status == GoldPriceStatus.error,
      errorReason: state.errorReason,
      fromHistory: shown.fromHistory,
      onRefresh: onRetry,
      onTap: onTap,
      onAlertTap: onAlertTap,
      hasActiveAlert: hasActiveAlert,
      appTheme: appTheme,
    );
  }
}

// ── Row 1: Brand name + vertically-stacked bell & refresh buttons ────────────
//
// A fixed-width SizedBox on the left mirrors the action column on the right
// so the shop name text stays truly centred regardless of button state.
// Bell (price alert) sits on top; refresh sits below — both flush right.

class _NameRow extends StatelessWidget {
  final String shopName;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onRefresh;
  final VoidCallback? onAlertTap;
  final bool hasActiveAlert;
  final AppTheme appTheme;

  const _NameRow({
    required this.shopName,
    required this.isLoading,
    required this.isError,
    required this.onRefresh,
    required this.appTheme,
    this.onAlertTap,
    this.hasActiveAlert = false,
  });

  static const double _btnW = 28;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: _btnW), // mirrors the right action column
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
        SizedBox(
          width: _btnW,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onAlertTap != null) ...[
                _buildBellBtn(),
                const SizedBox(height: 4),
              ],
              _buildRefreshBtn(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBellBtn() {
    return GestureDetector(
      onTap: onAlertTap,
      child: Icon(
        hasActiveAlert
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        size: 15,
        color: hasActiveAlert
            ? appTheme.primary
            : appTheme.textBody.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildRefreshBtn() {
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

// ── Rows 2 + 3: Label, price, and delta — one column per karat ───────────────
//
// Each karat type gets a vertical column: label on top, price in the middle,
// and a fixed-height delta row at the bottom. The reserved delta row height
// keeps both columns identical even when only one has a badge, preventing
// the price row from jumping on refresh.

class _PriceColumns extends StatelessWidget {
  final double? price916;
  final double? price999;
  final double? prevPrice916;
  final double? prevPrice999;
  final bool isLoading;
  final bool isStale;
  final AppTheme appTheme;

  const _PriceColumns({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PriceColumn(
            label: '916',
            price: price916,
            prevPrice: prevPrice916,
            priceColor: priceColor,
            mutedColor: mutedColor,
            appTheme: appTheme,
          ),
        ),
        Expanded(
          child: _PriceColumn(
            label: '999',
            price: price999,
            prevPrice: prevPrice999,
            priceColor: priceColor,
            mutedColor: mutedColor,
            appTheme: appTheme,
          ),
        ),
      ],
    );
  }
}

class _PriceColumn extends StatelessWidget {
  final String label;
  final double? price;
  final double? prevPrice;
  final Color priceColor;
  final Color mutedColor;
  final AppTheme appTheme;

  const _PriceColumn({
    required this.label,
    required this.price,
    required this.prevPrice,
    required this.priceColor,
    required this.mutedColor,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = price == null ? '—' : 'RM ${price!.toStringAsFixed(0)}';
    final hasDelta = price != null && prevPrice != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appTheme.textBody.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          priceText,
          style: TextStyle(
            color: priceColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        // Fixed-height slot keeps both columns the same total height.
        SizedBox(
          height: _kDeltaRowH,
          child: hasDelta
              ? Center(
                  child: _DeltaChip(
                    current: price!,
                    previous: prevPrice!,
                    mutedColor: mutedColor,
                    appTheme: appTheme,
                  ),
                )
              : null,
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
  final bool fromHistory;
  final String? errorReason;
  final DateTime? updatedAt;
  final DateFormat stampFmt;
  final AppTheme appTheme;

  // Shorter stamps for the failure line so it fits beside its prefix; history
  // points carry only a date (backfilled ones are pinned to noon).
  static final _failedStampFmt = DateFormat('d MMM yy, HH:mm');
  static final _dateOnlyFmt = DateFormat('d MMM yy');

  const _FooterRow({
    required this.hasData,
    required this.isLoading,
    required this.isError,
    required this.fromHistory,
    required this.errorReason,
    required this.updatedAt,
    required this.stampFmt,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errorStyle = TextStyle(
      color: appTheme.error.withValues(alpha: 0.9),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    if (isError && !hasData) {
      return Center(
        child: Text(
          friendlyPriceError(errorReason, l10n),
          style: errorStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (isLoading || updatedAt == null) return const SizedBox.shrink();

    // A failed refresh that still shows older prices must say so in red, or
    // it looks as if the refresh did nothing.
    if (isError) {
      final stamp =
          (fromHistory ? _dateOnlyFmt : _failedStampFmt).format(updatedAt!);
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          l10n.priceUpdateFailedStale(stamp),
          style: errorStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final label = fromHistory
        ? l10n.priceStalePrefix + _dateOnlyFmt.format(updatedAt!)
        : stampFmt.format(updatedAt!);

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

// ── Error text + refresh result feedback ─────────────────────────────────────

/// Short, user-facing description of a fetch failure reason code.
String friendlyPriceError(String? reason, AppLocalizations l10n) {
  if (reason == 'timeout') return l10n.errTimeout;
  if (reason == 'parse') return l10n.errParse;
  if (reason != null &&
      (reason.startsWith('http_') || reason.startsWith('proxy_'))) {
    return l10n.errUnavailable;
  }
  return l10n.errFetch;
}

/// Shows the outcome of a manual refresh of one shop: its new prices, or why
/// the fetch failed (with the technical detail, e.g. "HTTP 403").
///
/// Takes the messenger and strings rather than a [BuildContext] so it can be
/// called after the refresh's `await` completes.
void showPriceRefreshResult(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  AppTheme appTheme,
  String shopName,
  ShopPriceState state,
) {
  final data = state.data;
  final ok = state.status == GoldPriceStatus.success;

  String rm(double? price) =>
      price == null ? '—' : 'RM${price.toStringAsFixed(0)}';

  showPriceSnackBar(
    messenger,
    appTheme,
    ok
        ? l10n.priceRefreshed(shopName, rm(data?.price916), rm(data?.price999))
        : l10n.priceRefreshFailed(shopName, priceErrorWithDetail(state, l10n)),
    isError: !ok,
  );
}

/// Shows a price refresh snackbar, replacing any one already visible.
/// Success and failure both stay 3 s (swipe to dismiss sooner).
void showPriceSnackBar(
  ScaffoldMessengerState messenger,
  AppTheme appTheme,
  String message, {
  required bool isError,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: isError ? appTheme.error : appTheme.snackBarBg,
        duration: const Duration(seconds: 3),
        content: Text(message),
      ),
    );
}

/// [friendlyPriceError] plus the technical detail in brackets, when known.
String priceErrorWithDetail(ShopPriceState state, AppLocalizations l10n) {
  final reason = state.errorReason;
  final friendly = friendlyPriceError(reason, l10n);
  final extra = state.errorDetail;
  // For HTTP errors also say who answered (e.g. "HTTP 403 · cloudflare ·
  // Just a moment...") so a CDN block is distinguishable from a server error.
  final detail = reason != null && reason.startsWith('http_')
      ? 'HTTP ${reason.substring(5)}'
          '${extra != null && extra.isNotEmpty ? ' · $extra' : ''}'
      : reason != null && reason.startsWith('proxy_')
          ? reason
          : extra;
  return detail == null || detail.isEmpty ? friendly : '$friendly ($detail)';
}

// ── Delta chip ────────────────────────────────────────────────────────────────

class _DeltaChip extends StatelessWidget {
  final double current;
  final double previous;
  final Color mutedColor;
  final AppTheme appTheme;

  const _DeltaChip({
    required this.current,
    required this.previous,
    required this.mutedColor,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;

    if (diff.abs() < 0.5) {
      return Icon(Icons.remove, size: 12, color: mutedColor);
    }

    final up = diff > 0;
    final color = up ? appTheme.success : appTheme.error;
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
