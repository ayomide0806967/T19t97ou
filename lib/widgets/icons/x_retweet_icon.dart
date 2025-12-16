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
    final double sw = s * 0.06; // lighter shaft weight

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
    final double headSize = arrowSize * 1.0; // smaller chevron head, still cleanly centered
    final double gapOffset = s * 0.18; // Reduced vertical gap between arrows
    // Horizontal shaft geometry so the curve and shaft meet the arrowheads centrally.
    final double bodyTopStart = leftX + cornerR;
    // Shaft ends at the center of the head base, leaving equal space above/below.
    final double bodyTopEnd = rightX - headSize;
    final double bodyTopCurveStart =
        bodyTopEnd - (bodyTopEnd - bodyTopStart) * 0.3; // last 30% curved
    final double bodyBottomStart = rightX - cornerR;
    // Shaft ends at the center of the left head base.
    final double bodyBottomEnd = leftX + headSize;
    final double bodyBottomCurveStart =
        bodyBottomEnd + (bodyBottomStart - bodyBottomEnd) * 0.3;

    // ===== ARROW 1: Top-right pointing arrow =====
    // Starts from lower-left, goes up, runs mostly straight, then eases into a curve only near the head.
    final double upShift = s * 0.03; // nudge up arrow slightly to the right
    final Path arrow1 = Path()
      // Start below midpoint on left side
      ..moveTo(leftX + upShift, bottomY - gapOffset)
      // Go straight up close to the head, then ease into the horizontal
      ..lineTo(leftX + upShift, topY + cornerR * 0.4)
      ..quadraticBezierTo(leftX + upShift, topY, bodyTopStart, topY)
      // Straight horizontal segment before the head-side curve
      ..lineTo(bodyTopCurveStart, topY)
      // Gentle curve only near the head side
      ..quadraticBezierTo(
        bodyTopEnd + s * 0.02,
        topY - s * 0.04,
        bodyTopEnd,
        topY,
      );
    canvas.drawPath(arrow1, stroke);

    // Right-pointing arrowhead (top arrow) rendered as a stroked chevron "<"
    final double headHalfHeight = headSize * 0.5;
    final double shaftEndTop = bodyTopEnd;
    final double tipLeftTopMain = shaftEndTop - headSize;
    final Path headRight = Path()
      // upper arm of "<"
      ..moveTo(shaftEndTop, topY)
      ..lineTo(tipLeftTopMain, topY - headHalfHeight)
      // lower arm of "<"
      ..moveTo(shaftEndTop, topY)
      ..lineTo(tipLeftTopMain, topY + headHalfHeight);
    canvas.drawPath(headRight, stroke);

    // ===== ARROW 2: Bottom-left pointing arrow =====
    // Starts from upper-right, goes down, runs mostly straight, then eases into a curve only near the head.
    final double downShift = s * 0.03; // nudge down arrow slightly to the left
    final Path arrow2 = Path()
      // Start above midpoint on right side
      ..moveTo(rightX - downShift, topY + gapOffset)
      // Straight down close to the head, then ease into the horizontal
      ..lineTo(rightX - downShift, bottomY - cornerR * 0.4)
      ..quadraticBezierTo(rightX - downShift, bottomY, bodyBottomStart, bottomY)
      // Straight horizontal segment before the head-side curve
      ..lineTo(bodyBottomCurveStart, bottomY)
      // Gentle curve only near the head side
      ..quadraticBezierTo(
        bodyBottomEnd - s * 0.02,
        bottomY + s * 0.04,
        bodyBottomEnd,
        bottomY,
      );
    canvas.drawPath(arrow2, stroke);

    // Left-pointing arrowhead (bottom arrow) rendered as a stroked chevron ">"
    final double shaftEndBottom = bodyBottomEnd;
    final double tipRightBottomMain = shaftEndBottom + headSize;
    final Path headLeft = Path()
      // upper arm of ">"
      ..moveTo(shaftEndBottom, bottomY)
      ..lineTo(tipRightBottomMain, bottomY - headHalfHeight)
      // lower arm of ">"
      ..moveTo(shaftEndBottom, bottomY)
      ..lineTo(tipRightBottomMain, bottomY + headHalfHeight);
    canvas.drawPath(headLeft, stroke);
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
          strokeWidth: strokeWidth ?? size * 0.07, // lighter default shaft weight
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
    final double headSize = arrowSize * 1.0; // smaller chevron head, still cleanly centered
    final double gapOffset = s * 0.18; // Reduced vertical gap (match main icon)

    // Arrow 1: goes up-left, runs mostly straight, then eases into a curve only near the head
    final double bodyTopStart = leftX + cornerR;
    final double bodyTopEnd = rightX - headSize;
    final double bodyTopCurveStart =
        bodyTopEnd - (bodyTopEnd - bodyTopStart) * 0.3;
    final double upShift = s * 0.03; // nudge up arrow slightly to the right
    final Path arrow1 = Path()
      ..moveTo(leftX + upShift, bottomY - gapOffset)
      ..lineTo(leftX + upShift, topY + cornerR * 0.4)
      ..quadraticBezierTo(leftX + upShift, topY, bodyTopStart, topY)
      ..lineTo(bodyTopCurveStart, topY)
      ..quadraticBezierTo(
        bodyTopEnd + s * 0.02,
        topY - s * 0.04,
        bodyTopEnd,
        topY,
      );
    canvas.drawPath(arrow1, paint);

    // Right arrowhead rendered as stroked chevron "<"
    final double headHalfHeight = headSize * 0.5;
    final double shaftEndTop = bodyTopEnd;
    final double tipLeftTop = shaftEndTop - headSize;
    final Path headRight = Path()
      ..moveTo(shaftEndTop, topY)
      ..lineTo(tipLeftTop, topY - headHalfHeight)
      ..moveTo(shaftEndTop, topY)
      ..lineTo(tipLeftTop, topY + headHalfHeight);
    canvas.drawPath(headRight, paint);

    // Arrow 2: goes down-right, runs mostly straight, then eases into a curve only near the head
    final double bodyBottomStart = rightX - cornerR;
    final double bodyBottomEnd = leftX + headSize;
    final double bodyBottomCurveStart =
        bodyBottomEnd + (bodyBottomStart - bodyBottomEnd) * 0.3;
    final double downShift = s * 0.03; // nudge down arrow slightly to the left
    final Path arrow2 = Path()
      ..moveTo(rightX - downShift, topY + gapOffset)
      ..lineTo(rightX - downShift, bottomY - cornerR * 0.4)
      ..quadraticBezierTo(rightX - downShift, bottomY, bodyBottomStart, bottomY)
      ..lineTo(bodyBottomCurveStart, bottomY)
      ..quadraticBezierTo(
        bodyBottomEnd - s * 0.02,
        bottomY + s * 0.04,
        bodyBottomEnd,
        bottomY,
      );
    canvas.drawPath(arrow2, paint);

    // Left arrowhead rendered as stroked chevron ">"
    final double shaftEndBottom = bodyBottomEnd;
    final double tipRightBottom = shaftEndBottom + headSize;
    final Path headLeft = Path()
      ..moveTo(shaftEndBottom, bottomY)
      ..lineTo(tipRightBottom, bottomY - headHalfHeight)
      ..moveTo(shaftEndBottom, bottomY)
      ..lineTo(tipRightBottom, bottomY + headHalfHeight);
    canvas.drawPath(headLeft, paint);
  }

  @override
  bool shouldRepaint(_MinimalRetweetPainter old) => 
      old.color != color || old.strokeWidth != strokeWidth;
}
