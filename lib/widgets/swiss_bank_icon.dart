import 'package:flutter/material.dart';

class SwissBankIcon extends StatelessWidget {
  const SwissBankIcon({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color strokeColor =
        isDark ? Colors.white : const Color(0xFF111827);

    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: _SwissBankPainter(
          color: strokeColor,
        ),
      ),
    );
  }
}

class _SwissBankPainter extends CustomPainter {
  const _SwissBankPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Roof outline
    final double roofBaseY = h * 0.30;
    final Path roof = Path()
      ..moveTo(w * 0.10, roofBaseY)
      ..lineTo(w * 0.50, h * 0.05)
      ..lineTo(w * 0.90, roofBaseY)
      ..close();
    canvas.drawPath(roof, strokePaint);

    // Single base line
    final double baseY = h * 0.78;
    canvas.drawLine(
      Offset(w * 0.12, baseY),
      Offset(w * 0.88, baseY),
      strokePaint,
    );

    // Column vertical lines
    final double colTop = roofBaseY + h * 0.06;
    final double colBottom = baseY - h * 0.08;

    final double leftX = w * 0.22;
    final double centerX = w * 0.50;
    final double rightX = w * 0.78;

    canvas.drawLine(Offset(leftX, colTop), Offset(leftX, colBottom), strokePaint);
    canvas.drawLine(Offset(centerX, colTop), Offset(centerX, colBottom), strokePaint);
    canvas.drawLine(Offset(rightX, colTop), Offset(rightX, colBottom), strokePaint);

    // Diagonal stroke forming part of the "N"
    final Path diagonal = Path()
      ..moveTo(centerX, colTop + (colBottom - colTop) * 0.15)
      ..lineTo(rightX, colBottom);
    canvas.drawPath(diagonal, strokePaint);
  }

  @override
  bool shouldRepaint(_SwissBankPainter oldDelegate) => false;
}
