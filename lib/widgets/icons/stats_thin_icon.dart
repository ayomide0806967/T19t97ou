import 'package:flutter/material.dart';

/// Minimal, thin "stats/insights" line icon drawn with CustomPaint.
/// Keeps the look modern and lightweight compared to stock Material glyphs.
class StatsThinIcon extends StatelessWidget {
  const StatsThinIcon({
    super.key,
    required this.color,
    this.size = 18,
    this.strokeWidth = 1.8,
  });

  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StatsThinPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _StatsThinPainter extends CustomPainter {
  const _StatsThinPainter({required this.color, required this.strokeWidth});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;
    final double inset = w * 0.10;

    // A simple rising polyline with gentle kinks.
    final path = Path()
      ..moveTo(inset, h * 0.70)
      ..lineTo(w * 0.42, h * 0.58)
      ..lineTo(w * 0.64, h * 0.38)
      ..lineTo(w - inset, h * 0.22);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StatsThinPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

