import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/quiz_repository.dart';
import '../../../screens/quiz_correction_screen.dart';

class QuizTakeScreen extends StatefulWidget {
  const QuizTakeScreen({
    super.key,
    this.title,
    this.subtitle,
    this.questions,
  });

  final String? title;
  final String? subtitle;
  final List<QuizTakeQuestion>? questions;

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}


class _QuizTakeScreenState extends State<QuizTakeScreen> {
  late final List<QuizTakeQuestion> _questions;
  final Map<int, int> _responses = <int, int>{};
  int _currentIndex = 0;
  late final Duration _totalDuration;
  Duration _timeLeft = Duration.zero;
  Timer? _timer;
  bool _singlePageMode = false;

  @override
  void initState() {
    super.initState();
    _questions = widget.questions ?? QuizRepository.sampleQuestions;
    _totalDuration = const Duration(minutes: 12);
    _timeLeft = _totalDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft.inSeconds == 0) {
          timer.cancel();
        } else {
          _timeLeft -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _questions[_currentIndex];
    final bool isLast = _currentIndex == _questions.length - 1;
    final Color pageBackground = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: _singlePageMode
                  ? _buildSinglePageBody(theme)
                  : _buildOneQuestionBody(theme, question, isLast),
            ),
            Positioned(
              top: 12,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatClock(_timeLeft),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.9),
                            ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value:
                                _timeLeft.inSeconds / _totalDuration.inSeconds,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _singlePageMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'question_navigator',
                    onPressed: _openQuestionNavigator,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    elevation: 0,
                    focusElevation: 0,
                    hoverElevation: 0,
                    highlightElevation: 0,
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'calculator_fab',
                    onPressed: _openCalculator,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    elevation: 0,
                    focusElevation: 0,
                    hoverElevation: 0,
                    highlightElevation: 0,
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildOneQuestionBody(
    ThemeData theme,
    QuizTakeQuestion question,
    bool isLast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuizHeader(theme),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white,
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${_currentIndex + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.prompt,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final int count = question.options.length;
              const double separator = 0;
              final double available =
                  (constraints.maxHeight - separator * (count - 1))
                      .clamp(0, double.infinity);
              final double desired = count == 0 ? 0 : available / count;
              final double minTileHeight = desired.clamp(40.0, 72.0);

              return ListView.separated(
                itemCount: count,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: separator),
                itemBuilder: (context, index) {
                  final bool isSelected = _responses[_currentIndex] == index;
                  final String optionLabel =
                      String.fromCharCode(65 + index); // A, B, C...
                  return ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minTileHeight),
                    child: _buildOptionTile(
                      theme: theme,
                      label: optionLabel,
                      text: question.options[index],
                      isSelected: isSelected,
                      onTap: () => setState(
                        () => _responses[_currentIndex] = index,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 44),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _currentIndex == 0
                  ? null
                  : () => setState(() => _currentIndex -= 1),
              child: const Text('Back'),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 14,
                ),
                minimumSize: const Size(0, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: isLast ? _submitQuiz : _goForward,
              child: Text(isLast ? 'Submit' : 'Next'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInlineFab(
              icon: Icons.grid_view_rounded,
              onPressed: _openQuestionNavigator,
            ),
            const SizedBox(width: 16),
            _buildInlineFab(
              icon: Icons.calculate_rounded,
              onPressed: _openCalculator,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSinglePageBody(ThemeData theme) {
    return ListView.builder(
      itemCount: _questions.length + 2,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: _buildQuizHeader(theme),
          );
        }

        if (index == _questions.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _submitQuiz,
                child: const Text('Submit quiz'),
              ),
            ),
          );
        }

        final int questionIndex = index - 1;
        final question = _questions[questionIndex];
        return Padding(
          padding: EdgeInsets.only(
            bottom: questionIndex == _questions.length - 1 ? 12 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white,
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.prompt,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: List.generate(question.options.length, (opt) {
                  final bool isSelected = _responses[questionIndex] == opt;
                  final String optionLabel =
                      String.fromCharCode(65 + opt);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _buildOptionTile(
                      theme: theme,
                      label: optionLabel,
                      text: question.options[opt],
                      isSelected: isSelected,
                      dense: true,
                      onTap: () => setState(
                        () => _responses[questionIndex] = opt,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required ThemeData theme,
    required String label,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isSelected ? theme.colorScheme.primary : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.9)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.6),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  style: (dense
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.bodyLarge)
                      ?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.96),
                    height: dense ? 1.2 : 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.check,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineFab({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.black54),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildQuizHeader(ThemeData theme) {
    final String title = (widget.title ?? '').trim();
    final String subtitle = (widget.subtitle ?? '').trim();
    if (title.isEmpty && subtitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${_questions.length} questions',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_totalDuration.inMinutes} min',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goForward() {
    setState(() => _currentIndex += 1);
  }

  void _submitQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizCorrectionScreen(
          questions: _questions,
          responses: Map<int, int>.from(_responses),
          totalTime: _totalDuration,
          remainingTime: _timeLeft,
        ),
      ),
    );
  }

  static String _formatClock(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _openQuestionNavigator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3F4F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final viewInsets = MediaQuery.of(context).viewInsets;
        int? searchNumber;

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _singlePageMode
                                    ? Colors.transparent
                                    : Colors.black,
                                foregroundColor: _singlePageMode
                                    ? theme.colorScheme.onSurface
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                side: BorderSide(
                                  color: _singlePageMode
                                      ? Colors.black.withValues(alpha: 0.4)
                                      : Colors.black,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _singlePageMode = false;
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text('One per page'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _singlePageMode
                                    ? Colors.black
                                    : Colors.transparent,
                                foregroundColor: _singlePageMode
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                side: BorderSide(
                                  color: _singlePageMode
                                      ? Colors.black
                                      : Colors.black.withValues(alpha: 0.4),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _singlePageMode = true;
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text('Full page'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          hintText: 'Jump to question number (e.g. 3)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (value) {
                          final int? number = int.tryParse(value.trim());
                          setModalState(() {
                            if (number == null ||
                                number < 1 ||
                                number > _questions.length) {
                              searchNumber = null;
                            } else {
                              searchNumber = number;
                            }
                          });
                        },
                        onSubmitted: (value) {
                          final int? number = int.tryParse(value.trim());
                          if (number == null ||
                              number < 1 ||
                              number > _questions.length) {
                            return;
                          }
                          Navigator.of(context).pop();
                          setState(() => _currentIndex = number - 1);
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_questions.length, (index) {
                          final int displayNumber = index + 1;
                          if (searchNumber != null &&
                              displayNumber != searchNumber) {
                            return const SizedBox.shrink();
                          }

                          final bool answered = _responses.containsKey(index);
                          final bool isCurrent = index == _currentIndex;
                          Color background;
                          Color textColor;
                          if (isCurrent) {
                            background = theme.colorScheme.primary;
                            textColor = theme.colorScheme.onPrimary;
                          } else if (answered) {
                            background = theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            );
                            textColor = theme.colorScheme.primary;
                          } else {
                            background =
                                theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.6);
                            textColor = theme.colorScheme.onSurfaceVariant;
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              setState(() => _currentIndex = index);
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: background,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$displayNumber',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    answered ? 'Done' : 'Empty',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _submitQuiz();
                          },
                          child: const Text('Submit quiz'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openCalculator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => const _IOSStyleCalculatorSheet(),
    );
  }
}

class _IOSStyleCalculatorSheet extends StatefulWidget {
  const _IOSStyleCalculatorSheet();

  @override
  State<_IOSStyleCalculatorSheet> createState() =>
      _IOSStyleCalculatorSheetState();
}

class _IOSStyleCalculatorSheetState extends State<_IOSStyleCalculatorSheet> {
  String _display = '0';
  double? _firstOperand;
  String? _pendingOperator;
  bool _resetOnNextDigit = false;
  String? _lastExpression;
  bool _justEvaluated = false;

  String _formatNumber(double value) {
    final fixed = value.toStringAsFixed(6);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String get _expressionText {
    if (_lastExpression != null) {
      return _lastExpression!;
    }
    if (_firstOperand == null || _pendingOperator == null) {
      return _display;
    }
    final left = _formatNumber(_firstOperand!);
    final String right =
        _resetOnNextDigit ? '' : _display;
    if (right.isEmpty) {
      return '$left $_pendingOperator';
    }
    return '$left $_pendingOperator $right';
  }

  void _tapDigit(String digit) {
    setState(() {
      _justEvaluated = false;
      _lastExpression = null;
      if (_resetOnNextDigit) {
        _display = digit == '.' ? '0.' : digit;
        _resetOnNextDigit = false;
        return;
      }
      if (digit == '.') {
        if (_display.contains('.')) return;
        _display = '$_display.';
      } else {
        _display = _display == '0' ? digit : '$_display$digit';
      }
    });
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _pendingOperator = null;
      _resetOnNextDigit = false;
      _lastExpression = null;
      _justEvaluated = false;
    });
  }

  void _toggleSign() {
    setState(() {
      if (_display == '0') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _percent() {
    final value = double.tryParse(_display);
    if (value == null) return;
    setState(() {
      final result = value / 100;
      _display = _formatNumber(result);
      _lastExpression = null;
      _justEvaluated = false;
    });
  }

  void _setOperator(String op) {
    final value = double.tryParse(_display);
    if (value == null) return;
    setState(() {
      _firstOperand = value;
      _pendingOperator = op;
      _resetOnNextDigit = true;
      _lastExpression = null;
      _justEvaluated = false;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _pendingOperator == null) return;
    final second = double.tryParse(_display);
    if (second == null) return;
    double result = _firstOperand!;
    switch (_pendingOperator) {
      case '+':
        result = _firstOperand! + second;
        break;
      case '−':
        result = _firstOperand! - second;
        break;
      case '×':
        result = _firstOperand! * second;
        break;
      case '÷':
        if (second != 0) {
          result = _firstOperand! / second;
        }
        break;
    }
    setState(() {
      final left = _formatNumber(_firstOperand!);
      final right = _formatNumber(second);
      final resultStr = _formatNumber(result);
      _lastExpression = '$left $_pendingOperator $right = $resultStr';
      _display = resultStr;
      _firstOperand = null;
      _pendingOperator = null;
      _resetOnNextDigit = true;
      _justEvaluated = true;
    });
  }

  Widget _buildButton({
    required String label,
    Color? background,
    Color? foreground,
    double flex = 1,
    VoidCallback? onTap,
  }) {
    return Expanded(
      flex: flex.round(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: background ?? const Color(0xFF333333),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: foreground ?? Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color operatorColor = const Color(0xFFFF9500);
    final Color lightKey = const Color(0xFFA5A5A5);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  _expressionText,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            const SizedBox(height: 8),
              // Keypad
              Column(
                children: [
                  Row(
                    children: [
                      _buildButton(
                        label: 'AC',
                        background: lightKey,
                        foreground: Colors.black,
                        onTap: _clearAll,
                      ),
                      _buildButton(
                        label: '+/−',
                        background: lightKey,
                        foreground: Colors.black,
                        onTap: _toggleSign,
                      ),
                      _buildButton(
                        label: '%',
                        background: lightKey,
                        foreground: Colors.black,
                        onTap: _percent,
                      ),
                      _buildButton(
                        label: '÷',
                        background: operatorColor,
                        onTap: () => _setOperator('÷'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton(label: '7', onTap: () => _tapDigit('7')),
                      _buildButton(label: '8', onTap: () => _tapDigit('8')),
                      _buildButton(label: '9', onTap: () => _tapDigit('9')),
                      _buildButton(
                        label: '×',
                        background: operatorColor,
                        onTap: () => _setOperator('×'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton(label: '4', onTap: () => _tapDigit('4')),
                      _buildButton(label: '5', onTap: () => _tapDigit('5')),
                      _buildButton(label: '6', onTap: () => _tapDigit('6')),
                      _buildButton(
                        label: '−',
                        background: operatorColor,
                        onTap: () => _setOperator('−'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton(label: '1', onTap: () => _tapDigit('1')),
                      _buildButton(label: '2', onTap: () => _tapDigit('2')),
                      _buildButton(label: '3', onTap: () => _tapDigit('3')),
                      _buildButton(
                        label: '+',
                        background: operatorColor,
                        onTap: () => _setOperator('+'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton(
                        label: '0',
                        flex: 2,
                        onTap: () => _tapDigit('0'),
                      ),
                      _buildButton(label: '.', onTap: () => _tapDigit('.')),
                      _buildButton(
                        label: '=',
                        background: operatorColor,
                        onTap: _calculate,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
