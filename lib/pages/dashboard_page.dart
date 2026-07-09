import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../painters/bg_pattern_painter.dart';
import '../services/hive_service.dart';
import '../widgets/gold_gradient_card.dart';
import '../widgets/jewellery_type_icon.dart';
import '../widgets/money_text.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import 'main_shell_page.dart';

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
      appBar: AppHeader(
        title: l10n.dashboardTitle,
        showBackButton: false,
        actions: [PrivacyToggleButton(color: appTheme.inkDark)],
      ),
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
                const SizedBox(height: 10),
                _PortfolioTrendButton(appTheme: appTheme, l10n: l10n),
                const SizedBox(height: 24),

                // ── Recently Added ─────────────────────────────
                if (_data.recentItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.recentlyAdded,
                    appTheme: appTheme,
                    l10n: l10n,
                  ),
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
                  const SizedBox(height: 24),
                ],

                // ── Breakdown donut ────────────────────────────
                if (_data.totalItems > 0) ...[
                  _BreakdownSection(
                    typeStats: _data.typeStats,
                    ownerStats: _data.ownerStats,
                    currencySymbol: _data.currencySymbol,
                    totalItems: _data.totalItems,
                    appTheme: appTheme,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── By Jewellery Type ──────────────────────────
                _SectionHeader(
                  title: l10n.byJewelleryType,
                  appTheme: appTheme,
                  l10n: l10n,
                ),
                const SizedBox(height: 12),
                if (_data.typeStats.isEmpty)
                  _EmptyHint(l10n.noItemsYet, appTheme, l10n)
                else
                  _TypeGrid(
                    stats: _data.typeStats,
                    appTheme: appTheme,
                    l10n: l10n,
                    onTap: (type) {
                      // Pass English name for routing so the listing page
                      // can resolve to the correct type regardless of locale.
                      TabScope.of(context)?.switchTab(3, filterType: type.name);
                    },
                  ),
                const SizedBox(height: 24),

                // ── By Owner ───────────────────────────────────
                if (_data.ownerStats.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.byOwner,
                    appTheme: appTheme,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  ..._data.ownerStats.map(
                    (stat) => _OwnerRow(
                      stat: stat,
                      appTheme: appTheme,
                      currencySymbol: _data.currencySymbol,
                      l10n: l10n,
                      onTap: () {
                        TabScope.of(
                          context,
                        )?.switchTab(3, filterOwnerId: stat.ownerId.toString());
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
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
  final List<Jewellery> allItems;

  const _DashboardData({
    required this.totalItems,
    required this.totalValue,
    required this.currencySymbol,
    required this.typeStats,
    required this.ownerStats,
    required this.recentItems,
    required this.allItems,
  });

  factory _DashboardData.load() {
    final items = HiveService.getAllJewellery();
    final types = HiveService.getAllJewelleryTypes();
    final users = HiveService.getAllUsers();
    final currencySymbol = HiveService.getCurrencyByCode('MYR')?.symbol ?? 'RM';

    final totalValue = items.fold<double>(0, (s, j) => s + (j.totalPrice ?? 0));

    final typeStats = types.map((t) {
      final typeItems = items.where((j) => j.jewelleryTypeId == t.id).toList();
      return _TypeStat(
        type: t,
        count: typeItems.length,
        totalValue: typeItems.fold(0, (s, j) => s + (j.totalPrice ?? 0)),
      );
    }).toList();

    final ownerStats = users
        .map((u) {
          final owned = items.where((j) => j.ownerId == u.id).toList();
          return _OwnerStat(
            ownerId: u.id,
            ownerName: u.name,
            count: owned.length,
            totalValue: owned.fold(0, (s, j) => s + (j.totalPrice ?? 0)),
          );
        })
        .where((s) => s.count > 0)
        .toList();

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
      allItems: items,
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

  const _SectionHeader({
    required this.title,
    required this.appTheme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.headline(appTheme.inkDark, locale: l10n.locale),
    );
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
      child: Text(message, style: AppTextStyles.handNote(appTheme.inkLight)),
    );
  }
}

// ── Portfolio summary card ────────────────────────────────────────────────────

class _PortfolioCard extends StatelessWidget {
  final _DashboardData data;
  final AurumTheme appTheme;
  final AppLocalizations l10n;

  const _PortfolioCard({
    required this.data,
    required this.appTheme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: goldGradient(appTheme),
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
            const Positioned.fill(
              child: GoldGradientShimmer(),
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
                      locale: l10n.locale,
                    ),
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
                          sensitive: true,
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

class _PortfolioTrendButton extends StatelessWidget {
  final AurumTheme appTheme;
  final AppLocalizations l10n;
  const _PortfolioTrendButton({required this.appTheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/portfolio-chart'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appTheme.border),
          boxShadow: [appTheme.cardShadow],
        ),
        child: Row(
          children: [
            Icon(Icons.show_chart_rounded, color: appTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.viewPortfolioTrend,
              style: TextStyle(
                color: appTheme.inkDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: appTheme.inkLight,
              size: 20,
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
  final bool sensitive;
  final AppLocalizations l10n;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.l10n,
    this.alignRight = false,
    this.sensitive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 16 : 0,
        right: alignRight ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: alignRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!alignRight) ...[
                Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 14,
                ),
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
                Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 14,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (sensitive)
            MoneyText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            )
          else
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

// ── Breakdown donut (by type / by owner) ─────────────────────────────────────

class _Segment {
  final String label;
  final double value;
  final Color color;

  const _Segment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _BreakdownSection extends StatefulWidget {
  final List<_TypeStat> typeStats;
  final List<_OwnerStat> ownerStats;
  final String currencySymbol;
  final int totalItems;
  final AurumTheme appTheme;
  final AppLocalizations l10n;

  const _BreakdownSection({
    required this.typeStats,
    required this.ownerStats,
    required this.currencySymbol,
    required this.totalItems,
    required this.appTheme,
    required this.l10n,
  });

  @override
  State<_BreakdownSection> createState() => _BreakdownSectionState();
}

class _BreakdownSectionState extends State<_BreakdownSection> {
  bool _byOwner = false;

  // Categorical palette (theme-independent so segments stay distinguishable).
  static const List<Color> _palette = [
    Color(0xFFBA7517),
    Color(0xFF1D9E75),
    Color(0xFF7F77DD),
    Color(0xFFD4537E),
    Color(0xFF378ADD),
    Color(0xFF639922),
    Color(0xFFD85A30),
  ];

  List<_Segment> _segments() {
    final locale = widget.l10n.locale;
    if (_byOwner) {
      final list = widget.ownerStats.where((o) => o.totalValue > 0).toList()
        ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
      return [
        for (var i = 0; i < list.length; i++)
          _Segment(
            label: list[i].ownerName,
            value: list[i].totalValue,
            color: _palette[i % _palette.length],
          ),
      ];
    }
    final list =
        widget.typeStats.where((t) => t.count > 0 && t.totalValue > 0).toList()
          ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
    return [
      for (var i = 0; i < list.length; i++)
        _Segment(
          label: list[i].type.localizedName(locale),
          value: list[i].totalValue,
          color: _palette[i % _palette.length],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = widget.appTheme;
    final l10n = widget.l10n;
    final segments = _segments();
    final total = segments.fold<double>(0, (s, seg) => s + seg.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionHeader(
                title: l10n.breakdownTitle,
                appTheme: appTheme,
                l10n: l10n,
              ),
            ),
            _SegToggle(
              byOwner: _byOwner,
              appTheme: appTheme,
              typeLabel: l10n.breakdownByType,
              ownerLabel: l10n.breakdownByOwner,
              onChanged: (v) => setState(() => _byOwner = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (segments.isEmpty)
          _EmptyHint(l10n.noItemsYet, appTheme, l10n)
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: appTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appTheme.border),
              boxShadow: [appTheme.cardShadow],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  height: 118,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                          startDegreeOffset: -90,
                          sections: [
                            for (final seg in segments)
                              PieChartSectionData(
                                value: seg.value,
                                color: seg.color,
                                radius: 22,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.totalItems}',
                            style: TextStyle(
                              color: appTheme.inkDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.itemsUnit,
                            style: TextStyle(
                              color: appTheme.inkLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < segments.length; i++) ...[
                        _LegendRow(
                          seg: segments[i],
                          pct: total > 0 ? segments[i].value / total * 100 : 0,
                          currencySymbol: widget.currencySymbol,
                          appTheme: appTheme,
                        ),
                        if (i != segments.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SegToggle extends StatelessWidget {
  final bool byOwner;
  final AurumTheme appTheme;
  final String typeLabel;
  final String ownerLabel;
  final ValueChanged<bool> onChanged;

  const _SegToggle({
    required this.byOwner,
    required this.appTheme,
    required this.typeLabel,
    required this.ownerLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(typeLabel, !byOwner, () => onChanged(false)),
          _seg(ownerLabel, byOwner, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? appTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : appTheme.inkMid,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final _Segment seg;
  final double pct;
  final String currencySymbol;
  final AurumTheme appTheme;

  const _LegendRow({
    required this.seg,
    required this.pct,
    required this.currencySymbol,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: seg.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            seg.label,
            style: TextStyle(color: appTheme.inkDark, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                color: appTheme.inkDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            MoneyText(
              '$currencySymbol ${seg.value.toStringAsFixed(0)}',
              style: TextStyle(color: appTheme.inkLight, fontSize: 11),
            ),
          ],
        ),
      ],
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
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
    final initial = stat.ownerName.isNotEmpty
        ? stat.ownerName[0].toUpperCase()
        : '?';

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
                  Text(
                    stat.ownerName,
                    style: AppTextStyles.title(
                      appTheme.inkDark,
                      locale: l10n.locale,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    '$currencySymbol ${stat.totalValue.toStringAsFixed(2)}',
                    style: AppTextStyles.priceSmall(appTheme.primaryDark),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            Icon(
              Icons.chevron_right_outlined,
              color: appTheme.inkLight,
              size: 20,
            ),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.isNotEmpty ? item.name : l10n.untitled,
                      style: AppTextStyles.caption(
                        appTheme.inkDark,
                        locale: l10n.locale,
                      ).copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    MoneyText(
                      '$currencySymbol ${price.toStringAsFixed(0)}',
                      style: AppTextStyles.caption(
                        appTheme.primaryDark,
                        locale: l10n.locale,
                      ).copyWith(fontWeight: FontWeight.w700),
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
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, _) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      );
    } catch (_) {
      return const Center(child: Icon(Icons.broken_image_outlined));
    }
  }
}
