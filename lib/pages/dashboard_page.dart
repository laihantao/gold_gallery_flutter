import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../painters/bg_pattern_painter.dart';
import '../services/hive_service.dart';
import '../widgets/jewellery_type_icon.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';

class DashboardPage extends StatefulWidget {
  final int refreshNonce;

  const DashboardPage({super.key, this.refreshNonce = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late _DashboardData _data;

  @override
  void initState() {
    super.initState();
    _data = _DashboardData.load();
  }

  @override
  void didUpdateWidget(DashboardPage old) {
    super.didUpdateWidget(old);
    if (old.refreshNonce != widget.refreshNonce) _reload();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _data = _DashboardData.load());
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(title: l10n.dashboardTitle, showBackButton: false),
      body: PatternedBackground(
        patternColor: appTheme.patternColor,
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          color: appTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Portfolio Summary ──────────────────────────
                _PortfolioCard(data: _data, appTheme: appTheme, l10n: l10n),
                const SizedBox(height: 24),

                // ── By Jewellery Type ──────────────────────────
                _SectionHeader(
                    title: l10n.byJewelleryType, appTheme: appTheme, l10n: l10n),
                const SizedBox(height: 12),
                if (_data.typeStats.isEmpty)
                  _EmptyHint(l10n.noItemsYet, appTheme, l10n)
                else
                  _TypeGrid(
                    stats: _data.typeStats,
                    appTheme: appTheme,
                    l10n: l10n,
                    onTap: (type) async {
                      // Pass English name for routing so the listing page
                      // can resolve to the correct type regardless of locale.
                      await GoRouter.of(context)
                          .push('/listing', extra: {'type': type.name});
                      if (!mounted) return;
                      _reload();
                    },
                  ),
                const SizedBox(height: 24),

                // ── By Owner ───────────────────────────────────
                if (_data.ownerStats.isNotEmpty) ...[
                  _SectionHeader(
                      title: l10n.byOwner, appTheme: appTheme, l10n: l10n),
                  const SizedBox(height: 12),
                  ..._data.ownerStats.map(
                    (stat) => _OwnerRow(
                      stat: stat,
                      appTheme: appTheme,
                      currencySymbol: _data.currencySymbol,
                      l10n: l10n,
                      onTap: () async {
                        await GoRouter.of(context).push(
                          '/listing',
                          extra: {'owner': stat.ownerId.toString()},
                        );
                        if (!mounted) return;
                        _reload();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Recently Added ─────────────────────────────
                if (_data.recentItems.isNotEmpty) ...[
                  _SectionHeader(
                      title: l10n.recentlyAdded, appTheme: appTheme, l10n: l10n),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _data.recentItems.length,
                      itemBuilder: (context, index) => _RecentCard(
                        item: _data.recentItems[index],
                        currencySymbol: _data.currencySymbol,
                        appTheme: appTheme,
                        l10n: l10n,
                        onTap: () async {
                          await GoRouter.of(context).push(
                            '/details',
                            extra: _data.recentItems[index].id,
                          );
                          if (!mounted) return;
                          _reload();
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _TypeStat {
  final JewelleryType type;
  final int count;
  final double totalValue;

  const _TypeStat({
    required this.type,
    required this.count,
    required this.totalValue,
  });
}

class _OwnerStat {
  final int ownerId;
  final String ownerName;
  final int count;
  final double totalValue;

  const _OwnerStat({
    required this.ownerId,
    required this.ownerName,
    required this.count,
    required this.totalValue,
  });
}

class _DashboardData {
  final int totalItems;
  final double totalValue;
  final String currencySymbol;
  final List<_TypeStat> typeStats;
  final List<_OwnerStat> ownerStats;
  final List<Jewellery> recentItems;

  const _DashboardData({
    required this.totalItems,
    required this.totalValue,
    required this.currencySymbol,
    required this.typeStats,
    required this.ownerStats,
    required this.recentItems,
  });

  factory _DashboardData.load() {
    final items = HiveService.getAllJewellery();
    final types = HiveService.getAllJewelleryTypes();
    final users = HiveService.getAllUsers();
    final currencySymbol =
        HiveService.getCurrencyByCode('MYR')?.symbol ?? 'RM';

    final totalValue =
        items.fold<double>(0, (s, j) => s + (j.totalPrice ?? 0));

    final typeStats = types.map((t) {
      final typeItems = items.where((j) => j.jewelleryTypeId == t.id).toList();
      return _TypeStat(
        type: t,
        count: typeItems.length,
        totalValue: typeItems.fold(0, (s, j) => s + (j.totalPrice ?? 0)),
      );
    }).toList();

    final ownerStats = users.map((u) {
      final owned = items.where((j) => j.ownerId == u.id).toList();
      return _OwnerStat(
        ownerId: u.id,
        ownerName: u.name,
        count: owned.length,
        totalValue: owned.fold(0, (s, j) => s + (j.totalPrice ?? 0)),
      );
    }).where((s) => s.count > 0).toList();

    final sorted = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = sorted.take(5).toList();

    return _DashboardData(
      totalItems: items.length,
      totalValue: totalValue,
      currencySymbol: currencySymbol,
      typeStats: typeStats,
      ownerStats: ownerStats,
      recentItems: recent,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final AurumTheme appTheme;
  final AppLocalizations l10n;

  const _SectionHeader(
      {required this.title, required this.appTheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTextStyles.headline(appTheme.inkDark, locale: l10n.locale));
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  final AurumTheme appTheme;
  final AppLocalizations l10n;

  const _EmptyHint(this.message, this.appTheme, this.l10n);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child:
          Text(message, style: AppTextStyles.handNote(appTheme.inkLight)),
    );
  }
}

// ── Portfolio summary card ────────────────────────────────────────────────────

class _PortfolioCard extends StatelessWidget {
  final _DashboardData data;
  final AurumTheme appTheme;
  final AppLocalizations l10n;

  const _PortfolioCard(
      {required this.data, required this.appTheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final highlight = Color.lerp(appTheme.primary, Colors.white, 0.20)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appTheme.primaryDark,
            appTheme.primary,
            highlight,
            appTheme.primaryDark.withValues(alpha: 0.90),
          ],
          stops: const [0.0, 0.38, 0.62, 1.0],
        ),
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.portfolioOverview,
                    style: AppTextStyles.title(
                        Colors.white.withValues(alpha: 0.85),
                        locale: l10n.locale),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          label: l10n.totalItems,
                          value: '${data.totalItems}',
                          icon: Icons.diamond_outlined,
                          l10n: l10n,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _StatBlock(
                          label: l10n.portfolioValue,
                          value:
                              '${data.currencySymbol} ${data.totalValue.toStringAsFixed(2)}',
                          icon: Icons.account_balance_wallet_outlined,
                          alignRight: true,
                          l10n: l10n,
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
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool alignRight;
  final AppLocalizations l10n;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.l10n,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 16 : 0,
        right: alignRight ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: alignRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!alignRight) ...[
                Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: l10n.isZhCN ? 10 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (alignRight) ...[
                const SizedBox(width: 4),
                Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Type grid ────────────────────────────────────────────────────────────────

class _TypeGrid extends StatelessWidget {
  final List<_TypeStat> stats;
  final AurumTheme appTheme;
  final AppLocalizations l10n;
  final void Function(JewelleryType type) onTap;

  const _TypeGrid({
    required this.stats,
    required this.appTheme,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 500 ? 3 : 2;
        const gap = 12.0;
        final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats.map((stat) {
            final dimmed = stat.count == 0;
            final displayName = stat.type.localizedName(l10n.locale);
            return GestureDetector(
              onTap: dimmed ? null : () => onTap(stat.type),
              child: Container(
                width: cardW,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: appTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dimmed
                        ? appTheme.border.withValues(alpha: 0.5)
                        : appTheme.border,
                    width: 1,
                  ),
                  boxShadow: [appTheme.cardShadow],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: dimmed
                            ? appTheme.primaryLight.withValues(alpha: 0.4)
                            : appTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: JewelleryTypeIcon(
                          iconKey: stat.type.iconKey,
                          size: 36,
                          tintColor: dimmed
                              ? appTheme.primary.withValues(alpha: 0.4)
                              : appTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      style: AppTextStyles.title(
                        dimmed
                            ? appTheme.inkDark.withValues(alpha: 0.4)
                            : appTheme.inkDark,
                        locale: l10n.locale,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.itemCount(stat.count),
                      style: AppTextStyles.caption(
                        dimmed
                            ? appTheme.inkLight.withValues(alpha: 0.5)
                            : appTheme.inkLight,
                        locale: l10n.locale,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Owner row ────────────────────────────────────────────────────────────────

class _OwnerRow extends StatelessWidget {
  final _OwnerStat stat;
  final AurumTheme appTheme;
  final String currencySymbol;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _OwnerRow({
    required this.stat,
    required this.appTheme,
    required this.currencySymbol,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        stat.ownerName.isNotEmpty ? stat.ownerName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appTheme.border, width: 1),
          boxShadow: [appTheme.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appTheme.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: appTheme.primary, width: 1.2),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: appTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat.ownerName,
                      style: AppTextStyles.title(appTheme.inkDark,
                          locale: l10n.locale)),
                  const SizedBox(height: 2),
                  Text(
                    '$currencySymbol ${stat.totalValue.toStringAsFixed(2)}',
                    style: AppTextStyles.priceSmall(appTheme.primaryDark),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: appTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.itemCount(stat.count),
                style: TextStyle(
                  color: appTheme.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_outlined,
                color: appTheme.inkLight, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Recent item card ─────────────────────────────────────────────────────────

class _RecentCard extends StatelessWidget {
  final Jewellery item;
  final String currencySymbol;
  final AurumTheme appTheme;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _RecentCard({
    required this.item,
    required this.currencySymbol,
    required this.appTheme,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = item.jewelleryPhoto.isNotEmpty;
    final price = item.totalPrice ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appTheme.border, width: 1),
          boxShadow: [appTheme.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: hasPhoto
                    ? _Thumb(base64: item.jewelleryPhoto.first)
                    : Container(
                        color: appTheme.primaryLight,
                        child: Icon(
                          Icons.diamond_outlined,
                          color: appTheme.primary,
                          size: 28,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.isNotEmpty ? item.name : l10n.untitled,
                      style: AppTextStyles.caption(appTheme.inkDark,
                              locale: l10n.locale)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '$currencySymbol ${price.toStringAsFixed(0)}',
                      style: AppTextStyles.caption(appTheme.primaryDark,
                              locale: l10n.locale)
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String base64;
  const _Thumb({required this.base64});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(base64);
      return Image.memory(bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, _) =>
              const Center(child: Icon(Icons.broken_image_outlined)));
    } catch (_) {
      return const Center(child: Icon(Icons.broken_image_outlined));
    }
  }
}
