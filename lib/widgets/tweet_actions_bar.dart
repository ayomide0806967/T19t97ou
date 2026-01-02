import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TweetMetricType { reply, rein, like, view, bookmark, share }

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

class TweetActionsBar extends StatelessWidget {
  const TweetActionsBar({
    super.key,
    required this.leftMetrics,
    required this.share,
    required this.isCompact,
    required this.onTap,
    this.forceContrast = false,
    this.onSurfaceOverride,
  });

  final List<TweetMetricData> leftMetrics; // expects [reply, rein, like, view]
  final TweetMetricData share;
  final bool isCompact;
  final Map<TweetMetricType, VoidCallback> onTap;
  final bool forceContrast;
  final Color? onSurfaceOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final TweetMetricData replyMetric =
        leftMetrics.firstWhere((m) => m.type == TweetMetricType.reply);
    final TweetMetricData reinMetric =
        leftMetrics.firstWhere((m) => m.type == TweetMetricType.rein);
    final TweetMetricData likeMetric =
        leftMetrics.firstWhere((m) => m.type == TweetMetricType.like);
    final TweetMetricData viewMetric =
        leftMetrics.firstWhere((m) => m.type == TweetMetricType.view);
    final List<TweetMetricData> leftGroup = [
      replyMetric,
      reinMetric,
      likeMetric,
      viewMetric,
    ];

    final double tightGap = isCompact ? 8.0 : 10.0;

    Widget row = SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Left group: four equal cells, centered
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < leftGroup.length; i++)
                  Expanded(
                    child: Center(
                      child: TweetMetric(
                        data: leftGroup[i],
                        compact: isCompact,
                        onTap: onTap[leftGroup[i].type] ?? () {},
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: tightGap),
          TweetMetric(
            data: share,
            compact: isCompact,
            onTap: onTap[share.type] ?? () {},
          ),
        ],
      ),
    );

    // Guard tiny rounding overflows on some device widths by adding
    // a subtle right padding that doesn't affect layout.
    row = Padding(padding: const EdgeInsets.only(right: 1), child: row);

    if (!forceContrast || onSurfaceOverride == null) return row;

    final ThemeData overrideTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(onSurface: onSurfaceOverride),
    );
    return Theme(data: overrideTheme, child: row);
  }
}

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
    // Blue-gray neutral for metrics
    final neutral = const Color(0xFF4B6A88);
    // Logo brand orange for special highlight (e.g. bookmark)
    const logoOrange = Color(0xFFFF7A1A);
    final isRein = data.type == TweetMetricType.rein;
    final isLike = data.type == TweetMetricType.like;
    final isShare = data.type == TweetMetricType.share;
    final isBookmark = data.type == TweetMetricType.bookmark;

    double iconSize = compact ? 16.0 : 18.0;
    if (isRein) iconSize -= 4.0;
    if (isBookmark) iconSize -= 2.0;
    if (isShare) iconSize -= 4.0;
    if (isLike) iconSize -= 4.0;
    final double labelFontSize = compact ? 12.0 : 13.0;
    final double countFontSize = compact ? 12.0 : 13.0;
    final double gap = compact ? 4.0 : 5.0;

    // Base icon/text colors
    late final Color iconColor;
    late final Color textColor;
    if (isLike) {
      iconColor = data.isActive ? Colors.red : neutral;
      textColor = neutral;
    } else if (isBookmark) {
      iconColor = data.isActive ? logoOrange : neutral;
      textColor = data.isActive ? logoOrange : neutral;
    } else {
      iconColor = neutral;
      textColor = neutral;
    }
    final hasIcon = data.icon != null || data.type == TweetMetricType.view;
    final metricCount = data.count;
    final bool highlightRein = isRein && data.isActive;
    final String? displayLabel = data.label;
    final double reinFontSize = compact ? 13.5 : 14.5;

    Widget content;

    if (data.type == TweetMetricType.reply) {
      final Color pillText = neutral.withValues(alpha: 0.9);
      final Color pillBorder = neutral.withValues(alpha: 0.6);
      final String? countLabel =
          metricCount != null ? formatMetric(metricCount) : null;
      final String labelText = displayLabel ?? 'COMMENT';
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                fontSize: labelFontSize,
              ),
            ),
            if (countLabel != null) ...[
              const SizedBox(width: 4),
              Text(
                countLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: pillText,
                  fontWeight: FontWeight.w600,
                  fontSize: countFontSize,
                ),
              ),
            ],
          ],
        ),
      );
    } else if (highlightRein) {
      final highlightColor = neutral;
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayLabel ?? 'REPOST',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.w800,
              fontSize: labelFontSize,
              letterSpacing: 0.35,
            ),
          ),
          if (metricCount != null) ...[
            SizedBox(width: gap),
            Text(
              formatMetric(metricCount),
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
              Widget icon = data.type == TweetMetricType.view
                  ? Icon(Icons.signal_cellular_alt_rounded, size: iconSize, color: iconColor)
                  : Icon(data.icon, size: iconSize, color: iconColor);
              return icon;
            })(),
            if (displayLabel != null || metricCount != null)
              SizedBox(width: gap),
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
          if (metricCount != null)
            Text(
              formatMetric(metricCount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: countFontSize,
              ),
            ),
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
          (textColor).withValues(alpha: 0.08),
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
  Widget build(BuildContext context) =>
      ConstrainedBox(constraints: const BoxConstraints(minHeight: 44), child: child);
}

String formatMetric(int value) {
  if (value >= 1000000) {
    final formatted = value / 1000000;
    return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final formatted = value / 1000;
    return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}K';
  }
  return value.toString();
}
