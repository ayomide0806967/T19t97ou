part of 'profile_screen.dart';

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 18,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: subtle)),
      ],
    );
  }
}

class _ProfileLevelStat extends StatelessWidget {
  const _ProfileLevelStat({
    required this.label,
    required this.progress,
    this.interactive = true,
  });

  final String label;
  final double progress; // 0..1
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final barBg = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.25 : 0.15,
    );
    final clamped = progress.clamp(0.0, 1.0);
    // Color-coded indicator fills the grey track as progress grows
    final Color barFg = _progressColor(theme, clamped);
    return InkWell(
      onTap: interactive ? () => _openLevelDetails(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row matches the numeric "value" style of other stats
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 18,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 6),
          // Bottom row: progress bar track to align with labels row
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: 88,
              height: 8,
              child: Stack(
                children: [
                  Container(color: barBg),
                  FractionallySizedBox(
                    widthFactor: clamped,
                    child: Container(color: barFg),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressColor(ThemeData theme, double value) {
    final p = value.clamp(0.0, 1.0);
    if (p <= 0.30) {
      return Colors.red;
    }
    if (p <= 0.60) {
      // Dark cyan for mid-range progress
      return const Color(0xFF00838F);
    }
    return Colors.green;
  }

  void _openLevelDetails(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = progress.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    final levels = <Map<String, String>>[
      {
        'title': 'Novice',
        'desc': 'complete beginner; little to no experience.',
      },
      {
        'title': 'Beginner',
        'desc': 'has some exposure; starting to learn basics.',
      },
      {
        'title': 'Amateur',
        'desc':
            'learning actively but still inconsistent; not yet professional.',
      },
      {
        'title': 'Apprentice',
        'desc': 'under training or mentorship; gaining practical skill.',
      },
      {
        'title': 'Intermediate',
        'desc': 'understands fundamentals and can perform tasks with guidance.',
      },
      {
        'title': 'Competent',
        'desc': 'able to work independently with good understanding.',
      },
      {
        'title': 'Proficient',
        'desc':
            'skilled and efficient; sees patterns and solves problems effectively.',
      },
      {
        'title': 'Advanced',
        'desc': 'deep understanding; handles complex or unusual tasks.',
      },
      {
        'title': 'Expert',
        'desc': 'recognized authority; consistently performs at high level.',
      },
      {
        'title': 'Master',
        'desc': 'exceptional, creative, and innovative command of the field.',
      },
      {
        'title': 'Professional',
        'desc': 'performs for pay; adheres to standards and ethics.',
      },
    ];

    // Group levels into three stages, each with its own step rail section.
    final categories = [
      {
        'title': 'Foundations',
        'range': 'Novice – Apprentice',
        'indices': [0, 1, 2, 3],
      },
      {
        'title': 'Developing practice',
        'range': 'Intermediate – Advanced',
        'indices': [4, 5, 6, 7],
      },
      {
        'title': 'Expertise',
        'range': 'Expert – Professional',
        'indices': [8, 9, 10],
      },
    ];

    // Prefer mapping the current level from the label (e.g. "Novice")
    // so the highlighted row always matches what the user sees,
    // and fall back to the numeric progress if no label match is found.
    int currentLevelIndex = levels.indexWhere(
      (m) => (m['title'] as String).toLowerCase() == label.toLowerCase(),
    );
    if (currentLevelIndex < 0) {
      currentLevelIndex =
          (clamped * (levels.length - 1)).round().clamp(0, levels.length - 1);
    }

    int activeCategoryIndex;
    if (currentLevelIndex <= 3) {
      activeCategoryIndex = 0;
    } else if (currentLevelIndex <= 7) {
      activeCategoryIndex = 1;
    } else {
      activeCategoryIndex = 2;
    }

    int expandedCategoryIndex = 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final onSurface = theme.colorScheme.onSurface;
        final subtle = onSurface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.6 : 0.6,
        );
        final highlight = _progressColor(theme, clamped);

        const stageIcons = <IconData>[
          Icons.layers_rounded, // Foundations
          Icons.auto_graph_rounded, // Developing practice
          Icons.emoji_events_rounded, // Expertise
        ];

        return StatefulBuilder(
          builder: (innerCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(innerCtx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Progress details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$percent% complete',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: subtle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 140,
                              height: 8,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Stack(
                                  children: [
                                    Container(
                                      color: onSurface.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: clamped,
                                      child: Container(color: highlight),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: (MediaQuery.of(innerCtx).size.height * 0.5)
                          .clamp(260.0, 420.0),
                      child: Stack(
                        children: [
                          // Single continuous vertical rail behind all steps
                          Positioned(
                            left: 16, // centered under 32px leading column
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: theme.dividerColor.withValues(alpha: 0.6),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              children:
                                  List.generate(categories.length, (index) {
                                final cat = categories[index];
                                final isCurrentCategory =
                                    index == activeCategoryIndex;
                                final isCompletedCategory =
                                    index < activeCategoryIndex;
                                final isExpanded =
                                    index == expandedCategoryIndex;

                                final circleColor = isCurrentCategory
                                    ? highlight
                                    : isCompletedCategory
                                        ? highlight.withValues(alpha: 0.15)
                                        : Colors.transparent;
                                final borderColor =
                                    isCompletedCategory || isCurrentCategory
                                        ? highlight
                                        : subtle.withValues(alpha: 0.4);

                                final titleStyle =
                                    theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isCurrentCategory
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: onSurface,
                                );

                                final subtitleStyle =
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: subtle,
                                );

                                final List<int> indices =
                                    (cat['indices'] as List<int>);

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index == categories.length - 1 ? 0 : 18,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        expandedCategoryIndex = index;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 32,
                                          child: Column(
                                            children: [
                                              if (index != 0)
                                                Container(
                                                  width: 2,
                                                  height: 18,
                                                  color: isCurrentCategory
                                                      ? Colors.black
                                                      : Colors.transparent,
                                                ),
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: circleColor,
                                                  border: Border.all(
                                                    color: borderColor,
                                                    width: 1.6,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: isCompletedCategory
                                                    ? Icon(
                                                        Icons.check,
                                                        size: 14,
                                                        color: isCurrentCategory
                                                            ? Colors.white
                                                            : highlight,
                                                      )
                                                    : Text(
                                                        '${index + 1}',
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                          color:
                                                              isCurrentCategory
                                                                  ? Colors.white
                                                                  : borderColor,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                              ),
                                              if (index != categories.length - 1)
                                                Container(
                                                  width: 2,
                                                  height: 26,
                                                  color: isCurrentCategory
                                                      ? Colors.black
                                                      : Colors.transparent,
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            curve: Curves.easeOut,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      stageIcons[index],
                                                      size: 18,
                                                      color: highlight,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      cat['title'] as String,
                                                      style: titleStyle,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  cat['range'] as String,
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: subtle,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (isExpanded) ...[
                                                  const SizedBox(height: 8),
                                                  SizedBox(
                                                    // Keep each stage compact so the
                                                    // next rail/category is still visible.
                                                    height: 170,
                                                    child:
                                                        SingleChildScrollView(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        right: 2,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: indices.map(
                                                          (levelIndex) {
                                                            final isUserLevel =
                                                                levelIndex ==
                                                                    currentLevelIndex;
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                bottom: 6,
                                                              ),
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  vertical: 8,
                                                                  horizontal: 10,
                                                                ),
                                                                decoration: isUserLevel
                                                                    ? BoxDecoration(
                                                                        color: highlight.withValues(
                                                                          alpha: 0.06,
                                                                        ),
                                                                        borderRadius: BorderRadius.circular(
                                                                            10),
                                                                        border: Border.all(
                                                                          color: highlight.withValues(
                                                                            alpha: 0.7,
                                                                          ),
                                                                          width: 1.1,
                                                                        ),
                                                                      )
                                                                    : BoxDecoration(
                                                                        borderRadius: BorderRadius.circular(
                                                                            10),
                                                                      ),
                                                                child: Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    if (isUserLevel) ...[
                                                                      Icon(
                                                                        Icons.check_rounded,
                                                                        size: 18,
                                                                        color: highlight,
                                                                      ),
                                                                      const SizedBox(
                                                                        width: 8,
                                                                      ),
                                                                    ],
                                                                    Expanded(
                                                                      child: Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            levels[levelIndex]['title'] ?? '',
                                                                            style: theme.textTheme.bodyMedium?.copyWith(
                                                                              fontWeight: FontWeight.w600,
                                                                              color: onSurface,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            height: 2,
                                                                          ),
                                                                          Text(
                                                                            levels[levelIndex]['desc'] ?? '',
                                                                            style: subtitleStyle,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

