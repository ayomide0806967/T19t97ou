part of 'quiz_take_screen.dart';

extension _QuizTakeQuestionNavigatorSheet on _QuizTakeScreenState {
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
                            background = theme
                                .colorScheme
                                .surfaceContainerHighest
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
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    answered ? 'Done' : 'Empty',
                                    style: theme.textTheme.labelSmall?.copyWith(
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
}
