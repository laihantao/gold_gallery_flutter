import 'package:flutter/material.dart';

/// Faint repeating "sparkle + ring" watermark drawn behind page content.
///
/// A 4-point star (sparkle) sits above a tiny ring at every point of a
/// 60dp × 60dp grid, evoking gold jewellery + sparkle for the Aurum brand.
/// Rendered in [color] at low opacity for a soft notebook-paper feel.
class BgPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double opacity;

  const BgPatternPainter({
    required this.color,
    this.spacing = 60,
    this.opacity = 0.08,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintColor = color.withValues(alpha: opacity);

    final fill = Paint()
      ..color = paintColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;

    final stroke = Paint()
      ..color = paintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;

    const starSize = 12.0; // overall sparkle extent
    const ringRadius = 2.0; // tiny circle (≈4dp diameter)

    for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
      for (double x = spacing / 2; x < size.width + spacing; x += spacing) {
        _drawSparkle(canvas, fill, Offset(x, y), starSize);
        // tiny ring sits just below the sparkle
        canvas.drawCircle(Offset(x, y + starSize * 0.85), ringRadius, stroke);
      }
    }
  }

  /// A 4-point star: a slim concave diamond with pinched waist.
  void _drawSparkle(Canvas canvas, Paint paint, Offset c, double s) {
    final h = s / 2;
    final w = s * 0.18; // waist half-width
    final path = Path()
      ..moveTo(c.dx, c.dy - h) // top
      ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + h, c.dy) // to right
      ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + h) // to bottom
      ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - h, c.dy) // to left
      ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - h) // back to top
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BgPatternPainter oldDelegate) => false;
}

/// Convenience wrapper that paints [BgPatternPainter] behind [child].
///
/// Drop a screen body inside this and place it on a [Scaffold] whose
/// background is the theme's `primaryBg`.
class PatternedBackground extends StatelessWidget {
  final Color patternColor;
  final Widget child;

  const PatternedBackground({
    super.key,
    required this.patternColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BgPatternPainter(color: patternColor),
          ),
        ),
        child,
      ],
    );
  }
}
