import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/quiz.dart';
import '../../messages/ios_messages_screen.dart';
import '../application/quiz_providers.dart';
import '../create/quiz_create_screen.dart';
import '../drafts/quiz_drafts_screen.dart';
import '../results/quiz_results_screen.dart';
import '../../subscription/subscribe_screen.dart';

class QuizDashboardScreen extends ConsumerWidget {
  const QuizDashboardScreen({super.key, this.recentlyPublishedTitle});

  final String? recentlyPublishedTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizSource = ref.watch(quizSourceProvider);
    final drafts = quizSource.drafts;
    final results = quizSource.results;
    final int publishedCount = results.length;
    final int totalResponses = results.isEmpty
        ? 0
        : results.map((r) => r.responses).fold<int>(0, (a, b) => a + b);
    final double? avgScore = results.isEmpty
        ? null
        : results.map((r) => r.averageScore).fold<double>(0, (a, b) => a + b) /
            results.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _DashboardHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, 34),
                  child: _MyPlanCard(
                    planName: 'Basic',
                    usedQuizzes: publishedCount + drafts.length,
                    quizLimit: 10,
                    onTap: () {
                      Navigator.of(context).push(SubscribeScreen.route());
                    },
                  ),
                ),
                const SizedBox(height: 88),
                _DashboardQuickAccessGrid(
                  publishedCount: publishedCount,
                  draftsCount: drafts.length,
                  totalResponses: totalResponses,
                  avgScore: avgScore,
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
  const _DashboardHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/homelogo.png',
                  height: 40,
                  width: 40,
                  fit: BoxFit.contain,
                  semanticLabel: 'App logo',
                ),
              ],
            ),
            const SizedBox(height: 34),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF111827),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Colors.black,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QuizCreateScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create a quiz'),
              ),
            ),
          ],
        ),
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

    Color soft(Color light, Color dark) => isDark ? dark : light;

    void openResults() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const QuizResultsScreen()));
    }

    void openDrafts() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const QuizDraftsScreen()));
    }

    Future<void> openCreateClass() async {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FullPageClassesScreen()));
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
                  Colors.white, // white in light mode
                  const Color(0xFF064E3B), // deep green (dark)
                ),
                foreground: soft(const Color(0xFF0F766E), Colors.white),
                accent: soft(Colors.black, Colors.black),
                borderColor: soft(Colors.black, Colors.black),
                icon: Icons.assignment_rounded,
                iconColor: Colors.white,
                onTap: openResults,
              ),
              const SizedBox(height: 12),
              _DashboardQuickCard(
                title: 'Drafts',
                subtitle: '$draftsCount saved',
                badge: 'Continue drafts',
                background: soft(
                  const Color(0xFFFFFBF7), // off-white (light)
                  const Color(0xFF111827), // dark text surface (dark)
                ),
                foreground: soft(const Color(0xFF111827), Colors.white),
                accent: soft(
                  const Color(0xFFCBD5E1), // grey accent (light)
                  const Color(0xFFCBD5E1), // same accent in dark mode
                ),
                borderColor:
                    soft(const Color(0xFFCBD5E1), const Color(0xFFCBD5E1)),
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
                title: 'My classes',
                subtitle: 'Set up a new class space.',
                badge: 'Start class setup',
                background: soft(
                  const Color(0xFFE0F2FE),
                  const Color(0xFF0B1120),
                ),
                foreground: soft(const Color(0xFF0F172A), Colors.white),
                accent: soft(
                  const Color(0xFFCBD5E1), // grey action accent (light)
                  const Color(0xFFCBD5E1), // same accent in dark mode
                ),
                borderColor: soft(const Color(0xFFCBD5E1), const Color(0xFFCBD5E1)),
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
                foreground: soft(const Color(0xFF020617), Colors.white),
                accent: soft(
                  const Color(0xFFCBD5E1), // grey accent (light)
                  const Color(0xFFCBD5E1), // same in dark
                ),
                borderColor: soft(Colors.black, Colors.black),
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

class _MyPlanCard extends StatelessWidget {
  const _MyPlanCard({
    required this.planName,
    required this.usedQuizzes,
    required this.quizLimit,
    this.onTap,
  });

  final String planName;
  final int usedQuizzes;
  final int quizLimit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int clampedLimit = quizLimit <= 0 ? 1 : quizLimit;
    final int clampedUsed = usedQuizzes.clamp(0, clampedLimit);
    final double progress = clampedUsed / clampedLimit;

    const Color text = Color(0xFF111827);
    final Color progressFill = Colors.black;
    const Color glassOffWhite = Color(0xFFFFFBF7);
    final Color progressLabelColor =
        progress > 0.5 ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Subscription',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: text,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              planName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: text.withValues(alpha: 0.65),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Click to view plan details >',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: text.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 14,
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progressFill,
                                    ),
                                  ),
                                  Text(
                                    '$clampedUsed/$clampedLimit',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: progressLabelColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    this.borderColor,
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
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color badgeBackground = foreground.withValues(alpha: 0.06);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (borderColor ?? accent).withValues(alpha: 0.9),
            width: 1.6,
          ),
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
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.15,
    );
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.7 : 0.6,
    );

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
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            ),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
          Text(
            summary.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
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
                Text(
                  draft.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Updated ${hoursAgo}h ago',
                  style: theme.textTheme.bodySmall?.copyWith(color: subtle),
                ),
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
    final double avgScore =
        results.map((r) => r.averageScore).fold<double>(0, (a, b) => a + b) /
        results.length;
    final int totalResponses = results
        .map((r) => r.responses)
        .fold<int>(0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: 'Avg score',
            value: '${avgScore.toStringAsFixed(1)}%',
          ),
        ),
        Expanded(
          child: _Metric(label: 'Responses', value: '$totalResponses'),
        ),
        Expanded(
          child: _Metric(label: 'Quizzes', value: '${results.length}'),
        ),
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
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
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
