part of 'quiz_take_screen.dart';

extension _QuizTakeScreenUi on _QuizTakeScreenState {
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
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
                  (constraints.maxHeight - separator * (count - 1)).clamp(
                    0,
                    double.infinity,
                  );
              final double desired = count == 0 ? 0 : available / count;
              final double minTileHeight = desired.clamp(40.0, 72.0);

              return ListView.separated(
                itemCount: count,
                separatorBuilder: (_, __) => const SizedBox(height: separator),
                itemBuilder: (context, index) {
                  final bool isSelected = _responses[_currentIndex] == index;
                  final String optionLabel = String.fromCharCode(
                    65 + index,
                  ); // A, B, C...
                  return ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minTileHeight),
                    child: _buildOptionTile(
                      theme: theme,
                      label: optionLabel,
                      text: question.options[index],
                      isSelected: isSelected,
                      onTap: () =>
                          setState(() => _responses[_currentIndex] = index),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.85,
                          ),
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
                  final String optionLabel = String.fromCharCode(65 + opt);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _buildOptionTile(
                      theme: theme,
                      label: optionLabel,
                      text: question.options[opt],
                      isSelected: isSelected,
                      dense: true,
                      onTap: () =>
                          setState(() => _responses[questionIndex] = opt),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
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
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  style:
                      (dense
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.bodyLarge)
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.96,
                            ),
                            height: dense ? 1.2 : 1.25,
                          ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 10),
                Icon(Icons.check, color: theme.colorScheme.primary, size: 18),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                    const Text('•', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(
                      widget.isTimed
                          ? '${_totalDuration.inMinutes} min'
                          : 'No timer',
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
}

String _formatClock(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
