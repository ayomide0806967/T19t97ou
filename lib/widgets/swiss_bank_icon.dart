import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SwissBankIcon extends StatelessWidget {
  const SwissBankIcon({
    super.key,
    this.size = 28,
    this.color,
    this.strokeWidthFactor = 0.06,
    this.refreshProgress,
    this.refreshDotColor = Colors.black,
  });

  final double size;
  final Color? color;
  final double strokeWidthFactor;
  final Animation<double>? refreshProgress;
  final Color refreshDotColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color strokeColor =
        color ?? (isDark ? Colors.white : const Color(0xFF111827));

    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: _SwissBankPainter(
          color: strokeColor,
          strokeWidthFactor: strokeWidthFactor,
          refreshProgress: refreshProgress,
          refreshDotColor: refreshDotColor,
        ),
      ),
    );
  }
}

class _SwissBankPainter extends CustomPainter {
  _SwissBankPainter({
    required this.color,
    required this.strokeWidthFactor,
    required this.refreshProgress,
    required this.refreshDotColor,
  }) : super(repaint: refreshProgress);

  final Color color;
  final double strokeWidthFactor;
  final Animation<double>? refreshProgress;
  final Color refreshDotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * strokeWidthFactor
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

    final progress = refreshProgress?.value;
    if (progress == null) return;

    final Path trace = Path()
      ..addPath(roof, Offset.zero)
      ..moveTo(w * 0.12, baseY)
      ..lineTo(w * 0.88, baseY)
      ..moveTo(leftX, colTop)
      ..lineTo(leftX, colBottom)
      ..moveTo(centerX, colTop)
      ..lineTo(centerX, colBottom)
      ..moveTo(rightX, colTop)
      ..lineTo(rightX, colBottom)
      ..addPath(diagonal, Offset.zero);

    final metrics = trace.computeMetrics(forceClosed: false).toList();
    double totalLength = 0;
    for (final metric in metrics) {
      totalLength += metric.length;
    }
    if (totalLength <= 0) return;

    double remaining = (progress % 1.0) * totalLength;
    ui.Tangent? tangent;
    for (final metric in metrics) {
      if (remaining > metric.length) {
        remaining -= metric.length;
        continue;
      }
      tangent = metric.getTangentForOffset(remaining);
      break;
    }
    if (tangent == null) return;

    final double dotRadius = (w * 0.055).clamp(1.5, 4.0);
    final Paint dotPaint = Paint()
      ..color = refreshDotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tangent.position, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(_SwissBankPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidthFactor != strokeWidthFactor ||
        oldDelegate.refreshDotColor != refreshDotColor ||
        (oldDelegate.refreshProgress == null) != (refreshProgress == null);
  }
}
