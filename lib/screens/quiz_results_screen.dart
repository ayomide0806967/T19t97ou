import 'package:flutter/material.dart';

import '../services/quiz_repository.dart';
import '../widgets/analytics_progress_arc.dart';
import '../widgets/vertical_action_menu.dart';
import 'quiz_answers_screen.dart';
import 'quiz_leaderboard_screen.dart';
import 'quiz_create_screen.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = QuizRepository.results;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My quizzes'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: results.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _MyQuizzesHeader();
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Previous quizzes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
          final result = results[index - 2];
          return _ResultCard(
            result: result,
            index: index - 1,
          );
        },
      ),
    );
  }
}

class _MyQuizzesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Card(
        elevation: 1.5,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a new quiz',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a fresh quiz for your learners.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuizCreateScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Create a quiz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.index,
  });

  final QuizResultSummary result;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.2);
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      color: theme.cardColor,
      elevation: isDark ? 0 : 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuizResultDetailsScreen(result: result),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. ${result.title}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 10,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 10,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF075E54),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Created ${_formatDate(result.lastUpdated)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dd = date.day.toString().padLeft(2, '0');
    final mm = months[date.month - 1];
    final yyyy = date.year.toString();
    int hour = date.hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hh = hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd $mm $yyyy, $hh:$min $suffix';
  }

  static String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class QuizResultDetailsScreen extends StatefulWidget {
  const QuizResultDetailsScreen({super.key, required this.result});

  final QuizResultSummary result;

  @override
  State<QuizResultDetailsScreen> createState() => _QuizResultDetailsScreenState();
}

class _QuizResultDetailsScreenState extends State<QuizResultDetailsScreen> {
  bool _isQuizActive = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AnalyticsProgressArc(
              averageScore: widget.result.averageScore,
              completionRate: widget.result.completionRate,
              totalResponses: widget.result.responses,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: theme.colorScheme.onSurface,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: widget.result.title,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  VerticalActionMenu(
                    isQuizActive: _isQuizActive,
                    onQuizStatusChanged: (value) {
                      setState(() => _isQuizActive = value);
                    },
                    onShareQuiz: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share quiz coming soon')),
                      );
                    },
                    onViewAnswers: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizAnswersScreen(
                            quizTitle: widget.result.title,
                            totalAnswers: widget.result.responses,
                          ),
                        ),
                      );
                    },
                    onViewResult: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuizLeaderboardScreen()),
                      );
                    },
                    onEditQuiz: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit quiz coming soon')),
                      );
                    },
                    onAddFavourite: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to favourites')),
                      );
                    },
                    onCollaboration: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Collaboration coming soon')),
                      );
                    },
                    onViewQuiz: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('View quiz coming soon')),
                      );
                    },
                    answerCount: 87,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: subtle)),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
