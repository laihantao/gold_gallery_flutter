import 'package:flutter/material.dart';

/// A crisp 4-point pixel star used as a small accent beside prices,
/// featured card headers and the home-screen gold price.
///
/// Drawn with nearest-neighbour / no anti-aliasing for a deliberate
/// pixel-art feel. Defaults to 10dp.
class SparkleWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const SparkleWidget({super.key, this.size = 10, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SparklePainter(c)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  const _SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final h = size.width / 2;
    final w = size.width * 0.16; // pinched waist

    // 4-point concave star
    final path = Path()
      ..moveTo(cx, cy - h)
      ..lineTo(cx + w, cy - w)
      ..lineTo(cx + h, cy)
      ..lineTo(cx + w, cy + w)
      ..lineTo(cx, cy + h)
      ..lineTo(cx - w, cy + w)
      ..lineTo(cx - h, cy)
      ..lineTo(cx - w, cy - w)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.color != color;
}
