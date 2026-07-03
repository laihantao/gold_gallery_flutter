import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../models/jewellery.dart';
import '../services/gold_price_history_service.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

// ── Data model for a single point on the portfolio chart ─────────────────────

class _PortfolioPoint {
  final DateTime date;
  final double totalValue;
  const _PortfolioPoint(this.date, this.totalValue);
}

// ── Page ─────────────────────────────────────────────────────────────────────

class PortfolioChartPage extends StatefulWidget {
  const PortfolioChartPage({super.key});

  @override
  State<PortfolioChartPage> createState() => _PortfolioChartPageState();
}

class _PortfolioChartPageState extends State<PortfolioChartPage> {
  static const _vendors = ['Poh Kong', 'Chiang Heng', 'Tomei'];
  String _selectedVendor = _vendors.first;
  int? _touchedIndex;

  List<_PortfolioPoint> _buildPoints(String vendor) {
    final items =
        HiveService.getAllJewellery().cast<Jewellery>().where((j) {
      return j.weight != null && j.weight! > 0;
    }).toList();

    final history = GoldPriceHistoryService.historyFor(vendor);
    if (history.isEmpty) return [];

    final points = <_PortfolioPoint>[];
    for (final snap in history) {
      double total = 0;
      for (final j in items) {
        final price = j.goldPurity == '999' ? snap.price999 : snap.price916;
        if (price != null && price > 0) {
          total += j.weight! * price;
        }
      }
      if (total > 0) {
        points.add(_PortfolioPoint(snap.recordedAt, total));
      }
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final points = _buildPoints(_selectedVendor);

    return Scaffold(
      appBar: AppHeader(
        title: 'Portfolio Trend',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // ── Vendor selector ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _VendorSelector(
              vendors: _vendors,
              selected: _selectedVendor,
              appTheme: appTheme,
              onSelect: (v) => setState(() {
                _selectedVendor = v;
                _touchedIndex = null;
              }),
            ),
          ),

          const SizedBox(height: 12),

          // ── Summary cards ──
          if (points.isNotEmpty)
            _SummaryRow(points: points, appTheme: appTheme),

          const SizedBox(height: 8),

          // ── Chart ──
          Expanded(
            child: points.length < 2
                ? _EmptyChart(
                    appTheme: appTheme, vendor: _selectedVendor)
                : _Chart(
                    points: points,
                    appTheme: appTheme,
                    touchedIndex: _touchedIndex,
                    onTouch: (i) => setState(() => _touchedIndex = i),
                  ),
          ),

          // ── Touch detail ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _touchedIndex != null &&
                    _touchedIndex! < points.length
                ? _TouchDetail(
                    key: ValueKey(_touchedIndex),
                    point: points[_touchedIndex!],
                    appTheme: appTheme,
                  )
                : const SizedBox(height: 64),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Vendor selector ───────────────────────────────────────────────────────────

class _VendorSelector extends StatelessWidget {
  final List<String> vendors;
  final String selected;
  final AppTheme appTheme;
  final ValueChanged<String> onSelect;

  const _VendorSelector({
    required this.vendors,
    required this.selected,
    required this.appTheme,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: appTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appTheme.border),
      ),
      child: Row(
        children: vendors.map((v) {
          final active = v == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? appTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  v,
                  style: TextStyle(
                    color: active ? Colors.white : appTheme.inkMid,
                    fontSize: 12,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<_PortfolioPoint> points;
  final AppTheme appTheme;

  const _SummaryRow({required this.points, required this.appTheme});

  @override
  Widget build(BuildContext context) {
    final first = points.first.totalValue;
    final last = points.last.totalValue;
    final diff = last - first;
    final pct = first > 0 ? (diff / first) * 100 : 0.0;
    final isGain = diff >= 0;
    final gainColor = isGain ? appTheme.success : appTheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SummaryCard(
            label: 'Current Value',
            value: 'RM ${last.toStringAsFixed(0)}',
            color: appTheme.primaryDark,
            appTheme: appTheme,
          ),
          const SizedBox(width: 10),
          _SummaryCard(
            label: 'All-time Change',
            value:
                '${isGain ? '+' : ''}${pct.toStringAsFixed(1)}%',
            color: gainColor,
            appTheme: appTheme,
            icon: isGain
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
          ),
          const SizedBox(width: 10),
          _SummaryCard(
            label: 'Data points',
            value: '${points.length}d',
            color: appTheme.inkMid,
            appTheme: appTheme,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppTheme appTheme;
  final IconData? icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.appTheme,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appTheme.border),
          boxShadow: [appTheme.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  color: appTheme.inkLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart ─────────────────────────────────────────────────────────────────────

class _Chart extends StatelessWidget {
  final List<_PortfolioPoint> points;
  final AppTheme appTheme;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;

  const _Chart({
    required this.points,
    required this.appTheme,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final minY =
        points.map((p) => p.totalValue).reduce((a, b) => a < b ? a : b);
    final maxY =
        points.map((p) => p.totalValue).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padded = range * 0.12;
    final yMin = (minY - padded).clamp(0.0, double.infinity);
    final yMax = maxY + padded;

    final spots = List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), points[i].totalValue),
    );

    final isGainOverall =
        points.last.totalValue >= points.first.totalValue;
    final lineColor = isGainOverall ? appTheme.success : appTheme.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: LineChart(
        LineChartData(
          minY: yMin,
          maxY: yMax,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 4 : 1000,
            getDrawingHorizontalLine: (_) => FlLine(
              color: appTheme.border.withValues(alpha: 0.4),
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: range > 0 ? range / 4 : 1000,
                getTitlesWidget: (val, meta) {
                  if (val == meta.min || val == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    'RM ${(val / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(
                        color: appTheme.inkLight, fontSize: 9),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (points.length / 5).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('d/M').format(points[i].date),
                      style: TextStyle(
                          color: appTheme.inkLight, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (event, response) {
              if (event is FlTapUpEvent ||
                  event is FlPanEndEvent ||
                  event is FlLongPressEnd) {
                onTouch(null);
                return;
              }
              final idx =
                  response?.lineBarSpots?.first.spotIndex;
              onTouch(idx);
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  appTheme.surface.withValues(alpha: 0.0),
              getTooltipItems: (_) => [],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: lineColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) {
                  final isActive = idx == touchedIndex;
                  return FlDotCirclePainter(
                    radius: isActive ? 6 : 3,
                    color: isActive
                        ? Colors.white
                        : lineColor.withValues(alpha: 0.6),
                    strokeColor: lineColor,
                    strokeWidth: isActive ? 2.5 : 1,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.18),
                    lineColor.withValues(alpha: 0.0),
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

// ── Touch detail ──────────────────────────────────────────────────────────────

class _TouchDetail extends StatelessWidget {
  final _PortfolioPoint point;
  final AppTheme appTheme;

  const _TouchDetail({super.key, required this.point, required this.appTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appTheme.border),
        boxShadow: [appTheme.cardShadow],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded,
              color: appTheme.inkLight, size: 14),
          const SizedBox(width: 6),
          Text(
            DateFormat('d MMM yyyy').format(point.date),
            style: TextStyle(
                color: appTheme.inkMid,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            'RM ${point.totalValue.toStringAsFixed(2)}',
            style: TextStyle(
              color: appTheme.primaryDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  final AppTheme appTheme;
  final String vendor;

  const _EmptyChart({required this.appTheme, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded,
                color: appTheme.inkLight, size: 48),
            const SizedBox(height: 12),
            Text(
              'No history for $vendor yet',
              style: TextStyle(
                  color: appTheme.inkDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Fetch gold prices regularly or sync history in Settings to build the portfolio trend.',
              style: TextStyle(
                  color: appTheme.inkLight,
                  fontSize: 12,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
