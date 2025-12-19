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
    int skippedCount = 0;
    for (int i = 0; i < questions.length; i++) {
      if (!responses.containsKey(i)) {
        skippedCount += 1;
      }
    }
    final int wrongCount = questions.length - correctCount - skippedCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popToOrigin(context);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _popToOrigin(context),
          ),
          title: const Text('Quiz correction'),
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
              wrong: wrongCount,
              skipped: skippedCount,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () => _retakeQuiz(context),
                    child: const Text('Retake quiz'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () => _postResults(
                      context,
                      correctCount,
                      wrongCount,
                      skippedCount,
                      accuracy,
                      timeUsed,
                    ),
                    child: const Text('Post results'),
                  ),
                ),
              ],
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

  void _popToOrigin(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _retakeQuiz(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _postResults(
    BuildContext context,
    int correct,
    int wrong,
    int skipped,
    double accuracy,
    Duration timeUsed,
  ) {
    final int accuracyPercent = (accuracy * 100).round();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Post results',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this quiz outcome with your class or group.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        theme.dividerColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $correct correct, $wrong wrong, $skipped skipped',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accuracy: $accuracyPercent%   •   Time: ${_SummaryCard._formatClock(timeUsed)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.correct,
    required this.total,
    required this.accuracy,
    required this.timeUsed,
    required this.timeRemaining,
    required this.wrong,
    required this.skipped,
  });

  final int correct;
  final int total;
  final double accuracy;
  final Duration timeUsed;
  final Duration timeRemaining;
  final int wrong;
  final int skipped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.25,
    );
    final int accuracyPercent = (accuracy * 100).round();

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
            'Results',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$correct / $total',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : accuracy.clamp(0, 1),
                        minHeight: 4,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accuracy >= 0.7
                              ? Colors.green
                              : accuracy >= 0.4
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$accuracyPercent% accuracy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryMetric(
                  label: 'Time used',
                  value: _formatClock(timeUsed),
                  secondary: 'Remaining ${_formatClock(timeRemaining)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatusCountChip(
                label: 'Correct',
                count: correct,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _StatusCountChip(
                label: 'Wrong',
                count: wrong,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _StatusCountChip(
                label: 'Skipped',
                count: skipped,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

class _StatusCountChip extends StatelessWidget {
  const _StatusCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$count $label',
            style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
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
