import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../ui/quiz_palette.dart';
import 'aiken_import_models.dart';

part 'aiken_import_review_screen_actions.dart';
part 'aiken_import_review_screen_build.dart';

const Color _whatsAppTeal = quizWhatsAppTeal;

/// A dedicated screen for reviewing and editing imported Aiken questions
class AikenImportReviewScreen extends StatefulWidget {
  const AikenImportReviewScreen({super.key, required this.questions});

  final List<ImportedQuestion> questions;

  @override
  State<AikenImportReviewScreen> createState() =>
      _AikenImportReviewScreenState();
}

abstract class _AikenImportReviewScreenStateBase
    extends State<AikenImportReviewScreen> {
  late List<ImportedQuestion> _questions;
  int? _expandedIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _questions = widget.questions.map((q) => q.copy()).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _AikenImportReviewScreenState extends _AikenImportReviewScreenStateBase
    with _AikenImportReviewScreenActions, _AikenImportReviewScreenBuild {}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onSetCorrect,
    required this.onRemove,
    required this.onPickPromptImage,
    required this.onRemovePromptImage,
    required this.onPickOptionImage,
    required this.onRemoveOptionImage,
  });

  final int index;
  final ImportedQuestion question;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
  final void Function(int) onSetCorrect;
  final VoidCallback onRemove;
  final VoidCallback onPickPromptImage;
  final VoidCallback onRemovePromptImage;
  final void Function(int) onPickOptionImage;
  final void Function(int) onRemoveOptionImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String promptText = question.prompt.text.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded
            ? (isDark ? theme.colorScheme.surface : Colors.white)
            : Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: isExpanded
            ? Border.all(color: _whatsAppTeal.withValues(alpha: 0.3))
            : null,
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible)
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isExpanded ? _whatsAppTeal : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isExpanded ? Colors.white : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isExpanded
                                ? theme.colorScheme.onSurface
                                : Colors.white,
                          ),
                        ),
                        if (promptText.isNotEmpty && !isExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            promptText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isExpanded) ...[
                    Text(
                      '${question.options.length} options',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isExpanded
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show prompt image if exists
                  if (question.promptImage != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(question.promptImage!),
                            height: 90,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: onRemovePromptImage,
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
                    const SizedBox(height: 6),
                  ],
                  TextField(
                    controller: question.prompt,
                    maxLines: null,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter question prompt...',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.25),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _whatsAppTeal,
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: InkWell(
                        onTap: onPickPromptImage,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            question.promptImage != null
                                ? Icons.image
                                : Icons.image_outlined,
                            size: 20,
                            color: question.promptImage != null
                                ? _whatsAppTeal
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Options
                  Text(
                    'Options',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _whatsAppTeal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(question.options.length, (optIdx) {
                    final isCorrect = question.correctIndex == optIdx;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Letter indicator
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? _whatsAppTeal
                                      : theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCorrect
                                        ? _whatsAppTeal
                                        : theme.dividerColor,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  String.fromCharCode(65 + optIdx),
                                  style: TextStyle(
                                    color: isCorrect
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Option text field
                              Expanded(
                                child: TextField(
                                  controller: question.options[optIdx],
                                  minLines: 1,
                                  maxLines: null, // auto-grow
                                  textInputAction: TextInputAction.newline,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Option ${String.fromCharCode(65 + optIdx)}',
                                    isDense: true,
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: _whatsAppTeal,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Actions (image, correct, remove) aligned on the right
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => onPickOptionImage(optIdx),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 2,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      child: Icon(
                                        (optIdx <
                                                    question
                                                        .optionImages
                                                        .length &&
                                                question.optionImages[optIdx] !=
                                                    null)
                                            ? Icons.image
                                            : Icons.image_outlined,
                                        size: 20,
                                        color:
                                            (optIdx <
                                                    question
                                                        .optionImages
                                                        .length &&
                                                question.optionImages[optIdx] !=
                                                    null)
                                            ? _whatsAppTeal
                                            : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => onSetCorrect(optIdx),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 2,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      child: Icon(
                                        isCorrect
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked,
                                        size: 24,
                                        color: isCorrect
                                            ? _whatsAppTeal
                                            : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  if (question.options.length > 2) ...[
                                    InkWell(
                                      onTap: () => onRemoveOption(optIdx),
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
                          // Show option image preview if exists
                          if (optIdx < question.optionImages.length &&
                              question.optionImages[optIdx] != null)
                            Column(
                              children: [
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(question.optionImages[optIdx]!),
                                          height: 48,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: InkWell(
                                          onTap: () =>
                                              onRemoveOptionImage(optIdx),
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
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                  // Bottom actions row
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: onAddOption,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add option'),
                        style: TextButton.styleFrom(
                          foregroundColor: _whatsAppTeal,
                        ),
                      ),
                      IconButton(
                        onPressed: onRemove,
                        tooltip: 'Remove question',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
