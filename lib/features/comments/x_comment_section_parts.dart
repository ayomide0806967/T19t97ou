part of 'x_comment_section.dart';

class _XCommentTile extends StatefulWidget {
  const _XCommentTile({
    required this.comment,
    required this.onReply,
    required this.onLike,
  });

  final XComment comment;
  final VoidCallback onReply;
  final VoidCallback onLike;

  @override
  State<_XCommentTile> createState() => _XCommentTileState();
}

class _XCommentTileState extends State<_XCommentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  String _formatCount(int value) {
    if (value >= 1000000) {
      final formatted = value / 1000000;
      return formatted >= 10
          ? '${formatted.toStringAsFixed(0)}M'
          : '${formatted.toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final formatted = value / 1000;
      return formatted >= 10
          ? '${formatted.toStringAsFixed(0)}K'
          : '${formatted.toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color textColor = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : Colors.black.withValues(alpha: 0.9);
    final Color metaTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    const double avatarSize = 36;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Card + reply text, shifted right so the avatar cuts into the left edge.
              Container(
                margin: const EdgeInsets.only(left: avatarSize / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 1,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: isDark ? 0.28 : 0.12,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 10, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.comment.author,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        textColor.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.comment.body,
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.comment.timeAgo,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontSize: 10,
                                        color: metaTextColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: widget.onLike,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.comment.isLiked
                                                ? Icons.favorite_rounded
                                                : Icons
                                                    .favorite_border_rounded,
                                            size: 14,
                                            color: widget.comment.isLiked
                                                ? Colors.red
                                                : metaTextColor,
                                          ),
                                          if (widget.comment.likes > 0) ...[
                                            const SizedBox(width: 3),
                                            Text(
                                              _formatCount(
                                                  widget.comment.likes),
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 10,
                                                color: metaTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: isDark ? 0.28 : 0.12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: widget.onReply,
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Picture-frame avatar overlapping the card's left edge.
              Positioned(
                left: 0,
                top: 8,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.comment.avatarColors,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.comment.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _XActionButton extends StatefulWidget {
  const _XActionButton({
    required this.icon,
    this.customIcon,
    this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final Widget? customIcon;
  final String? label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  State<_XActionButton> createState() => _XActionButtonState();
}

class _XActionButtonState extends State<_XActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.isActive
        ? Colors.redAccent
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);

    // Responsive scaling based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    // Scale icon size based on device type
    final iconSize = isMobile ? 24.0 : (isTablet ? 26.0 : 28.0);
    final horizontalPadding = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
    final verticalPadding = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);
    final minTapTarget = isMobile ? 48.0 : (isTablet ? 52.0 : 56.0);

    final Widget iconWidget = widget.customIcon ??
        Icon(
          widget.icon,
          size: iconSize,
          color: baseColor,
        );

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              constraints: BoxConstraints(
                minWidth: minTapTarget,
                minHeight: minTapTarget,
              ),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
	              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
	                  iconWidget,
                  if (widget.label != null) ...[
                    SizedBox(width: isMobile ? 6.0 : 8.0),
                    Text(
                      widget.label!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: baseColor,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13.0 : 14.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class XPostMetrics {
  const XPostMetrics({
    required this.replyCount,
    required this.reposts,
    required this.likes,
    required this.bookmarks,
    required this.views,
  });

  final int replyCount;
  final int reposts;
  final int likes;
  final int bookmarks;
  final int views;
}

class _XMetricsRow extends StatelessWidget {
  const _XMetricsRow({required this.metrics});

  final XPostMetrics metrics;

  String _formatCount(int value) {
    if (value >= 1000000) {
      final formatted = value / 1000000;
      return formatted >= 10
          ? '${formatted.toStringAsFixed(0)}M'
          : '${formatted.toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final formatted = value / 1000;
      return formatted >= 10
          ? '${formatted.toStringAsFixed(0)}K'
          : '${formatted.toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
    );
    final isDark = theme.brightness == Brightness.dark;
    // Use neutral greys for the Views chip instead of accent/cyan.
    final Color chipBackground = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final Color chipContent = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.85 : 0.7,
    );
    final chipTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: chipContent,
      fontWeight: FontWeight.w600,
    );

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${_formatCount(metrics.reposts)} Reposts', style: labelStyle),
        Text('${_formatCount(metrics.replyCount)} Replies', style: labelStyle),
        Text('${_formatCount(metrics.likes)} Likes', style: labelStyle),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 16, color: chipContent),
              const SizedBox(width: 6),
              Text(
                '${_formatCount(metrics.views)} views',
                style: chipTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class XQuotedPost {
  const XQuotedPost({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
}

class _XQuotedPostCard extends StatelessWidget {
  const _XQuotedPostCard({required this.quoted});

  final XQuotedPost quoted;

  String get _normalizedHandle => quoted.handle.startsWith('@')
      ? quoted.handle
      : '@${quoted.handle.replaceAll(' ', '').toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.accent.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quoted.author,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _normalizedHandle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '·',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                quoted.timeAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quoted.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class XComment {
  XComment({
    required this.id,
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    required this.avatarColors,
    this.likes = 0,
    this.isLiked = false,
  });

  final String id;
  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final List<Color> avatarColors;
  int likes;
  bool isLiked;

  String get initials {
    final parts = author.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

