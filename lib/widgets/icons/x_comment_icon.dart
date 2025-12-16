import 'package:flutter/material.dart';

/// X/Twitter-style comment/reply icon.
/// A rounded chat bubble with a small tail on the bottom-left.
class XCommentIcon extends StatelessWidget {
  const XCommentIcon({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _XCommentPainter(
          color:
              color ??
              Theme.of(context).iconTheme.color ??
              const Color(0xFF536471),
        ),
      ),
    );
  }
}

/// Custom painter for the X-style comment bubble icon.
class _XCommentPainter extends CustomPainter {
  _XCommentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double sw = s * 0.085; // Stroke width

    final paint = Paint()
      ..color = color
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Dimensions for the bubble
    final double padding = sw;
    final double bubbleHeight = s * 0.72;
    final double cornerRadius = s * 0.22;
    final double tailSize = s * 0.15;

    // Create the bubble path
    final path = Path();

    // Starting from bottom-left, just after the tail
    final double left = padding;
    final double top = padding;
    final double right = s - padding;
    final double bottom = top + bubbleHeight;

    // Top-left corner
    path.moveTo(left + cornerRadius, top);

    // Top edge
    path.lineTo(right - cornerRadius, top);

    // Top-right corner
    path.arcToPoint(
      Offset(right, top + cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Right edge
    path.lineTo(right, bottom - cornerRadius);

    // Bottom-right corner
    path.arcToPoint(
      Offset(right - cornerRadius, bottom),
      radius: Radius.circular(cornerRadius),
    );

    // Bottom edge (with tail gap)
    path.lineTo(left + tailSize * 2.5, bottom);

    // Tail (pointing down-left)
    path.lineTo(left + tailSize * 0.5, bottom + tailSize);
    path.lineTo(left + tailSize * 1.2, bottom);

    // Continue bottom edge
    path.lineTo(left + cornerRadius, bottom);

    // Bottom-left corner
    path.arcToPoint(
      Offset(left, bottom - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Left edge
    path.lineTo(left, top + cornerRadius);

    // Top-left corner (closing)
    path.arcToPoint(
      Offset(left + cornerRadius, top),
      radius: Radius.circular(cornerRadius),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_XCommentPainter old) => old.color != color;
}

/// X-style comment button with icon + count, matching the XRetweetButton style.
class XCommentButton extends StatefulWidget {
  const XCommentButton({
    super.key,
    this.count,
    this.color,
    this.isActive = false,
    this.onTap,
  });

  final int? count;
  final Color? color;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<XCommentButton> createState() => _XCommentButtonState();
}

class _XCommentButtonState extends State<XCommentButton>
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Blue when active, grey otherwise (X uses blue for replies)
    final Color primaryColor = widget.isActive
        ? const Color(0xFF1D9BF0) // X blue when active
        : (widget.color ?? const Color(0xFF71767B)); // Grey otherwise

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              XCommentIcon(size: 16, color: primaryColor),
              if (widget.count != null && widget.count! > 0) ...[
                const SizedBox(width: 1),
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
