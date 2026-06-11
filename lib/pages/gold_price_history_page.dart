import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../services/gold_price_history_service.dart';
import '../services/gold_price_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_price_card.dart';

// ── Chart padding constants (shared between painter and gesture handler) ──────

const double _kChartPadL = 46;
const double _kChartPadR = 10;
const double _kChartPadT = 10;
const double _kChartPadB = 26;

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _Metric { k916, k999 }

enum _ChartRange { d7, d30, all }

// ── Page ──────────────────────────────────────────────────────────────────────

class GoldPriceHistoryPage extends StatefulWidget {
  final String shopName;
  const GoldPriceHistoryPage({super.key, required this.shopName});

  @override
  State<GoldPriceHistoryPage> createState() => _GoldPriceHistoryPageState();
}

class _GoldPriceHistoryPageState extends State<GoldPriceHistoryPage> {
  // ── Async load state ──────────────────────────────────────────────────────
  List<GoldPriceHistoryPoint>? _allPoints;

  // ── Chart controls ────────────────────────────────────────────────────────
  _Metric _metric = _Metric.k999;
  _ChartRange _chartRange = _ChartRange.d30;

  // ── Chart interaction ─────────────────────────────────────────────────────
  _ChartPoint? _selectedChartPoint;

  // ── Table pagination ──────────────────────────────────────────────────────
  int _pageSize = 7;
  int _page = 0;

  // ── Formatters ────────────────────────────────────────────────────────────
  static final _dateFmt = DateFormat('d MMM yy');
  static final _tooltipFmt = DateFormat('d MMM yyyy');

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Offload Hive work so the first frame renders the spinner immediately.
    Future.microtask(_loadHistory);
  }

  Future<void> _loadHistory() async {
    final points = await Future(
        () => GoldPriceHistoryService.historyFor(widget.shopName));
    if (!mounted) return;
    setState(() {
      _allPoints = points;
      _page = 0;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _logoAsset {
    for (final s in GoldPriceService.sources) {
      if (s.shopName == widget.shopName) return s.logoAsset;
    }
    return '';
  }

  List<GoldPriceHistoryPoint> _chartPoints(List<GoldPriceHistoryPoint> all) {
    if (_chartRange == _ChartRange.all) return all;
    final days = _chartRange == _ChartRange.d7 ? 7 : 30;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = all.where((p) => p.recordedAt.isAfter(cutoff)).toList();
    if (filtered.length < 2 && all.length >= 2) {
      return all.sublist(all.length - 2);
    }
    return filtered;
  }

  double? _metricValue(GoldPriceHistoryPoint p) =>
      _metric == _Metric.k916 ? p.price916 : p.price999;

  List<GoldPriceHistoryPoint> _tablePage(List<GoldPriceHistoryPoint> all) {
    final rows = all.reversed.toList();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, rows.length);
    return rows.sublist(start, end);
  }

  int _totalPages(int totalRows) =>
      totalRows == 0 ? 1 : ((totalRows + _pageSize - 1) ~/ _pageSize);

  // ── Chart gesture ─────────────────────────────────────────────────────────

  void _onChartTouch(
      Offset localPos, List<_ChartPoint> series, Size chartSize) {
    if (series.isEmpty) return;
    final chartW = chartSize.width - _kChartPadL - _kChartPadR;
    if (chartW <= 0) return;

    final minX = series.first.x;
    final maxX = series.last.x;
    final dataX = maxX == minX
        ? minX
        : minX + (localPos.dx - _kChartPadL) / chartW * (maxX - minX);

    var nearest = series.first;
    var nearestDist = (nearest.x - dataX).abs();
    for (final pt in series) {
      final d = (pt.x - dataX).abs();
      if (d < nearestDist) {
        nearest = pt;
        nearestDist = d;
      }
    }
    setState(() => _selectedChartPoint = nearest);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    if (_allPoints == null) {
      return _LoadingScaffold(title: widget.shopName, appTheme: appTheme);
    }

    final all = _allPoints!;
    final chartSeries = _chartPoints(all)
        .where((p) => _metricValue(p) != null)
        .map((p) => _ChartPoint(
              p.recordedAt.millisecondsSinceEpoch.toDouble(),
              _metricValue(p)!,
            ))
        .toList();

    return Scaffold(
      appBar: AppHeader(title: widget.shopName),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(appTheme, all),
          const SizedBox(height: 16),
          _buildMetricToggle(appTheme),
          const SizedBox(height: 12),
          _buildChartCard(appTheme, chartSeries),
          const SizedBox(height: 8),
          _buildChartRangeToggle(appTheme),
          const SizedBox(height: 24),
          _buildHistorySection(appTheme, all),
        ],
      ),
    );
  }

  // ── Summary card (shared BrandPriceCard component) ────────────────────────

  Widget _buildSummaryCard(
      AppTheme appTheme, List<GoldPriceHistoryPoint> all) {
    final latest = all.isNotEmpty ? all.last : null;
    final prev = all.length >= 2 ? all[all.length - 2] : null;

    return BrandPriceCard(
      shopName: widget.shopName,
      logoAsset: _logoAsset,
      price916: latest?.price916,
      price999: latest?.price999,
      prevPrice916: prev?.price916,
      prevPrice999: prev?.price999,
      updatedAt: latest?.recordedAt,
      isLoading: false,
      isError: false,
      onRefresh: null,
      onTap: null,
      appTheme: appTheme,
    );
  }

  // ── Metric toggle ─────────────────────────────────────────────────────────

  Widget _buildMetricToggle(AppTheme appTheme) {
    return Row(
      children: [
        _SegmentButton(
          appTheme: appTheme,
          label: '916 Gold',
          selected: _metric == _Metric.k916,
          onTap: () => setState(() {
            _metric = _Metric.k916;
            _selectedChartPoint = null;
          }),
        ),
        const SizedBox(width: 8),
        _SegmentButton(
          appTheme: appTheme,
          label: '999 Gold',
          selected: _metric == _Metric.k999,
          onTap: () => setState(() {
            _metric = _Metric.k999;
            _selectedChartPoint = null;
          }),
        ),
      ],
    );
  }

  // ── Chart range toggle ────────────────────────────────────────────────────

  Widget _buildChartRangeToggle(AppTheme appTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SegmentButton(
          appTheme: appTheme,
          label: '7D',
          selected: _chartRange == _ChartRange.d7,
          onTap: () => setState(() {
            _chartRange = _ChartRange.d7;
            _selectedChartPoint = null;
          }),
        ),
        const SizedBox(width: 8),
        _SegmentButton(
          appTheme: appTheme,
          label: '30D',
          selected: _chartRange == _ChartRange.d30,
          onTap: () => setState(() {
            _chartRange = _ChartRange.d30;
            _selectedChartPoint = null;
          }),
        ),
        const SizedBox(width: 8),
        _SegmentButton(
          appTheme: appTheme,
          label: 'All',
          selected: _chartRange == _ChartRange.all,
          onTap: () => setState(() {
            _chartRange = _ChartRange.all;
            _selectedChartPoint = null;
          }),
        ),
      ],
    );
  }

  // ── Chart card ────────────────────────────────────────────────────────────

  Widget _buildChartCard(AppTheme appTheme, List<_ChartPoint> series) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      decoration: BoxDecoration(
        color: appTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: appTheme.borderColor.withValues(alpha: 0.3)),
      ),
      child: SizedBox(
        height: 220,
        child: series.length < 2
            ? _ChartEmpty(appTheme: appTheme)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final chartSize =
                      Size(constraints.maxWidth, 220);
                  return GestureDetector(
                    // Pan: tap-hold and drag to scrub
                    onPanStart: (d) =>
                        _onChartTouch(d.localPosition, series, chartSize),
                    onPanUpdate: (d) =>
                        _onChartTouch(d.localPosition, series, chartSize),
                    onPanEnd: (_) =>
                        setState(() => _selectedChartPoint = null),
                    // Single tap also shows tooltip briefly
                    onTapDown: (d) =>
                        _onChartTouch(d.localPosition, series, chartSize),
                    onTapUp: (_) =>
                        setState(() => _selectedChartPoint = null),
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        points: series,
                        selectedPoint: _selectedChartPoint,
                        lineColor: appTheme.accentPrimary,
                        fillColor: appTheme.accentPrimary
                            .withValues(alpha: 0.14),
                        gridColor: appTheme.borderColor
                            .withValues(alpha: 0.25),
                        textColor: appTheme.textBody,
                        dotColor: appTheme.priceHighlight,
                        dateLabel: (ms) => _dateFmt.format(
                            DateTime.fromMillisecondsSinceEpoch(
                                ms.toInt())),
                        tooltipDateLabel: (ms) => _tooltipFmt.format(
                            DateTime.fromMillisecondsSinceEpoch(
                                ms.toInt())),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ── History section ───────────────────────────────────────────────────────

  Widget _buildHistorySection(
      AppTheme appTheme, List<GoldPriceHistoryPoint> all) {
    if (all.isEmpty) return const SizedBox.shrink();

    final rows = all.reversed.toList();
    final pageRows = _tablePage(all);
    final totalPages = _totalPages(rows.length);
    final startIdx = _page * _pageSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'History',
              style: TextStyle(
                  color: appTheme.textHeading,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _PageSizeSelector(
              current: _pageSize,
              options: const [7, 14, 30],
              appTheme: appTheme,
              onChanged: (size) => setState(() {
                _pageSize = size;
                _page = 0;
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: appTheme.backgroundSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: appTheme.borderColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _TableHeaderRow(appTheme: appTheme),
              for (var i = 0; i < pageRows.length; i++)
                _TableDataRow(
                  appTheme: appTheme,
                  point: pageRows[i],
                  shaded: i.isOdd,
                  dateFmt: _dateFmt,
                ),
              _PaginationFooter(
                appTheme: appTheme,
                currentPage: _page,
                totalPages: totalPages,
                totalRows: rows.length,
                pageStart: startIdx + 1,
                pageEnd: startIdx + pageRows.length,
                onPrev: _page > 0 ? () => setState(() => _page--) : null,
                onNext: _page < totalPages - 1
                    ? () => setState(() => _page++)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Loading scaffold ──────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  final String title;
  final AppTheme appTheme;

  const _LoadingScaffold({required this.title, required this.appTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: title),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: appTheme.accentPrimary,
                backgroundColor:
                    appTheme.accentPrimary.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading history…',
              style: TextStyle(
                color: appTheme.textBody.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment button ────────────────────────────────────────────────────────────

class _SegmentButton extends StatelessWidget {
  final AppTheme appTheme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.appTheme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? appTheme.accentPrimary.withValues(alpha: 0.18)
                : appTheme.backgroundSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? appTheme.accentPrimary
                  : appTheme.borderColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? appTheme.textHeading : appTheme.textBody,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page size selector (7D / 14D / 30D) ──────────────────────────────────────

class _PageSizeSelector extends StatelessWidget {
  final int current;
  final List<int> options;
  final AppTheme appTheme;
  final ValueChanged<int> onChanged;

  const _PageSizeSelector({
    required this.current,
    required this.options,
    required this.appTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final opt in options) ...[
          if (opt != options.first) const SizedBox(width: 6),
          _SizeChip(
            label: '${opt}D',
            selected: current == opt,
            appTheme: appTheme,
            onTap: () => onChanged(opt),
          ),
        ],
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppTheme appTheme;
  final VoidCallback onTap;

  const _SizeChip({
    required this.label,
    required this.selected,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? appTheme.accentPrimary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? appTheme.accentPrimary
                : appTheme.borderColor.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? appTheme.textHeading
                : appTheme.textBody.withValues(alpha: 0.8),
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Table header ──────────────────────────────────────────────────────────────

class _TableHeaderRow extends StatelessWidget {
  final AppTheme appTheme;
  const _TableHeaderRow({required this.appTheme});

  @override
  Widget build(BuildContext context) {
    final s = TextStyle(
        color: appTheme.textBody.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Date', style: s)),
          Expanded(
              flex: 3,
              child: Text('916', style: s, textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text('999', style: s, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

// ── Table data row ────────────────────────────────────────────────────────────

class _TableDataRow extends StatelessWidget {
  final AppTheme appTheme;
  final GoldPriceHistoryPoint point;
  final bool shaded;
  final DateFormat dateFmt;

  const _TableDataRow({
    required this.appTheme,
    required this.point,
    required this.shaded,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    String fmt(double? v) =>
        v == null ? '—' : 'RM ${v.toStringAsFixed(0)}';
    final valStyle = TextStyle(
        color: appTheme.textHeading,
        fontSize: 12.5,
        fontWeight: FontWeight.w500);

    return Container(
      color: shaded
          ? appTheme.backgroundSubtle.withValues(alpha: 0.4)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              dateFmt.format(point.recordedAt),
              style: TextStyle(color: appTheme.textBody, fontSize: 12.5),
            ),
          ),
          Expanded(
              flex: 3,
              child: Text(fmt(point.price916),
                  style: valStyle, textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text(fmt(point.price999),
                  style: valStyle, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

// ── Pagination footer ─────────────────────────────────────────────────────────

class _PaginationFooter extends StatelessWidget {
  final AppTheme appTheme;
  final int currentPage;
  final int totalPages;
  final int totalRows;
  final int pageStart;
  final int pageEnd;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationFooter({
    required this.appTheme,
    required this.currentPage,
    required this.totalPages,
    required this.totalRows,
    required this.pageStart,
    required this.pageEnd,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      color: appTheme.textBody.withValues(alpha: 0.55),
      fontSize: 11,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: appTheme.borderColor.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Text('$pageStart–$pageEnd of $totalRows', style: mutedStyle),
          const Spacer(),
          _PageButton(
            icon: Icons.chevron_left_rounded,
            enabled: onPrev != null,
            appTheme: appTheme,
            onTap: onPrev,
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: appTheme.accentPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: TextStyle(
                  color: appTheme.textHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            enabled: onNext != null,
            appTheme: appTheme,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppTheme appTheme;
  final VoidCallback? onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? appTheme.accentPrimary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? appTheme.accentPrimary.withValues(alpha: 0.4)
                : appTheme.borderColor.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? appTheme.accentPrimary
              : appTheme.textBody.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

// ── Chart empty placeholder ───────────────────────────────────────────────────

class _ChartEmpty extends StatelessWidget {
  final AppTheme appTheme;
  const _ChartEmpty({required this.appTheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline_rounded,
              size: 40, color: appTheme.textBody.withValues(alpha: 0.35)),
          const SizedBox(height: 10),
          Text(
            'Not enough history yet',
            style: TextStyle(
                color: appTheme.textHeading.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Prices are recorded once a day.\nCheck back after a few refreshes.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: appTheme.textBody.withValues(alpha: 0.55),
                fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ── Chart data model ──────────────────────────────────────────────────────────

class _ChartPoint {
  final double x; // milliseconds since epoch
  final double y; // price
  const _ChartPoint(this.x, this.y);
}

// ── Chart painter ─────────────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final _ChartPoint? selectedPoint;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color textColor;
  final Color dotColor;
  final String Function(double ms) dateLabel;
  final String Function(double ms) tooltipDateLabel;

  _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textColor,
    required this.dotColor,
    required this.dateLabel,
    required this.tooltipDateLabel,
    this.selectedPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _kChartPadL - _kChartPadR;
    final chartH = size.height - _kChartPadT - _kChartPadB;
    if (chartW <= 0 || chartH <= 0 || points.isEmpty) return;

    final minX = points.first.x;
    final maxX = points.last.x;
    var minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    var maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    if (maxY == minY) {
      minY -= 1;
      maxY += 1;
    } else {
      final pad = (maxY - minY) * 0.15;
      minY -= pad;
      maxY += pad;
    }

    double px(double x) => maxX == minX
        ? _kChartPadL + chartW / 2
        : _kChartPadL + (x - minX) / (maxX - minX) * chartW;
    double py(double y) =>
        _kChartPadT + (1 - (y - minY) / (maxY - minY)) * chartH;

    // Gridlines + Y labels
    const gridLines = 4;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= gridLines; i++) {
      final t = i / gridLines;
      final y = _kChartPadT + chartH * t;
      canvas.drawLine(
          Offset(_kChartPadL, y),
          Offset(size.width - _kChartPadR, y),
          gridPaint);
      final value = maxY - (maxY - minY) * t;
      _drawText(canvas, 'RM${value.toStringAsFixed(0)}',
          Offset(_kChartPadL - 6, y), textColor, 10,
          alignRight: true, centerVert: true);
    }

    // Fill + line
    final linePath = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final o = Offset(px(points[i].x), py(points[i].y));
      if (i == 0) {
        linePath.moveTo(o.dx, o.dy);
        fillPath.moveTo(o.dx, _kChartPadT + chartH);
        fillPath.lineTo(o.dx, o.dy);
      } else {
        linePath.lineTo(o.dx, o.dy);
        fillPath.lineTo(o.dx, o.dy);
      }
    }
    fillPath.lineTo(px(points.last.x), _kChartPadT + chartH);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Dots (skip if a selection is active — the selection dot will render)
    if (selectedPoint == null) {
      for (var i = 0; i < points.length; i++) {
        final o = Offset(px(points[i].x), py(points[i].y));
        final isLast = i == points.length - 1;
        canvas.drawCircle(o, isLast ? 4.0 : 2.5, Paint()..color = dotColor);
        if (isLast) {
          canvas.drawCircle(
              o, 7, Paint()..color = dotColor.withValues(alpha: 0.25));
          _drawText(canvas, 'RM${points[i].y.toStringAsFixed(0)}',
              Offset(o.dx, o.dy - 10), dotColor, 11,
              centerHoriz: true, bold: true);
        }
      }
    }

    // X axis first & last labels
    _drawText(canvas, dateLabel(points.first.x),
        Offset(_kChartPadL, size.height - _kChartPadB + 6), textColor, 10);
    _drawText(canvas, dateLabel(points.last.x),
        Offset(size.width - _kChartPadR, size.height - _kChartPadB + 6),
        textColor, 10,
        alignRight: true);

    // Selection overlay
    if (selectedPoint != null) {
      final selX = px(selectedPoint!.x);
      final selY = py(selectedPoint!.y);

      // Vertical guide line
      canvas.drawLine(
        Offset(selX, _kChartPadT),
        Offset(selX, _kChartPadT + chartH),
        Paint()
          ..color = lineColor.withValues(alpha: 0.45)
          ..strokeWidth = 1.0,
      );

      // Highlight dot
      canvas.drawCircle(
          Offset(selX, selY), 9, Paint()..color = dotColor.withValues(alpha: 0.28));
      canvas.drawCircle(Offset(selX, selY), 5, Paint()..color = dotColor);

      _drawTooltip(canvas, size, selX, selY, chartH);
    }
  }

  void _drawTooltip(
      Canvas canvas, Size size, double x, double y, double chartH) {
    final dateStr = tooltipDateLabel(selectedPoint!.x);
    final priceStr = 'RM ${selectedPoint!.y.toStringAsFixed(0)}';

    const hPad = 8.0;
    const vPad = 6.0;
    const gap = 2.0;

    final dateTp = TextPainter(
      text: TextSpan(
          text: dateStr,
          style: TextStyle(
              color: textColor.withValues(alpha: 0.85), fontSize: 10.5)),
      textDirection: TextDirection.ltr,
    )..layout();

    final priceTp = TextPainter(
      text: TextSpan(
          text: priceStr,
          style: TextStyle(
              color: dotColor,
              fontSize: 13,
              fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();

    final boxW =
        (dateTp.width > priceTp.width ? dateTp.width : priceTp.width) +
            hPad * 2;
    final boxH = dateTp.height + priceTp.height + vPad * 2 + gap;

    // Prefer above dot; fall back to below when near top
    double boxTop = y - boxH - 14;
    if (boxTop < _kChartPadT) boxTop = y + 14;

    double boxLeft = x - boxW / 2;
    if (boxLeft < 0) boxLeft = 0;
    if (boxLeft + boxW > size.width) boxLeft = size.width - boxW;

    final bgPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(boxLeft, boxTop, boxW, boxH),
          const Radius.circular(6)),
      bgPaint,
    );

    dateTp.paint(canvas, Offset(boxLeft + hPad, boxTop + vPad));
    priceTp.paint(
        canvas, Offset(boxLeft + hPad, boxTop + vPad + dateTp.height + gap));
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color,
      double fontSize,
      {bool alignRight = false,
      bool centerVert = false,
      bool centerHoriz = false,
      bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = pos.dx;
    var dy = pos.dy;
    if (alignRight) dx -= tp.width;
    if (centerHoriz) dx -= tp.width / 2;
    if (centerVert) dy -= tp.height / 2;
    if (dx < 0) dx = 0;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points ||
      old.selectedPoint != selectedPoint ||
      old.lineColor != lineColor ||
      old.dotColor != dotColor;
}
