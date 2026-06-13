import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter that draws a rounded rectangle outline with a soft, hand-drawn
/// wobble — as if traced with a pencil rather than a ruler.
///
/// The wobble is *deterministic* (seeded by position along the path) so the
/// border is stable frame-to-frame and never jitters.
class SketchBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final bool dashed;
  final double dashLength;
  final double dashGap;
  final double wobble;

  const SketchBorderPainter({
    required this.color,
    this.radius = 16,
    this.strokeWidth = 1.5,
    this.dashed = false,
    this.dashLength = 8,
    this.dashGap = 4,
    this.wobble = 0.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      math.max(0, size.width - strokeWidth),
      math.max(0, size.height - strokeWidth),
    );
    final r = radius.clamp(0, math.min(rect.width, rect.height) / 2).toDouble();
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));

    final wobbly = _wobblePath(base);

    if (dashed) {
      canvas.drawPath(_dash(wobbly), paint);
    } else {
      canvas.drawPath(wobbly, paint);
    }
  }

  /// Walk the path and nudge each sampled point by a seeded perpendicular
  /// offset, producing an organic outline.
  Path _wobblePath(Path source) {
    final out = Path();
    const step = 10.0; // sample every 10dp
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      bool first = true;
      while (dist <= metric.length) {
        final tan = metric.getTangentForOffset(dist);
        if (tan != null) {
          final p = tan.position;
          // perpendicular to the tangent direction
          final nx = -tan.vector.dy;
          final ny = tan.vector.dx;
          final offset = _seededWobble(dist) * wobble;
          final wp = Offset(p.dx + nx * offset, p.dy + ny * offset);
          if (first) {
            out.moveTo(wp.dx, wp.dy);
            first = false;
          } else {
            out.lineTo(wp.dx, wp.dy);
          }
        }
        dist += step;
      }
      if (metric.isClosed) out.close();
    }
    return out;
  }

  /// Deterministic value in [-1, 1] based on distance along the path.
  double _seededWobble(double d) {
    final s = math.sin(d * 12.9898) * 43758.5453;
    return (s - s.floor()) * 2 - 1;
  }

  /// Convert a continuous path into on/off dash segments.
  Path _dash(Path source) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final len = draw ? dashLength : dashGap;
        final next = math.min(dist + len, metric.length);
        if (draw) {
          out.addPath(metric.extractPath(dist, next), Offset.zero);
        }
        dist = next;
        draw = !draw;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant SketchBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashed != dashed ||
      old.dashLength != dashLength ||
      old.dashGap != dashGap ||
      old.wobble != wobble;
}

/// Wraps [child] in a hand-drawn pencil outline.
///
/// Used for jewellery cards, dialogs/sheets, filter chips, banners and
/// section headers. Set [dashed] for a sketch-divider style.
class SketchBorder extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double radius;
  final double strokeWidth;
  final bool dashed;
  final double dashLength;
  final double dashGap;

  const SketchBorder({
    super.key,
    required this.child,
    this.color,
    this.radius = 16,
    this.strokeWidth = 1.5,
    this.dashed = false,
    this.dashLength = 8,
    this.dashGap = 4,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).dividerColor;
    return CustomPaint(
      foregroundPainter: SketchBorderPainter(
        color: c,
        radius: radius,
        strokeWidth: strokeWidth,
        dashed: dashed,
        dashLength: dashLength,
        dashGap: dashGap,
      ),
      child: child,
    );
  }
}

/// A single horizontal hand-drawn (optionally dashed) divider line.
class SketchDivider extends StatelessWidget {
  final Color color;
  final double thickness;
  final bool dashed;
  final double height;

  const SketchDivider({
    super.key,
    required this.color,
    this.thickness = 1.0,
    this.dashed = true,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SketchLinePainter(
          color: color,
          thickness: thickness,
          dashed: dashed,
        ),
      ),
    );
  }
}

class _SketchLinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool dashed;

  const _SketchLinePainter({
    required this.color,
    required this.thickness,
    required this.dashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    if (dashed) {
      const dash = 8.0;
      const gap = 4.0;
      double x = 0;
      while (x < size.width) {
        final dy = math.sin(x * 0.5) * 0.4; // faint wobble
        canvas.drawLine(
          Offset(x, y + dy),
          Offset(math.min(x + dash, size.width), y + dy),
          paint,
        );
        x += dash + gap;
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SketchLinePainter old) =>
      old.color != color || old.thickness != thickness || old.dashed != dashed;
}
