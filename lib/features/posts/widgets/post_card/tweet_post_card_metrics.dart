part of 'tweet_post_card.dart';

class _ReinOptionTile extends StatelessWidget {
  const _ReinOptionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  /// Icon widget (e.g. XRetweetIcon, XCommentIcon) to match metrics styling.
  final Widget icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconBackground = theme.colorScheme.primary.withValues(
      alpha: isDark ? 0.18 : 0.12,
    );
    final Color iconColor = theme.colorScheme.primary;
    final TextStyle? titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(color: iconColor, size: 20),
                  child: icon,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: titleStyle),
                  const SizedBox(height: 4),
                  Text(description, style: bodyStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TweetMetricData {
  const TweetMetricData({
    required this.type,
    this.icon,
    this.count,
    this.label,
    this.isActive = false,
  });

  final TweetMetricType type;
  final IconData? icon;
  final int? count;
  final String? label;
  final bool isActive;
}

enum TweetMetricType { reply, rein, like, view, bookmark, share }

class _TweetMetricSizing {
  const _TweetMetricSizing._();

  // Repost is the visual baseline (largest) in the main feed.
  static double repostIconSize(bool compact) => compact ? 19.0 : 21.0;

  // Slightly smaller for comment/like/share so repost remains the anchor.
  static double defaultIconSize(bool compact) => compact ? 19.0 : 21.0;

  static double countFontSize(bool compact) => compact ? 12.0 : 13.0;
}

class TweetMetric extends StatefulWidget {
  const TweetMetric({
    super.key,
    required this.data,
    required this.onTap,
    required this.compact,
  });

  final TweetMetricData data;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<TweetMetric> createState() => _TweetMetricState();
}

class _TweetMetricState extends State<TweetMetric>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      duration: const Duration(milliseconds: 500), // Slower for noticeable effect
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    // Pop-out and return animation: scales up to 1.4 then back to 1.0
    _popAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 65),
    ]).animate(_popController);
  }

  @override
  void dispose() {
    _popController.stop();
    _popController.dispose();
    super.dispose();
  }

  void _triggerPopAnimation() {
    _popController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTheme.accent;
    // Blue-gray neutral for metrics
    final neutral = const Color(0xFF4B6A88);
    // Logo brand orange for special highlight (e.g. bookmark)
    const logoOrange = Color(0xFFFF7A1A);
    final isRein = widget.data.type == TweetMetricType.rein;
    final isLike = widget.data.type == TweetMetricType.like;
    final isShare = widget.data.type == TweetMetricType.share;
    final isBookmark = widget.data.type == TweetMetricType.bookmark;

    final double iconSize = _TweetMetricSizing.defaultIconSize(widget.compact) -
        (isShare ? 4.0 : 0.0) -
        (isLike ? 4.0 : 0.0) -
        (isBookmark ? 2.0 : 0.0);
    final double labelFontSize = _TweetMetricSizing.countFontSize(widget.compact);
    final double countFontSize = _TweetMetricSizing.countFontSize(widget.compact);
    final double gap = widget.compact ? 1.0 : 2.0;

    // Base icon/text colors
    late final Color iconColor;
    late final Color textColor;
    if (isLike) {
      // Like uses red when active, neutral otherwise
      iconColor = widget.data.isActive ? Colors.red : neutral;
      textColor = neutral;
    } else if (isBookmark) {
      // Bookmark uses logo orange when active
      iconColor = widget.data.isActive ? logoOrange : neutral;
      textColor = widget.data.isActive ? logoOrange : neutral;
    } else {
      // Other metrics stay blue-gray
      iconColor = neutral;
      textColor = neutral;
    }
    final hasIcon = widget.data.icon != null || widget.data.type == TweetMetricType.view;
    final int? metricCount =
        (widget.data.count != null && widget.data.count! > 0) ? widget.data.count : null;
    final bool highlightRein = isRein && widget.data.isActive;
    final String? displayLabel = widget.data.label;
    final double reinFontSize = widget.compact ? 13.5 : 14.5;

    Widget content;

    if (widget.data.type == TweetMetricType.reply) {
      final Color pillText = neutral.withValues(alpha: 0.9);
      final Color pillBorder = neutral.withValues(alpha: 0.6);
      final String? countLabel =
          metricCount != null ? _formatMetric(metricCount) : null;
      final String labelText = widget.data.label ?? 'COMMENT';
      final Widget pill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: pillBorder, width: 1),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: pillText,
                fontWeight: FontWeight.w600,
                fontSize: widget.compact ? 11.0 : 12.0,
              ),
            ),
            if (countLabel != null) ...[
              const SizedBox(width: 4),
              Text(
                countLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: pillText,
                  fontWeight: FontWeight.w600,
                  fontSize: widget.compact ? 11.0 : 12.0,
                ),
              ),
            ],
          ],
        ),
      );
      content = pill;
    } else if (highlightRein) {
      final highlightColor = neutral;
      final Color labelColor = neutral;
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          XRetweetIcon(size: iconSize, color: highlightColor),
          SizedBox(width: gap),
          Text(
            displayLabel ?? 'REPOST',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w800,
              fontSize: labelFontSize,
              letterSpacing: 0.35,
            ),
          ),
          if (metricCount != null) ...[
            SizedBox(width: gap),
            Text(
              _formatMetric(metricCount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: highlightColor,
                fontWeight: FontWeight.w600,
                fontSize: countFontSize,
              ),
            ),
          ],
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasIcon) ...[
            (() {
              Widget icon;
              if (widget.data.type == TweetMetricType.view) {
                icon = Icon(
                  Icons.signal_cellular_alt_rounded,
                  size: iconSize,
                  color: iconColor,
                );
              } else if (widget.data.type == TweetMetricType.rein) {
                icon = XRetweetIcon(size: iconSize, color: iconColor);
              } else if (widget.data.type == TweetMetricType.share) {
                // Use custom share icon matching Instagram style
                icon = XShareIcon(size: iconSize, color: iconColor);
              } else {
                icon = Icon(widget.data.icon, size: iconSize, color: iconColor);
              }
              return icon;
            })(),
            if (displayLabel != null || metricCount != null) SizedBox(width: gap),
          ],
          if (displayLabel != null) ...[
            Text(
              displayLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isRein ? FontWeight.w700 : FontWeight.w600,
                fontSize: isRein ? reinFontSize : labelFontSize,
                letterSpacing: isRein ? 0.3 : null,
              ),
            ),
            if (metricCount != null) SizedBox(width: gap),
          ],
          if (metricCount != null) ...[
            (() {
              final text = Text(
                _formatMetric(metricCount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: countFontSize,
                  height: 1.1,
                ),
              );
              if (isLike || widget.data.type == TweetMetricType.view) {
                return SizedBox(
                  height: iconSize,
                  child: Center(child: text),
                );
              }
              return text;
            })(),
          ],
        ],
      );
    }

    // For like/bookmark buttons: use GestureDetector with pop-out animation instead of highlight
    if (isLike || isBookmark) {
      return GestureDetector(
        onTap: _triggerPopAnimation,
        child: AnimatedBuilder(
          animation: _popAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _popAnimation.value,
              child: child,
            );
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      );
    }

    return TextButton(
      onPressed: widget.onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 44),
        alignment: Alignment.center,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: textColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(
          iconColor.withValues(alpha: 0.08),
        ),
      ),
      child: content,
    );
  }
}

class _EdgeCell extends StatelessWidget {
  const _EdgeCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: child,
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? Colors.white.withAlpha(14) : const Color(0xFFF6F7F9);
    final textColor =
        isDark ? Colors.white.withAlpha(170) : const Color(0xFF4B5563);

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w500,
        fontSize: 10,
        letterSpacing: 0.1,
      ),
      backgroundColor: background,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
