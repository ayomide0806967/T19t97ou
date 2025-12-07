import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Modern, clean retweet icon with flowing curved design.
/// Features smooth curves and elegant arrow styling.
class XRetweetIcon extends StatelessWidget {
  const XRetweetIcon({
    super.key,
    this.size = 18,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ModernRetweetPainter(
          color: color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF536471),
        ),
      ),
    );
  }
}

/// Modern retweet button with sleek design and press animation.
class XRetweetButton extends StatefulWidget {
  const XRetweetButton({
    super.key,
    required this.label,
    this.count,
    this.color,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final int? count;
  final Color? color;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<XRetweetButton> createState() => _XRetweetButtonState();
}

class _XRetweetButtonState extends State<XRetweetButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Green when active/reposted, grey otherwise
    final Color primaryColor = widget.isActive 
        ? const Color(0xFF00BA7C) // Vibrant green when reposted
        : (widget.color ?? const Color(0xFF71767B)); // Grey when not reposted
    
    final Color bgColor = Colors.transparent;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              if (widget.count != null) ...[
                const SizedBox(width: 4),
                Text(
                  _formatCount(widget.count!),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// Modern flowing retweet icon painter.
/// Creates elegant curved arrows with smooth transitions.
class _ModernRetweetPainter extends CustomPainter {
  _ModernRetweetPainter({required this.color});
  
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double sw = s * 0.1; // Stroke width
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double cx = s / 2;
    final double cy = s / 2;
    final double radius = s * 0.32;
    
    // Draw two curved arrows flowing in a circle
    // First arrow (top-right, flowing clockwise)
    final path1 = Path();
    final startAngle1 = -math.pi * 0.75;
    final sweepAngle1 = math.pi * 0.9;
    
    path1.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle1,
      sweepAngle1,
    );
    
    // Second arrow (bottom-left, flowing clockwise)
    final path2 = Path();
    final startAngle2 = math.pi * 0.25;
    final sweepAngle2 = math.pi * 0.9;
    
    path2.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle2,
      sweepAngle2,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);

    // Arrow heads
    final double arrowSize = s * 0.18;
    
    // Arrow 1 head (pointing right-down)
    final end1Angle = startAngle1 + sweepAngle1;
    final end1X = cx + radius * math.cos(end1Angle);
    final end1Y = cy + radius * math.sin(end1Angle);
    final arrow1Dir = end1Angle + math.pi / 2;
    
    _drawArrowHead(canvas, fillPaint, end1X, end1Y, arrow1Dir, arrowSize);
    
    // Arrow 2 head (pointing left-up)
    final end2Angle = startAngle2 + sweepAngle2;
    final end2X = cx + radius * math.cos(end2Angle);
    final end2Y = cy + radius * math.sin(end2Angle);
    final arrow2Dir = end2Angle + math.pi / 2;
    
    _drawArrowHead(canvas, fillPaint, end2X, end2Y, arrow2Dir, arrowSize);
  }

  void _drawArrowHead(Canvas canvas, Paint paint, double x, double y, double angle, double size) {
    final path = Path();
    
    // Create a sleek triangular arrow head
    final tipX = x + size * 0.5 * math.cos(angle);
    final tipY = y + size * 0.5 * math.sin(angle);
    
    final base1X = x + size * 0.5 * math.cos(angle + math.pi * 0.75);
    final base1Y = y + size * 0.5 * math.sin(angle + math.pi * 0.75);
    
    final base2X = x + size * 0.5 * math.cos(angle - math.pi * 0.75);
    final base2Y = y + size * 0.5 * math.sin(angle - math.pi * 0.75);
    
    path.moveTo(tipX, tipY);
    path.lineTo(base1X, base1Y);
    path.lineTo(base2X, base2Y);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ModernRetweetPainter old) => old.color != color;
}

/// Alternative minimal style - just the icon without frame
class XRetweetIconMinimal extends StatelessWidget {
  const XRetweetIconMinimal({
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth,
  });

  final double size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MinimalRetweetPainter(
          color: color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF536471),
          strokeWidth: strokeWidth ?? size * 0.1,
        ),
      ),
    );
  }
}

/// Minimal, clean retweet icon with infinity-like flow
class _MinimalRetweetPainter extends CustomPainter {
  _MinimalRetweetPainter({
    required this.color,
    required this.strokeWidth,
  });
  
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create two opposing curved arrows
    final double m = s * 0.15;
    final double h = s * 0.35; // Height of curve
    
    // Top arrow (curves up, points right)
    final topPath = Path()
      ..moveTo(m, s * 0.5)
      ..quadraticBezierTo(s * 0.5, m, s - m - s * 0.1, s * 0.5);
    
    // Bottom arrow (curves down, points left)  
    final bottomPath = Path()
      ..moveTo(s - m, s * 0.5)
      ..quadraticBezierTo(s * 0.5, s - m, m + s * 0.1, s * 0.5);

    canvas.drawPath(topPath, paint);
    canvas.drawPath(bottomPath, paint);

    // Right arrow head
    final double arrowSize = s * 0.12;
    final rightArrow = Path()
      ..moveTo(s - m, s * 0.5)
      ..lineTo(s - m - arrowSize * 1.2, s * 0.5 - arrowSize)
      ..lineTo(s - m - arrowSize * 1.2, s * 0.5 + arrowSize)
      ..close();

    // Left arrow head
    final leftArrow = Path()
      ..moveTo(m, s * 0.5)
      ..lineTo(m + arrowSize * 1.2, s * 0.5 - arrowSize)
      ..lineTo(m + arrowSize * 1.2, s * 0.5 + arrowSize)
      ..close();

    canvas.drawPath(rightArrow, fillPaint);
    canvas.drawPath(leftArrow, fillPaint);
  }

  @override
  bool shouldRepaint(_MinimalRetweetPainter old) => 
      old.color != color || old.strokeWidth != strokeWidth;
}
