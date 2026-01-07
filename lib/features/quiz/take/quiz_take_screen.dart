import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/quiz.dart';
import '../application/quiz_providers.dart';
import '../results/quiz_correction_screen.dart';

part 'quiz_take_calculator_sheet.dart';
part 'quiz_take_question_navigator_sheet.dart';
part 'quiz_take_screen_ui.dart';

class QuizTakeScreen extends ConsumerStatefulWidget {
  const QuizTakeScreen({
    super.key,
    this.title,
    this.subtitle,
    this.questions,
    this.isTimed = true,
    this.timerMinutes,
  });

  final String? title;
  final String? subtitle;
  final List<QuizTakeQuestion>? questions;
  final bool isTimed;
  final int? timerMinutes;

  @override
  ConsumerState<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends ConsumerState<QuizTakeScreen> {
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
    _questions =
        widget.questions ?? ref.read(quizSourceProvider).sampleQuestions;
    final minutes = (widget.timerMinutes ?? 12).clamp(1, 360);
    _totalDuration = widget.isTimed ? Duration(minutes: minutes) : Duration.zero;
    _timeLeft = _totalDuration;
    if (widget.isTimed) {
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
            if (widget.isTimed)
              Positioned(
                top: 12,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
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
                              value: _totalDuration.inSeconds == 0
                                  ? 0
                                  : _timeLeft.inSeconds /
                                      _totalDuration.inSeconds,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.12,
                              ),
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
}
