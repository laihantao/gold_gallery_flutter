import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/gold_price_notifier.dart';
import '../services/gold_price_service.dart';
import '../theme/theme_notifier.dart';
import 'gold_price_card.dart';

class GoldPriceSection extends StatelessWidget {
  const GoldPriceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final sources = GoldPriceService.sources;

    return Consumer<GoldPriceNotifier>(
      builder: (context, notifier, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gold Price Today',
                        style: TextStyle(
                          color: appTheme.textHeading,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.04,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap a card to view its price trend',
                        style: TextStyle(
                          color: appTheme.textBody.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh prices',
                  onPressed: notifier.isAnyLoading ? null : notifier.fetchAll,
                  icon: notifier.isAnyLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: appTheme.accentPrimary,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: appTheme.accentSecondary,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                for (var index = 0; index < sources.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  GoldPriceCard(
                    shopName: sources[index].shopName,
                    logoAsset: sources[index].logoAsset,
                    state: notifier.stateFor(sources[index].shopName),
                    appTheme: appTheme,
                    onRetry: () => notifier.retry(sources[index].shopName),
                    onTap: () => context.push(
                      '/gold-history',
                      extra: sources[index].shopName,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
