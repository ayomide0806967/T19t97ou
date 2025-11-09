import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loop Arrow Icon Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('LoopArrowIcon Demo'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              // Default size (24) – close to the screenshot scale
              LoopArrowIcon(
                size: 24,
                color: Colors.blueGrey,
              ),
              SizedBox(height: 24),
              // Bigger version so you can inspect it
              LoopArrowIcon(
                size: 48,
                color: Colors.blueGrey,
                thickness: 2.4,
                gap: 2.2,
                arrowSeparation: 0.8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loop-style two-arrow icon similar to the screenshot.
class LoopArrowIcon extends StatelessWidget {
  final double size;
  final Color? color;

  /// Stroke thickness at 24x24. Scales with size.
  final double thickness;

  /// Gap between arrowheads and frame in the 24x24 grid.
  final double gap;

  /// Extra separation between the two arrowheads themselves.
  final double arrowSeparation;

  const LoopArrowIcon({
    super.key,
    this.size = 24,
    this.color,
    this.thickness = 2.0,
    this.gap = 2.2,
    this.arrowSeparation = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.black;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LoopArrowPainter(
          iconColor,
          thickness: thickness,
          gap: gap,
          arrowSeparation: arrowSeparation,
        ),
      ),
    );
  }
}

class _LoopArrowPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double gap;
  final double arrowSeparation;

  _LoopArrowPainter(
    this.color, {
    required this.thickness,
    required this.gap,
    required this.arrowSeparation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double baseSize = 24.0;
    final double scale = math.min(size.width, size.height) / baseSize;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = thickness * scale;

    // Center the 24x24 drawing in the given size
    final dx = (size.width - baseSize * scale) / 2;
    final dy = (size.height - baseSize * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    // Main “square” loop with larger gaps near the arrow tips
    final double leftX = 8.0;
    final double rightX = 16.0;
    final double topY = 9.0;
    final double bottomY = 18.0;

    final frame = Path()
      ..moveTo(leftX, bottomY)
      ..lineTo(leftX, topY + gap * 0.9)
      ..moveTo(leftX + gap * 1.8, topY)
      ..lineTo(rightX, topY)
      ..lineTo(rightX, bottomY - gap * 1.2)
      ..moveTo(leftX, bottomY)
      ..lineTo(rightX, bottomY);

    // Arrow heads
    final double sep = arrowSeparation;

    final arrows = Path()
      // top-left up arrow
      ..moveTo(leftX - 0.2 - sep, topY - (gap + 0.8))
      ..lineTo(leftX - 1.8 - sep, topY - (gap - 0.4))
      ..moveTo(leftX - 0.2 - sep, topY - (gap + 0.8))
      ..lineTo(leftX - 1.0 - sep, topY - (gap - 0.4))
      // bottom-right down arrow
      ..moveTo(rightX + 0.2 + sep, bottomY + (gap - 1.0))
      ..lineTo(rightX + 1.6 + sep, bottomY - (gap - 0.6))
      ..moveTo(rightX + 0.2 + sep, bottomY + (gap - 1.0))
      ..lineTo(rightX - 0.6 + sep, bottomY - (gap - 0.6));

    canvas.drawPath(frame, paint);
    canvas.drawPath(arrows, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoopArrowPainter old) =>
      old.color != color ||
      old.thickness != thickness ||
      old.gap != gap ||
      old.arrowSeparation != arrowSeparation;
}

