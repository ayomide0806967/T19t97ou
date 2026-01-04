part of 'trending_screen.dart';

class _TopicItem {
  const _TopicItem({required this.topic, required this.count});

  final String topic;
  final int count;
}

class _TrendingSearchBar extends StatelessWidget {
  const _TrendingSearchBar({
    required this.controller,
    required this.hintText,
    this.dense = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.55,
    );

    final Color fill = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        boxShadow: dense
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: AppTheme.tweetBody(theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTheme.tweetBody(subtle),
          prefixIcon: Icon(Icons.search, color: subtle),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close_rounded, color: subtle),
                  onPressed: controller.clear,
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: dense,
          contentPadding: dense
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}

const List<String> _fallbackTopics = [
  'NMCN Key Points',
  'Skills Lab',
  'Emergency Care',
  'Community Posting',
  'OSCE Practice',
  'Exam Prep',
  'Clinical Skills',
  'Research Updates',
  'Case Studies',
  'Student Life',
  'Medication Safety',
  'Simulation Lab',
];

const List<int> _fallbackTopicCounts = [
  39200,
  13700,
  1227,
  1271,
  8450,
  2310,
  5640,
  4210,
  3125,
  2760,
  1980,
  1640,
];

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.color, this.thickness = 1});

  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, thickness: thickness, color: color),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color border =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.2);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.showDivider,
    this.count,
  });

  final String topic;
  final int? count;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );
    final Color line =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.18);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In Nigeria',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic,
                      style: AppTheme.tweetBody(theme.colorScheme.onSurface)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCount(count ?? 0)} posts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(top: 2),
                icon: Icon(Icons.more_vert_rounded, color: subtle),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('More options for $topic'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: line),
      ],
    );
  }

  static String _formatCount(int value) {
    if (value >= 1000000) {
      final m = value / 1000000.0;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final k = value / 1000.0;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return value.toString();
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.topic,
    required this.count,
  });

  final String topic;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );
    final Color border =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topic,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.tweetBody(theme.colorScheme.onSurface).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_TopicRow._formatCount(count)} posts',
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
        ],
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.author,
    required this.handle,
    required this.showDivider,
  });

  final String author;
  final String handle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );
    final Color line =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.18);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialsFor(author),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      handle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Following $handle'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Follow'),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.zero,
            child: Divider(height: 1, thickness: 1, color: line),
          ),
      ],
    );
  }

  static String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '#';
    if (parts.length == 1) {
      final part = parts.first;
      return part.length >= 2
          ? part.substring(0, 2).toUpperCase()
          : part.substring(0, 1).toUpperCase();
    }
    final first = parts.first;
    final last = parts.last;
    return '${first[0]}${last[0]}'.toUpperCase();
  }
}

class _WhoToFollowEmpty extends StatelessWidget {
  const _WhoToFollowEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );
    return Text(
      'No suggestions yet.',
      style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
    );
  }
}

class _TrendingEmptyState extends StatelessWidget {
  const _TrendingEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const title = 'No posts yet';
    const subtitle =
        'Try checking back later or follow more creators to see activity here.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_fire_department_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ??
                    const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
