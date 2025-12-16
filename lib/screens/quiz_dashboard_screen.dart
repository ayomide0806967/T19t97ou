import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/quiz_repository.dart';
import 'create_class_screen.dart';
import 'quiz_drafts_screen.dart';
import 'quiz_create_screen.dart';
import 'quiz_results_screen.dart';

class QuizDashboardScreen extends StatelessWidget {
  const QuizDashboardScreen({
    super.key,
    this.recentlyPublishedTitle,
  });

  final String? recentlyPublishedTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drafts = QuizRepository.drafts;
    final results = QuizRepository.results;
    final size = MediaQuery.of(context).size;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color background =
        isDark ? const Color(0xFF050709) : const Color(0xFFF4F4F5);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: size.height * 0.33,
            child: _DashboardHero(
              publishedCount: results.length,
              totalResponses: results.isEmpty
                  ? 0
                  : results
                      .map((r) => r.responses)
                      .fold<int>(0, (a, b) => a + b),
              avgScore: results.isEmpty
                  ? null
                  : results
                          .map((r) => r.averageScore)
                          .fold<double>(0, (a, b) => a + b) /
                      results.length,
              draftsCount: drafts.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardQuickAccessGrid(
                  publishedCount: results.length,
                  draftsCount: drafts.length,
                  totalResponses: results.isEmpty
                      ? 0
                      : results
                          .map((r) => r.responses)
                          .fold<int>(0, (a, b) => a + b),
                  avgScore: results.isEmpty
                      ? null
                      : results
                              .map((r) => r.averageScore)
                              .fold<double>(0, (a, b) => a + b) /
                          results.length,
                ),
                if (recentlyPublishedTitle != null) ...[
                  const SizedBox(height: 24),
                  _RecentlyPublishedCard(title: recentlyPublishedTitle!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.publishedCount,
    required this.totalResponses,
    required this.avgScore,
    required this.draftsCount,
  });

  final int publishedCount;
  final int totalResponses;
  final double? avgScore;
  final int draftsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // WhatsApp-style banner color, matching the lecture note header.
    const Color bannerColor = Color(0xFF075E54);
    const Color bannerText = Colors.white;
    const Color accentSoft = Color(0xFF25D366);
    final Color subtitle = bannerText.withValues(alpha: 0.7);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(32),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bannerColor,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 20),
        child: Stack(
          children: [
            // Soft art shapes in the background.
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentSoft.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -10,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  border: Border.all(
                    color: accentSoft.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 44), // space for back button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quiz dashboard',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: bannerText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Stay on top of how learners are performing across your quizzes.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtitle,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: bannerText,
                                foregroundColor: bannerColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                                elevation: 3,
                                shadowColor: Colors.black.withValues(alpha: 0.25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: bannerText.withValues(alpha: 0.6),
                                  ),
                                ),
                                textStyle: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const QuizCreateScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add_rounded,
                                size: 20,
                              ),
                              label: const Text('Create a quiz'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentSoft.withValues(alpha: 0.05),
                        border: Border.all(
                          color: accentSoft.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: bannerText,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _HeaderMetric(
                      label: 'Published quizzes',
                      value: '$publishedCount',
                    ),
                    const SizedBox(width: 16),
                    _HeaderMetric(
                      label: 'Total responses',
                      value: '$totalResponses',
                    ),
                    const SizedBox(width: 16),
                    _HeaderMetric(
                      label: 'Average score',
                      value: avgScore == null
                          ? '–'
                          : '${avgScore!.toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Material(
                  color: accentSoft.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: bannerText,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const Color text = Colors.white;
    final Color subtle = text.withValues(alpha: 0.7);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: subtle),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardQuickAccessGrid extends StatelessWidget {
  const _DashboardQuickAccessGrid({
    required this.publishedCount,
    required this.draftsCount,
    required this.totalResponses,
    required this.avgScore,
  });

  final int publishedCount;
  final int draftsCount;
  final int totalResponses;
  final double? avgScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    Color soft(Color light, Color dark) =>
        isDark ? dark : light;

    void openResults() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuizResultsScreen()),
      );
    }

    void openDrafts() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuizDraftsScreen()),
      );
    }

    void openCreateClass() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateClassScreen()),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _DashboardQuickCard(
                title: 'My quizzes',
                subtitle: '$publishedCount published',
                badge: 'Manage quizzes',
                background: soft(
                  const Color(0xFF075E54), // WhatsApp banner green
                  const Color(0xFF075E54),
                ),
                foreground: soft(
                  Colors.white,
                  Colors.white,
                ),
                accent: soft(
                  Color(0xFFE5E7EB), // light grey action button
                  Color(0xFF9CA3AF), // darker grey for dark mode
                ),
                icon: Icons.assignment_rounded,
                iconColor: Colors.black,
                onTap: openResults,
              ),
              const SizedBox(height: 12),
              _DashboardQuickCard(
                title: 'Drafts',
                subtitle: '$draftsCount saved',
                badge: 'Continue drafts',
                background: soft(
                  const Color(0xFFD1FAE5), // soft green (light)
                  const Color(0xFF064E3B), // deep green (dark)
                ),
                foreground: soft(
                  const Color(0xFF064E3B),
                  const Color(0xFFE5F9F0),
                ),
                accent: soft(
                  const Color(0xFF34D399),
                  const Color(0xFF34D399),
                ),
                icon: Icons.drafts_rounded,
                onTap: openDrafts,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _DashboardQuickCard(
                title: 'Create a class',
                subtitle: 'Set up a new class space.',
                badge: 'Start class setup',
                background: soft(
                  const Color(0xFFE0F2FE),
                  const Color(0xFF0B1120),
                ),
                foreground: soft(
                  const Color(0xFF0F172A),
                  Colors.white,
                ),
                accent: soft(
                  const Color(0xFF0284C7),
                  const Color(0xFF38BDF8),
                ),
                icon: Icons.class_rounded,
                onTap: openCreateClass,
              ),
              const SizedBox(height: 12),
              _DashboardQuickCard(
                title: 'Question bank',
                subtitle: '$totalResponses responses logged',
                badge: 'Review questions',
                background: soft(
                  const Color(0xFFF1F5F9),
                  const Color(0xFF020617),
                ),
                foreground: soft(
                  const Color(0xFF020617),
                  Colors.white,
                ),
                accent: soft(
                  const Color(0xFF0F766E),
                  const Color(0xFF14B8A6),
                ),
                icon: Icons.playlist_add_check_rounded,
                onTap: openResults,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardQuickCard extends StatelessWidget {
  const _DashboardQuickCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.background,
    required this.foreground,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color background;
  final Color foreground;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color badgeBackground = foreground.withValues(alpha: 0.06);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 2,
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 13) + 1,
                    color: foreground.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize:
                            (theme.textTheme.bodySmall?.fontSize ?? 13) + 1,
                        color: foreground.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.15);
    final Color subtle =
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.7 : 0.6);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtle,
              ),
            ),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                label: Text(
                  actionLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview({required this.summary});

  final QuizResultSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '${summary.responses} responses · ${summary.averageScore.toStringAsFixed(0)}% avg score',
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
        ],
      ),
    );
  }
}

class _DraftPreview extends StatelessWidget {
  const _DraftPreview({required this.draft});

  final QuizDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final hoursAgo = DateTime.now().difference(draft.updatedAt).inHours;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Updated ${hoursAgo}h ago', style: theme.textTheme.bodySmall?.copyWith(color: subtle)),
              ],
            ),
          ),
          Text('${draft.questionCount} Qs', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ResultsOverview extends StatelessWidget {
  const _ResultsOverview({required this.results});

  final List<QuizResultSummary> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Text('No published quizzes yet.');
    }
    final double avgScore = results.map((r) => r.averageScore).fold<double>(0, (a, b) => a + b) / results.length;
    final int totalResponses = results.map((r) => r.responses).fold<int>(0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(child: _Metric(label: 'Avg score', value: '${avgScore.toStringAsFixed(1)}%')),
        Expanded(child: _Metric(label: 'Responses', value: '$totalResponses')),
        Expanded(child: _Metric(label: 'Quizzes', value: '${results.length}')),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: subtle)),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RecentlyPublishedCard extends StatelessWidget {
  const _RecentlyPublishedCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final String quizLink =
        'https://quiz.myapp.local/share/${Uri.encodeComponent(title)}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.11),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz published',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this link with your learners so they can join your quiz.',
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    quizLink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: quizLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quiz link copied to clipboard'),
                      ),
                    );
                  },
                  tooltip: 'Copy quiz link',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
