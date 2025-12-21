part of '../ios_messages_screen.dart';

class _LabelCountButton extends StatefulWidget {
  const _LabelCountButton({
    required this.count,
    required this.onPressed,
    this.icon,
    this.color,
    this.iconSize,
  });
  final IconData? icon;
  final int count;
  final VoidCallback onPressed;
  final Color? color;
  final double? iconSize;

  @override
  State<_LabelCountButton> createState() => _LabelCountButtonState();
}

class _LabelCountButtonState extends State<_LabelCountButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color meta =
        widget.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 1.08 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final bool veryTight = maxW.isFinite && maxW < 34;
            final bool ultraTight = maxW.isFinite && maxW < 28;
            final double padH = ultraTight ? 4 : (veryTight ? 6 : 10);
            final double gap = ultraTight ? 2 : (veryTight ? 3 : 6);
            final TextStyle? countStyle = theme.textTheme.bodySmall?.copyWith(
              color: meta,
            );

            Widget inner = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: widget.iconSize ?? 18, color: meta),
                  SizedBox(width: gap),
                ],
                Text('${widget.count}', style: countStyle),
              ],
            );

            // Scale down the row content if width becomes too tight
            inner = FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: inner,
            );

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onPressed,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padH, vertical: 6),
                child: inner,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  const _ScaleTap({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: widget.child,
    );
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 1.08 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: child,
        ),
      ),
    );
  }
}

class _EmojiReactionChip extends StatelessWidget {
  const _EmojiReactionChip({
    required this.emoji,
    required this.count,
    this.isActive = false,
    this.onTap,
  });

  final String emoji;
  final int count;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isHeart = emoji == '❤️';
    final Color fg = isHeart
        ? Colors.red
        : (isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.8));

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(emoji, style: TextStyle(fontSize: 14, color: fg))],
      ),
    );
  }
}
