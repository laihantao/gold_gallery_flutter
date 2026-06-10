import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/gold_price_notifier.dart';
import '../theme/app_theme.dart';

class GoldPriceCard extends StatelessWidget {
  final String shopName;
  final String logoAsset;
  final ShopPriceState state;
  final AppTheme appTheme;

  const GoldPriceCard({
    super.key,
    required this.shopName,
    required this.logoAsset,
    required this.state,
    required this.appTheme,
  });

  String _formatPrice(double? price) {
    if (price == null) return '—';
    return 'RM ${price.toStringAsFixed(2)}';
  }

  Widget _buildPriceValue({
    required String label,
    required double? livePrice,
    required double? cachedPrice,
    required bool showError,
    required bool isLoading,
  }) {
    final displayPrice = showError && livePrice == null ? cachedPrice : livePrice;
    final isCachedOnly = showError && livePrice == null && cachedPrice != null;

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: TextStyle(
              color: appTheme.textBody.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? Align(
                    key: const ValueKey('loading'),
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: appTheme.accentPrimary,
                      ),
                    ),
                  )
                : Row(
                    key: ValueKey('$label-$displayPrice-$isCachedOnly'),
                    children: [
                      Expanded(
                        child: Text(
                          _formatPrice(displayPrice),
                          style: TextStyle(
                            color: isCachedOnly
                                ? appTheme.textBody.withValues(alpha: 0.7)
                                : appTheme.priceHighlight,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (showError && livePrice == null)
                        Tooltip(
                          message: state.errorReason ?? 'Failed to fetch',
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: appTheme.accentPrimary,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    final isLoading = state.status == GoldPriceStatus.loading;
    final isError = state.status == GoldPriceStatus.error;
    final fetchedAt = data?.fetchedAt;
    final timeLabel = fetchedAt != null
        ? DateFormat('HH:mm').format(fetchedAt)
        : null;
    final resolvedLogo = logoAsset.isNotEmpty
        ? logoAsset
        : (data?.logoAsset ?? '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: appTheme.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: resolvedLogo.isEmpty
                    ? Icon(
                        Icons.store,
                        size: 36,
                        color: appTheme.accentSecondary,
                      )
                    : Image.asset(
                        resolvedLogo,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.store,
                          size: 36,
                          color: appTheme.accentSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  shopName,
                  style: TextStyle(
                    color: appTheme.textHeading,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isError)
                Icon(
                  Icons.cloud_off_outlined,
                  size: 16,
                  color: appTheme.textBody.withValues(alpha: 0.7),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceValue(
            label: '916',
            livePrice: isError ? null : data?.price916,
            cachedPrice: data?.price916,
            showError: isError,
            isLoading: isLoading,
          ),
          const SizedBox(height: 8),
          _buildPriceValue(
            label: '999',
            livePrice: isError ? null : data?.price999,
            cachedPrice: data?.price999,
            showError: isError,
            isLoading: isLoading,
          ),
          const SizedBox(height: 10),
          if (isError && data != null)
            Text(
              'Last known',
              style: TextStyle(
                color: appTheme.textBody.withValues(alpha: 0.55),
                fontSize: 10,
              ),
            ),
          if (!isLoading && timeLabel != null)
            Text(
              data?.websiteDate != null
                  ? 'Updated $timeLabel · ${data!.websiteDate}'
                  : 'Updated $timeLabel',
              style: TextStyle(
                color: appTheme.textBody.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
