part of 'quiz_create_screen.dart';

// ============================================================================
// QUESTION EDITING STEP
// ============================================================================

class _QuestionEditingStep extends StatelessWidget {
  const _QuestionEditingStep({
    super.key,
    required this.index,
    required this.question,
    required this.canRemove,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onSetCorrect,
    required this.onRemove,
    required this.onPickPromptImage,
    required this.onRemovePromptImage,
    required this.onPickOptionImage,
    required this.onRemoveOptionImage,
    required this.onDone,
    required this.onOptionChanged,
  });

  final int index;
  final QuizQuestionFields question;
  final bool canRemove;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
  final void Function(int) onSetCorrect;
  final VoidCallback onRemove;
  final VoidCallback onDone;
  final void Function(int) onPickPromptImage;
  final void Function(int) onRemovePromptImage;
  final void Function(int, int) onPickOptionImage;
  final void Function(int, int) onRemoveOptionImage;
  final VoidCallback onOptionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color outline = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.22,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(width: 2, height: 8, color: Colors.black),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 4}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(width: 2, height: 20, color: Colors.black),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.07,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Multiple choice',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (canRemove)
                      IconButton(
                        tooltip: 'Remove question',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: onRemove,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Prompt image preview (shown above the prompt box)
                if (question.promptImage != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(question.promptImage!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => onRemovePromptImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Prompt (no label, icon inside field)
                QuizLabeledField(
                  label: '',
                  hintText: 'What parameter best reflects cardiac output?',
                  controller: question.prompt,
                  maxLines: 2,
                  autoExpand: true,
                  backgroundColor: theme.colorScheme.surface,
                  suffixIcon: InkWell(
                    onTap: () => onPickPromptImage(index),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        question.promptImage != null
                            ? Icons.image
                            : Icons.image_outlined,
                        size: 20,
                        color: question.promptImage != null
                            ? quizWhatsAppTeal
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Options
                ...List.generate(question.options.length, (optionIndex) {
                  final optionController = question.options[optionIndex];
                  final bool canRemoveOption = question.options.length > 2;
                  final bool hasOptionText = optionController.text
                      .trim()
                      .isNotEmpty;

                  return Column(
                    children: [
                      // Option image preview (shown above the option row)
                      if (optionIndex < question.optionImages.length &&
                          question.optionImages[optionIndex] != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                            top: 4,
                            right: 8,
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(question.optionImages[optionIndex]!),
                                  height: 60,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () =>
                                      onRemoveOptionImage(index, optionIndex),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Option letter pill (A, B, C, D) that highlights
                            // when this option is marked as correct.
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: question.correctIndex == optionIndex
                                    ? quizWhatsAppTeal
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: question.correctIndex == optionIndex
                                      ? quizWhatsAppTeal
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.25,
                                        ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                String.fromCharCode(65 + optionIndex),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: question.correctIndex == optionIndex
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: optionController,
                                minLines: 1,
                                maxLines: null, // auto-grow
                                textInputAction: TextInputAction.newline,
                                onChanged: (_) => onOptionChanged(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  hintText: question.correctIndex == optionIndex
                                      ? 'Correct answer'
                                      : 'Add option',
                                  isDense: true,
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.12),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.12),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: quizWhatsAppTeal,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!hasOptionText)
                                  InkWell(
                                    onTap: () =>
                                        onPickOptionImage(index, optionIndex),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 2,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      child: Icon(
                                        (optionIndex <
                                                    question
                                                        .optionImages
                                                        .length &&
                                                question.optionImages[optionIndex] !=
                                                    null)
                                            ? Icons.image
                                            : Icons.image_outlined,
                                        size: 22,
                                        color:
                                            (optionIndex <
                                                    question
                                                        .optionImages
                                                        .length &&
                                                question.optionImages[optionIndex] !=
                                                    null)
                                            ? quizWhatsAppTeal
                                            : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                InkWell(
                                  onTap: () => onSetCorrect(optionIndex),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 2,
                                      top: 4,
                                      bottom: 4,
                                    ),
                                    child: Icon(
                                      question.correctIndex == optionIndex
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked,
                                      size: 24,
                                      color:
                                          question.correctIndex == optionIndex
                                          ? quizWhatsAppTeal
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                if (canRemoveOption) ...[
                                  InkWell(
                                    onTap: () => onRemoveOption(optionIndex),
                                    borderRadius: BorderRadius.circular(999),
                                    child: const Padding(
                                      padding: EdgeInsets.only(
                                        left: 2,
                                        right: 4,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (optionIndex != question.options.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.7,
                          color: theme.dividerColor.withValues(alpha: 0.6),
                        ),
                    ],
                  );
                }),

                const Divider(height: 16),
                TextButton.icon(
                  onPressed: onAddOption,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add option'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
