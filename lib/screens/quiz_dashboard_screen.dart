import 'package:flutter/material.dart';

import '../services/quiz_repository.dart';
import 'quiz_drafts_screen.dart';
import 'quiz_results_screen.dart';

class QuizDashboardScreen extends StatelessWidget {
  const QuizDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drafts = QuizRepository.drafts;
    final results = QuizRepository.results;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quiz dashboard'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _DashboardCard(
            title: 'Previous quizzes',
            subtitle: 'Track performance from your published quizzes.',
            child: Column(
              children: results.take(2).map((summary) => _ResultPreview(summary: summary)).toList(),
            ),
            actionLabel: 'View results',
            onActionTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuizResultsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _DashboardCard(
            title: 'Drafts',
            subtitle: drafts.isEmpty
                ? 'No drafts saved yet.'
                : 'You have ${drafts.length} drafts waiting to publish.',
            child: Column(
              children: drafts.take(2).map((draft) => _DraftPreview(draft: draft)).toList(),
            ),
            actionLabel: 'Open drafts',
            onActionTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuizDraftsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _DashboardCard(
            title: 'Results overview',
            subtitle: 'High-level metrics that update live.',
            child: _ResultsOverview(results: results),
            actionLabel: 'Export summaries',
            onActionTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export coming soon')),
            ),
          ),
        ],
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
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.2);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onActionTap,
                child: Text(actionLabel),
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
    final theme = Theme.of(context);
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
