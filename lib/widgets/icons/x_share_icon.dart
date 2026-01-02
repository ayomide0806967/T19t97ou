import 'package:flutter/material.dart';

/// Instagram-style share icon (paper airplane arrow pointing up-right).
/// Drawn with a CustomPainter so it scales cleanly at any size.
class XShareIcon extends StatelessWidget {
  const XShareIcon({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShareIconPainter(
          color:
              color ??
              Theme.of(context).iconTheme.color ??
              const Color(0xFF536471),
        ),
      ),
    );
  }
}

class _ShareIconPainter extends CustomPainter {
  _ShareIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double sw = s * 0.09; // stroke width

    final Paint stroke = Paint()
      ..color = color
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // iOS-style share icon: upward arrow + tray at bottom
    final double margin = s * 0.12; // reduced from 0.18 for wider icon
    final double centerX = s / 2;
    
    // Arrow pointing up (shifted further down inside the tray)
    final double arrowTop = s * 0.18;
    final double arrowBottom = s * 0.65;
    // Slightly shorter arrow head wings so they don't flare out as much.
    final double arrowWidth = s * 0.16;
    
    // Draw the vertical line of arrow
    final Path arrowLine = Path()
      ..moveTo(centerX, arrowTop)
      ..lineTo(centerX, arrowBottom);
    canvas.drawPath(arrowLine, stroke);
    
    // Draw the arrow head (chevron pointing up)
    final Path arrowHead = Path()
      ..moveTo(centerX - arrowWidth, arrowTop + arrowWidth)
      ..lineTo(centerX, arrowTop)
      ..lineTo(centerX + arrowWidth, arrowTop + arrowWidth);
    canvas.drawPath(arrowHead, stroke);
    
    // Draw the tray/box at bottom (U-shape)
    // Raise trayTop a bit more so the vertical "legs" are shorter.
    final double trayTop = s * 0.62;
    final double trayBottom = s - margin;
    final double trayLeft = margin;
    final double trayRight = s - margin;
    final double cornerRadius = s * 0.08;
    
    final Path tray = Path()
      ..moveTo(trayLeft, trayTop)
      ..lineTo(trayLeft, trayBottom - cornerRadius)
      ..quadraticBezierTo(trayLeft, trayBottom, trayLeft + cornerRadius, trayBottom)
      ..lineTo(trayRight - cornerRadius, trayBottom)
      ..quadraticBezierTo(trayRight, trayBottom, trayRight, trayBottom - cornerRadius)
      ..lineTo(trayRight, trayTop);
    canvas.drawPath(tray, stroke);
  }

  @override
  bool shouldRepaint(_ShareIconPainter old) => old.color != color;
}
