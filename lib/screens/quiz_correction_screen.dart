import 'package:flutter/material.dart';

import '../services/quiz_repository.dart';

class QuizCorrectionScreen extends StatelessWidget {
  const QuizCorrectionScreen({
    super.key,
    required this.questions,
    required this.responses,
    required this.totalTime,
    required this.remainingTime,
  });

  final List<QuizTakeQuestion> questions;
  final Map<int, int> responses;
  final Duration totalTime;
  final Duration remainingTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int correctCount = _calculateCorrect();
    final double accuracy = questions.isEmpty
        ? 0
        : correctCount / questions.length;
    final Duration timeUsed = _timeUsed;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quiz correction'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _SummaryCard(
            correct: correctCount,
            total: questions.length,
            accuracy: accuracy,
            timeUsed: timeUsed,
            timeRemaining: remainingTime,
          ),
          const SizedBox(height: 24),
          ...List.generate(questions.length, (index) {
            final question = questions[index];
            final int? selected = responses[index];
            final bool isCorrect = selected == question.answerIndex;
            return _QuestionReviewCard(
              question: question,
              index: index,
              selectedIndex: selected,
              isCorrect: isCorrect,
            );
          }),
        ],
      ),
    );
  }

  Duration get _timeUsed {
    final Duration raw = totalTime - remainingTime;
    if (raw.isNegative) return Duration.zero;
    if (raw > totalTime) return totalTime;
    return raw;
  }

  int _calculateCorrect() {
    int total = 0;
    for (int i = 0; i < questions.length; i++) {
      final selected = responses[i];
      if (selected != null && selected == questions[i].answerIndex) {
        total += 1;
      }
    }
    return total;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.correct,
    required this.total,
    required this.accuracy,
    required this.timeUsed,
    required this.timeRemaining,
  });

  final int correct;
  final int total;
  final double accuracy;
  final Duration timeUsed;
  final Duration timeRemaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.2,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryMetric(label: 'Score', value: '$correct / $total'),
              _SummaryMetric(
                label: 'Accuracy',
                value: '${(accuracy * 100).round()}%',
              ),
              _SummaryMetric(
                label: 'Time used',
                value: _formatClock(timeUsed),
                secondary: 'Rem ${_formatClock(timeRemaining)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatClock(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.secondary,
  });

  final String label;
  final String value;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (secondary != null)
            Text(
              secondary!,
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.question,
    required this.index,
    required this.selectedIndex,
    required this.isCorrect,
  });

  final QuizTakeQuestion question;
  final int index;
  final int? selectedIndex;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool answered = selectedIndex != null;
    final Color borderColor = isCorrect
        ? Colors.green
        : answered
        ? Colors.red
        : theme.dividerColor.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(isCorrect: isCorrect, answered: answered),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.prompt,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(question.options.length, (optionIndex) {
            final bool isAnswer = optionIndex == question.answerIndex;
            final bool isSelected = optionIndex == selectedIndex;
            final _OptionState state = _OptionState(
              isSelected: isSelected,
              isCorrect: isAnswer,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                label: question.options[optionIndex],
                state: state,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isCorrect, required this.answered});

  final bool isCorrect;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color background;
    String label;
    if (isCorrect) {
      background = Colors.green.withValues(alpha: 0.12);
      label = 'Correct';
    } else if (answered) {
      background = Colors.red.withValues(alpha: 0.12);
      label = 'Incorrect';
    } else {
      background = theme.colorScheme.onSurface.withValues(alpha: 0.08);
      label = 'Skipped';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OptionState {
  const _OptionState({required this.isSelected, required this.isCorrect});

  final bool isSelected;
  final bool isCorrect;

  Color backgroundColor(BuildContext context) {
    if (isSelected && isCorrect) {
      return Colors.green.withValues(alpha: 0.12);
    }
    if (isSelected && !isCorrect) {
      return Colors.red.withValues(alpha: 0.12);
    }
    if (!isSelected && isCorrect) {
      return Colors.green.withValues(alpha: 0.08);
    }
    return Theme.of(context).cardColor;
  }

  Color borderColor(BuildContext context) {
    if (isSelected && isCorrect) return Colors.green;
    if (isSelected && !isCorrect) return Colors.red;
    if (!isSelected && isCorrect) return Colors.green.withValues(alpha: 0.7);
    return Theme.of(context).dividerColor.withValues(alpha: 0.3);
  }

  IconData? icon() {
    if (isSelected && isCorrect) return Icons.check_circle;
    if (isSelected && !isCorrect) return Icons.cancel_rounded;
    if (!isSelected && isCorrect) return Icons.task_alt_rounded;
    return null;
  }

  Color iconColor() {
    if (isCorrect) return Colors.green;
    if (isSelected && !isCorrect) return Colors.red;
    return Colors.transparent;
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.state});

  final String label;
  final _OptionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = state.icon();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: state.backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: state.borderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (icon != null) Icon(icon, color: state.iconColor()),
        ],
      ),
    );
  }
}
