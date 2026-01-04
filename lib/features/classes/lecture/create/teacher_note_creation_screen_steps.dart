part of 'teacher_note_creation_screen.dart';

/// Completed/collapsed step - tap to edit
class _CompletedNoteStep extends StatelessWidget {
  const _CompletedNoteStep({
    required this.index,
    required this.total,
    required this.section,
    required this.onTap,
  });

  final int index;
  final int total;
  final ClassNoteSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator - white circle for completed
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (index != 0)
                  Container(width: 2, height: 8, color: Colors.black),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.black,
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
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (section.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            section.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                        if (section.bullets.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${section.bullets.length} point${section.bullets.length > 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Active editing step
class _NoteEditingStep extends StatefulWidget {
  const _NoteEditingStep({
    required this.index,
    required this.isNewStep,
    required this.titleController,
    required this.subtitleController,
    required this.bulletsController,
    required this.onNext,
    required this.headingWordLimit,
    required this.subtitleWordLimit,
    this.onCancel,
    required this.imagePaths,
    required this.onAddImage,
  });

  final int index;
  final bool isNewStep;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController bulletsController;
  final VoidCallback onNext;
  final VoidCallback? onCancel;
  final int headingWordLimit;
  final int subtitleWordLimit;
  final List<String> imagePaths;
  final VoidCallback onAddImage;

  @override
  State<_NoteEditingStep> createState() => _NoteEditingStepState();
}

class _NoteEditingStepState extends State<_NoteEditingStep> {
  List<String> _words(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> imagePaths = widget.imagePaths;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator - black filled for active
        SizedBox(
          width: 24,
          child: Column(
            children: [
              if (widget.index != 0)
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
                  '${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Input panel
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Theme(
              data: theme.copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.8,
                    ),
                  ),
                ),
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Colors.black,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isNewStep
                        ? 'Step ${widget.index + 1}'
                        : 'Edit Step ${widget.index + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: widget.titleController,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Section Heading',
                    ),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      final words = _words(value);
                      if (words.length > widget.headingWordLimit) {
                        final truncated = words
                            .take(widget.headingWordLimit)
                            .join(' ');
                        widget.titleController.value = TextEditingValue(
                          text: truncated,
                          selection: TextSelection.collapsed(
                            offset: truncated.length,
                          ),
                        );
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'Keep section heading under ${widget.headingWordLimit} words',
                              ),
                            ),
                          );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: widget.subtitleController,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle (optional)',
                    ),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      final words = _words(value);
                      if (words.length > widget.subtitleWordLimit) {
                        final truncated = words
                            .take(widget.subtitleWordLimit)
                            .join(' ');
                        widget.subtitleController.value = TextEditingValue(
                          text: truncated,
                          selection: TextSelection.collapsed(
                            offset: truncated.length,
                          ),
                        );
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'Keep subtitle under ${widget.subtitleWordLimit} words',
                              ),
                            ),
                          );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  imagePaths.isNotEmpty
                      ? SizedBox(
                          height: 160,
                          child: PageView.builder(
                            itemCount: imagePaths.length,
                            controller: PageController(viewportFraction: 0.9),
                            itemBuilder: (context, index) {
                              final String path = imagePaths[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.black12,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Image ${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.65),
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : TextFormField(
                          controller: widget.bulletsController,
                          maxLines: null,
                          minLines: 4,
                          textInputAction: TextInputAction.newline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Content',
                            hintText:
                                'Write brief points here...\nEach line becomes a bullet.\nKeep it short (max ~60 words).',
                            alignLabelWithHint: true,
                            suffixIcon:
                                widget.bulletsController.text.trim().isEmpty &&
                                    widget.imagePaths.isEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.image_outlined),
                                    onPressed: widget.onAddImage,
                                  )
                                : null,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          onChanged: (_) => setState(() {}),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: widget.onNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF075E54),
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          widget.isNewStep ? Icons.arrow_downward : Icons.check,
                          size: 16,
                        ),
                        label: Text(widget.isNewStep ? 'Next Step' : 'Save'),
                      ),
                      if (widget.onCancel != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
