part of 'quiz_create_screen.dart';

// ============================================================================
// DETAILS EDITING STEP
// ============================================================================

class _DetailsEditingStep extends StatelessWidget {
  const _DetailsEditingStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.onNext,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator - black filled for active
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
                child: const Text(
                  '1',
                  style: TextStyle(
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
        // Content panel
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.25),
              ),
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
                Text(
                  'Step 1 · Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: quizWhatsAppTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Give your quiz a name and context',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                QuizLabeledField(
                  label: 'Title',
                  hintText: 'Cardiology round recap quiz',
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  backgroundColor: theme.colorScheme.surface,
                ),
                const SizedBox(height: 16),
                QuizLabeledField(
                  label: 'Description',
                  hintText:
                      'Give learners context or expectations for this quiz.',
                  controller: descriptionController,
                  maxLines: 3,
                  autoExpand: true,
                  backgroundColor: theme.colorScheme.surface,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: quizWhatsAppTeal,
                      foregroundColor: Colors.white,
                    ),
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
