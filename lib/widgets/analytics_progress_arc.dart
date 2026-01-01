import 'package:flutter/material.dart';

class AnalyticsProgressArc extends StatelessWidget {
  const AnalyticsProgressArc({
    super.key,
    required this.averageScore,
    required this.completionRate,
    required this.totalResponses,
    this.leading,
    this.title,
  });

  final double averageScore;
  final double completionRate;
  final int totalResponses;
  final Widget? leading;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final ColorScheme colorScheme = theme.colorScheme;

    const Color passGreen = Color(0xFF25D366);
    const Color passRed = Color(0xFFDC2626);
    final Color cardColor = isDark ? colorScheme.surface : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title ?? 'Quiz analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 12),
          _BarChartSummary(
            averageScore: averageScore,
            completionRate: completionRate,
            totalResponses: totalResponses,
            // Pass uses brand orange; Fail uses red.
            failColor: passRed,
            passColor: passGreen,
          ),
        ],
      ),
    );
  }
}

// _SmallMetricItem was unused; removed to keep this widget focused.

class _BarChartSummary extends StatelessWidget {
  const _BarChartSummary({
    required this.averageScore,
    required this.completionRate,
    required this.totalResponses,
    required this.failColor,
    required this.passColor,
  });

  final double averageScore;
  final double completionRate;
  final int totalResponses;
  final Color failColor;
  final Color passColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color bgBar = theme.dividerColor.withValues(alpha: 0.25);

    final double passPercent = (completionRate * 100).clamp(0, 100);
    final double failPercent = (averageScore).clamp(0, 100);
    final double remainingPercent =
        (100 - passPercent - failPercent).clamp(0, 100);

    Widget buildBar({
      required String label,
      required double percent,
      required Color color,
      double? visualPercent,
      Color? trackColor,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: (visualPercent ?? percent) / 100,
                backgroundColor: trackColor ?? bgBar,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          '$totalResponses Responses',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Performance breakdown',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        buildBar(
          label: 'Pass',
          percent: passPercent,
          color: passColor,
        ),
        const SizedBox(height: 10),
        buildBar(
          label: 'Fail',
          percent: failPercent,
          color: failColor,
        ),
        const SizedBox(height: 10),
        buildBar(
          label: 'Not completed',
          percent: remainingPercent,
          color: const Color(0xFF111827),
          visualPercent: remainingPercent == 0 ? 10 : remainingPercent,
        ),
      ],
    );
  }
}
