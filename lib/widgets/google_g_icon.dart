import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleGIcon extends StatelessWidget {
  const GoogleGIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleGIconPainter(),
      ),
    );
  }
}

class _GoogleGIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = (size.shortestSide * 0.18).clamp(2.0, 4.0);
    final double radius = (size.shortestSide - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Rough approximation of the Google "G" ring segments.
    paint.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, -0.15 * math.pi, 0.75 * math.pi, false, paint);

    paint.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, 0.65 * math.pi, 0.62 * math.pi, false, paint);

    paint.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, 1.27 * math.pi, 0.62 * math.pi, false, paint);

    paint.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, 1.89 * math.pi, 0.95 * math.pi, false, paint);

    // Horizontal bar of the "G".
    final Paint bar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF4285F4);

    final double barY = center.dy;
    canvas.drawLine(
      Offset(center.dx, barY),
      Offset(center.dx + radius * 0.75, barY),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

