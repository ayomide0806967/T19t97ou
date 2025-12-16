import 'package:flutter/material.dart';

/// Twitter/X-style retweet icon (two arrows forming a loop).
/// Drawn with a CustomPainter so it scales cleanly at any size.
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
        painter: _TwitterRetweetPainter(
          color: color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF536471),
        ),
      ),
    );
  }
}

/// Retweet button styled like Twitter: icon + count (no "REPOST" text).
class XRetweetButton extends StatefulWidget {
  const XRetweetButton({
    super.key,
    required this.label,
    this.count,
    this.color,
    this.isActive = false,
    this.countFontSize = 12,
    this.iconSize = 23,
    this.onTap,
    this.onLongPress,
  });

  final String label;
  final int? count;
  final Color? color;
  final bool isActive;
  final double countFontSize;
  final double iconSize;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<XRetweetButton> createState() => _XRetweetButtonState();
}

class _XRetweetButtonState extends State<XRetweetButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
    // Green when active/reposted, grey otherwise
    final Color primaryColor = widget.isActive 
        ? const Color(0xFF00BA7C) // Vibrant green when reposted
        : (widget.color ?? const Color(0xFF71767B)); // Grey when not reposted
    
    final Color bgColor = Colors.transparent;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () {
          _controller.reverse();
        },
        onLongPressStart: widget.onLongPress == null
            ? null
            : (_) {
                _controller.forward();
              },
        onLongPress: widget.onLongPress,
        onLongPressEnd: widget.onLongPress == null
            ? null
            : (_) {
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: Colors.transparent,
                width: 1.5,
              ),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  XRetweetIcon(size: widget.iconSize, color: primaryColor),
                  if (widget.count != null) ...[
                    const SizedBox(width: 9),
                    Text(
                      _formatCount(widget.count!),
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: widget.countFontSize,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

class _TwitterRetweetPainter extends CustomPainter {
  _TwitterRetweetPainter({required this.color});
  
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double sw = s * 0.08;

    final Paint stroke = Paint()
      ..color = color
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Two separate bent arrows with an even more visible gap between them
    final double margin = s * 0.10;
    final double topY = s * 0.28;
    final double bottomY = s * 0.72;
    final double leftX = margin;
    final double rightX = s - margin;
    final double cornerR = s * 0.14;
    final double arrowSize = s * 0.18;
    final double headSize = arrowSize * 1.4; // heavier arrowhead
    final double gapOffset = s * 0.24; // Increased vertical gap between arrows

    // ===== ARROW 1: Top-right pointing arrow =====
    // Starts from lower-left, goes up, curves right, ends with right arrowhead
    final Path arrow1 = Path()
      // Start below midpoint on left side
      ..moveTo(leftX, bottomY - gapOffset)
      // Go up
      ..lineTo(leftX, topY + cornerR)
      // Curve to horizontal, then straight line
      ..quadraticBezierTo(leftX, topY, leftX + cornerR, topY)
      ..lineTo(rightX - arrowSize * 0.8, topY);
    canvas.drawPath(arrow1, stroke);

    // Right-pointing arrowhead (top arrow)
    final Path headRight = Path()
      ..moveTo(rightX, topY)
      ..lineTo(rightX - headSize, topY - headSize * 0.5)
      ..lineTo(rightX - headSize, topY + headSize * 0.5)
      ..close();
    canvas.drawPath(headRight, fill);

    // ===== ARROW 2: Bottom-left pointing arrow =====
    // Starts from upper-right, goes down, curves left, ends with left arrowhead
    final Path arrow2 = Path()
      // Start above midpoint on right side
      ..moveTo(rightX, topY + gapOffset)
      // Go down
      ..lineTo(rightX, bottomY - cornerR)
      // Curve to horizontal, then straight line
      ..quadraticBezierTo(rightX, bottomY, rightX - cornerR, bottomY)
      ..lineTo(leftX + arrowSize * 0.8, bottomY);
    canvas.drawPath(arrow2, stroke);

    // Left-pointing arrowhead (bottom arrow)
    final Path headLeft = Path()
      ..moveTo(leftX, bottomY)
      ..lineTo(leftX + headSize, bottomY - headSize * 0.5)
      ..lineTo(leftX + headSize, bottomY + headSize * 0.5)
      ..close();
    canvas.drawPath(headLeft, fill);
  }

  @override
  bool shouldRepaint(_TwitterRetweetPainter old) => old.color != color;
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

/// Minimal, clean retweet icon matching X/Twitter style
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

    // Two separate bent arrows with gap between them
    final double margin = s * 0.10;
    final double topY = s * 0.28;
    final double bottomY = s * 0.72;
    final double leftX = margin;
    final double rightX = s - margin;
    final double cornerR = s * 0.14;
    final double arrowSize = s * 0.18;
    final double headSize = arrowSize * 1.4; // heavier arrowhead
    final double gapOffset = s * 0.24; // Increased vertical gap (match main icon)

    // Arrow 1: goes up-left, curves right, ends with right arrowhead
    final Path arrow1 = Path()
      ..moveTo(leftX, bottomY - gapOffset)
      ..lineTo(leftX, topY + cornerR)
      ..quadraticBezierTo(leftX, topY, leftX + cornerR, topY)
      ..lineTo(rightX - arrowSize * 0.8, topY);
    canvas.drawPath(arrow1, paint);

    // Right arrowhead
    final Path headRight = Path()
      ..moveTo(rightX, topY)
      ..lineTo(rightX - headSize, topY - headSize * 0.5)
      ..lineTo(rightX - headSize, topY + headSize * 0.5)
      ..close();
    canvas.drawPath(headRight, fillPaint);

    // Arrow 2: goes down-right, curves left, ends with left arrowhead
    final Path arrow2 = Path()
      ..moveTo(rightX, topY + gapOffset)
      ..lineTo(rightX, bottomY - cornerR)
      ..quadraticBezierTo(rightX, bottomY, rightX - cornerR, bottomY)
      ..lineTo(leftX + arrowSize * 0.8, bottomY);
    canvas.drawPath(arrow2, paint);

    // Left arrowhead
    final Path headLeft = Path()
      ..moveTo(leftX, bottomY)
      ..lineTo(leftX + headSize, bottomY - headSize * 0.5)
      ..lineTo(leftX + headSize, bottomY + headSize * 0.5)
      ..close();
    canvas.drawPath(headLeft, fillPaint);
  }

  @override
  bool shouldRepaint(_MinimalRetweetPainter old) => 
      old.color != color || old.strokeWidth != strokeWidth;
}
