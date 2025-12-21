part of '../ios_messages_screen.dart';

class _ClassNotesCard extends StatelessWidget {
  const _ClassNotesCard({
    super.key,
    required this.summary,
    this.onUpdated,
    this.onMoveToLibrary,
    this.inLibrary = false,
    this.onDelete,
  });

  final ClassNoteSummary summary;
  final ValueChanged<ClassNoteSummary>? onUpdated;
  final VoidCallback? onMoveToLibrary;
  final bool inLibrary;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    final bool isDark = theme.brightness == Brightness.dark;
    const whatsappGreen = Color(0xFF075E54);
    final DateTime createdAt = summary.createdAt;
    final String dateLabel =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClassNoteStepperScreen(summary: summary),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade800,
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lecture note',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Topic: ${summary.title}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          size: 20,
                        ),
                        onPressed: onDelete,
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: () async {
                          final updated = await Navigator.of(context)
                              .push<ClassNoteSummary>(
                                MaterialPageRoute(
                                  builder: (_) => TeacherNoteCreationScreen(
                                    topic: summary.title,
                                    subtitle: summary.subtitle,
                                    initialSections: summary.sections,
                                    initialCreatedAt: summary.createdAt,
                                    initialCommentCount: summary.commentCount,
                                  ),
                                ),
                              );
                          if (updated != null &&
                              onUpdated != null &&
                              context.mounted) {
                            onUpdated!(updated);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtle,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.list_alt_outlined,
                        size: 16,
                        color: subtle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.steps} step${summary.steps == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtle,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: subtle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.estimatedMinutes} min review',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onMoveToLibrary != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: inLibrary
                            ? Colors.grey.shade300
                            : Colors.white,
                        foregroundColor: inLibrary
                            ? Colors.grey.shade700
                            : whatsappGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: inLibrary
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClassNoteStepperScreen(summary: summary),
                                ),
                              );
                            },
                      icon: Icon(
                        inLibrary ? Icons.block : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(inLibrary ? 'Deactivate' : 'Open'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: whatsappGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: onMoveToLibrary,
                          icon: const Icon(Icons.archive_outlined, size: 18),
                          label: Text(
                            inLibrary ? 'Move to Class' : 'Move to Library',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



// Repost now rendered as text label "repost"



// (removed unused _PostActivityPage + activity tiles)

// (moved to ios_messages/discussion_thread_page.dart)

// (moved to ios_messages/thread_models.dart)
