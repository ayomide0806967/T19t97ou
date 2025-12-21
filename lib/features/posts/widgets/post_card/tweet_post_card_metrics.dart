part of 'tweet_post_card.dart';

class _ReinOptionTile extends StatelessWidget {
  const _ReinOptionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
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
              child: Icon(icon, color: iconColor, size: 20),
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

class TweetMetric extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTheme.accent;
    final neutral = AppTheme.textSecondary;
    final isRein = data.type == TweetMetricType.rein;
    final isLike = data.type == TweetMetricType.like;
    final isShare = data.type == TweetMetricType.share;
    final isBookmark = data.type == TweetMetricType.bookmark;

    double iconSize = compact ? 16.0 : 18.0;
    if (isShare || isBookmark) iconSize += 2.0;
    final double labelFontSize = compact ? 12.0 : 13.0;
    final double countFontSize = compact ? 10.0 : 11.0;
    final double gap = compact ? 1.0 : 2.0;

    final Color activeColor =
        isRein ? Colors.green : (isLike ? Colors.red : accent);
    final baseColor = data.isActive ? activeColor : neutral;
    final Color iconColor =
        isLike ? (data.isActive ? activeColor : neutral) : baseColor;
    final Color textColor = isLike ? neutral : baseColor;
    final hasIcon = data.icon != null || data.type == TweetMetricType.view;
    final int? metricCount =
        (data.count != null && data.count! > 0) ? data.count : null;
    final bool highlightRein = isRein && data.isActive;
    final String? displayLabel = data.label;
    final double reinFontSize = compact ? 13.5 : 14.5;

    Widget content;

    if (data.type == TweetMetricType.reply) {
      final Color pillText =
          theme.colorScheme.onSurface.withValues(alpha: 0.45);
      final Color pillBorder = theme.dividerColor.withValues(alpha: 0.9);
      final String? countLabel =
          metricCount != null ? _formatMetric(metricCount) : null;
      final String labelText = data.label ?? 'COMMENT';
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
                fontSize: compact ? 11.0 : 12.0,
              ),
            ),
            if (countLabel != null) ...[
              const SizedBox(width: 4),
              Text(
                countLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: pillText,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11.0 : 12.0,
                ),
              ),
            ],
          ],
        ),
      );
      content = pill;
    } else if (highlightRein) {
      final highlightColor = Colors.green;
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
              if (data.type == TweetMetricType.view) {
                icon = Icon(
                  Icons.signal_cellular_alt_rounded,
                  size: iconSize,
                  color: iconColor,
                );
              } else if (data.type == TweetMetricType.rein) {
                icon = XRetweetIcon(size: iconSize, color: iconColor);
              } else {
                icon = Icon(data.icon, size: iconSize, color: iconColor);
              }
              if (isLike) {
                icon = AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutBack,
                  scale: data.isActive ? 1.18 : 1.0,
                  child: icon,
                );
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
              if (isLike || data.type == TweetMetricType.view) {
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

    return TextButton(
      onPressed: onTap,
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

