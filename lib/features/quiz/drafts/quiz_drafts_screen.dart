import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/quiz.dart';
import '../application/quiz_providers.dart';

class QuizDraftsScreen extends ConsumerWidget {
  const QuizDraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final drafts = ref.watch(quizSourceProvider).drafts;
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quiz drafts'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: drafts.isEmpty
          ? _EmptyDraftState(isDark: isDark)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                for (int i = 0; i < drafts.length; i++)
                  _DraftCard(
                    draft: drafts[i],
                    isLast: i == drafts.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft, required this.isLast});

  final QuizDraft draft;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final BorderSide borderSide = BorderSide(
      color: isDark
          ? theme.dividerColor.withValues(alpha: 0.35)
          : const Color(0xFFCBD5E1),
      width: 1.6,
    );

    return Card(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 18),
      color: theme.cardColor,
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: borderSide,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${draft.title}...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFCBD5E1).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? theme.dividerColor.withValues(alpha: 0.35)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    'Draft • ${draft.questionCount} Qs',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: isDark ? 0.92 : 0.85,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Updated ${_timeAgo(draft.updatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
            ),
          ],
        ),
      ),
      ),
    );
  }

  static String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

}

class _EmptyDraftState extends StatelessWidget {
  const _EmptyDraftState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No drafts yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Save quizzes as drafts to keep iterations handy. You can resume editing anytime.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
