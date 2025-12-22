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
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
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
                  hintText: 'Give learners context or expectations for this quiz.',
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

// ============================================================================
// SETTINGS EDITING STEP
// ============================================================================

class _SettingsEditingStep extends StatelessWidget {
  const _SettingsEditingStep({
    super.key,
    required this.isTimed,
    required this.timeLimitController,
    required this.hasDeadline,
    required this.closingDate,
    required this.attemptLimit,
    required this.requiresPin,
    required this.pinController,
    required this.onTimedChanged,
    required this.onTimeLimitChanged,
    required this.onDeadlineChanged,
    required this.onPickDeadline,
    required this.onAttemptsChanged,
    required this.onRequirePinChanged,
    required this.onNext,
    required this.onBack,
  });

  final bool isTimed;
  final TextEditingController timeLimitController;
  final bool hasDeadline;
  final DateTime? closingDate;
  final int? attemptLimit;
  final bool requiresPin;
  final TextEditingController pinController;
  final ValueChanged<bool> onTimedChanged;
  final ValueChanged<double> onTimeLimitChanged;
  final ValueChanged<bool> onDeadlineChanged;
  final Future<void> Function() onPickDeadline;
  final ValueChanged<int?> onAttemptsChanged;
  final ValueChanged<bool> onRequirePinChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color outline = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.22);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    String deadlineLabel;
    if (!hasDeadline || closingDate == null) {
      deadlineLabel = 'Set closing time';
    } else {
      final date = localizations.formatMediumDate(closingDate!);
      final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(closingDate!));
      deadlineLabel = '$date · $time';
    }

    final List<DropdownMenuItem<int?>> attemptItems = [
      const DropdownMenuItem<int?>(value: null, child: Text('Unlimited')),
      ...[1, 2, 3, 5].map(
        (value) => DropdownMenuItem<int?>(
          value: value,
          child: Text('$value attempt${value == 1 ? '' : 's'}'),
        ),
      ),
    ];

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
                child: const Text(
                  '2',
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
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
                Text(
                  'Step 2 · Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure timer, deadline, and access',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Timed quiz
                SwitchListTile.adaptive(
                  value: isTimed,
                  onChanged: onTimedChanged,
                  title: const Text('Timed quiz'),
                  subtitle: const Text('Set a time limit'),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.black,
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      final bool selected = states.contains(WidgetState.selected);
                      return selected ? Colors.white : Colors.black;
                    },
                  ),
                ),
                if (isTimed) ...[
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final int currentMinutes =
                          int.tryParse(timeLimitController.text) ?? 20;
                      final int hours = currentMinutes ~/ 60;
                      final int minutes = currentMinutes % 60;
                      final String durationLabel = hours > 0
                          ? '${hours}h ${minutes.toString().padLeft(2, '0')}m'
                          : '$minutes min';

                      Future<void> openTimerPicker() async {
                        Duration selected =
                            Duration(minutes: currentMinutes.clamp(1, 360));
                        await showModalBottomSheet<void>(
                          context: context,
                          useSafeArea: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (ctx) {
                            return StatefulBuilder(
                              builder: (ctx, setModalState) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 12, 16, 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Timer duration',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 200,
                                        child: CupertinoTimerPicker(
                                          mode: CupertinoTimerPickerMode.hm,
                                          initialTimerDuration: selected,
                                          onTimerDurationChanged: (duration) {
                                            setModalState(
                                                () => selected = duration);
                                            final int mins = duration
                                                .inMinutes
                                                .clamp(1, 360);
                                            timeLimitController.text =
                                                mins.toString();
                                            onTimeLimitChanged(
                                                mins.toDouble());
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: () async {
                                            final int initialHours =
                                                selected.inHours;
                                            final int initialMinutes =
                                                selected.inMinutes % 60;
                                            final TextEditingController
                                                hoursController =
                                                TextEditingController(
                                                    text: initialHours
                                                        .toString());
                                            final TextEditingController
                                                minutesController =
                                                TextEditingController(
                                                    text: initialMinutes
                                                        .toString());

                                            final Duration? manualResult =
                                                await showDialog<Duration>(
                                              context: ctx,
                                              builder: (dialogCtx) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  title: const Text(
                                                      'Set duration manually'),
                                                  content: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        width: 100,
                                                        child: TextField(
                                                          controller:
                                                              hoursController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter
                                                                .digitsOnly,
                                                            LengthLimitingTextInputFormatter(
                                                                3),
                                                          ],
                                                          decoration:
                                                              InputDecoration(
                                                            labelText: 'HOUR',
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      SizedBox(
                                                        width: 100,
                                                        child: TextField(
                                                          controller:
                                                              minutesController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter
                                                                .digitsOnly,
                                                            LengthLimitingTextInputFormatter(
                                                                2),
                                                          ],
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'MINUTE',
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                                  dialogCtx)
                                                              .pop(),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        final int h =
                                                            int.tryParse(
                                                                    hoursController
                                                                        .text) ??
                                                                0;
                                                        final int m =
                                                            int.tryParse(
                                                                    minutesController
                                                                        .text) ??
                                                                0;
                                                        int total =
                                                            h * 60 + m;
                                                        if (total < 1) {
                                                          total = 1;
                                                        }
                                                        if (total > 360) {
                                                          total = 360;
                                                        }
                                                        Navigator.of(
                                                                dialogCtx)
                                                            .pop(Duration(
                                                                minutes:
                                                                    total));
                                                      },
                                                      child:
                                                          const Text('Apply'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (manualResult != null) {
                                              setModalState(() {
                                                selected = manualResult;
                                              });
                                              final int mins = manualResult
                                                  .inMinutes
                                                  .clamp(1, 360);
                                              timeLimitController.text =
                                                  mins.toString();
                                              onTimeLimitChanged(
                                                  mins.toDouble());
                                            }
                                          },
                                          child: const Text('Set manually'),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('Done'),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }

                      return OutlinedButton(
                        onPressed: openTimerPicker,
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(durationLabel),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 8),
                
                // Deadline
                SwitchListTile.adaptive(
                  value: hasDeadline,
                  onChanged: onDeadlineChanged,
                  title: const Text('Close automatically'),
                  subtitle: const Text('Set a deadline'),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.black,
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      final bool selected = states.contains(WidgetState.selected);
                      return selected ? Colors.white : Colors.black;
                    },
                  ),
                ),
                if (hasDeadline) ...[
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: onPickDeadline,
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(deadlineLabel),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                
                // Attempts
                Text(
                  'Attempts allowed',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  value: attemptLimit,  // Using 'value' is fine for this use case
                  items: attemptItems,
                  onChanged: onAttemptsChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 8),
                // PIN
                SwitchListTile.adaptive(
                  value: requiresPin,
                  onChanged: onRequirePinChanged,
                  title: const Text('Require PIN'),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.black,
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      final bool selected = states.contains(WidgetState.selected);
                      return selected ? Colors.white : Colors.black;
                    },
                  ),
                ),
                if (requiresPin) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: pinController,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'PIN (4-6 digits)',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: outline),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        foregroundColor: quizWhatsAppTeal,
                      ),
                      child: const Text('Back'),
                    ),
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Next'),
                      style: FilledButton.styleFrom(
                        backgroundColor: quizWhatsAppTeal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUESTION SETUP STEP (Manual vs Aiken)
// ============================================================================

class _QuestionSetupStep extends StatelessWidget {
  const _QuestionSetupStep({
    super.key,
    required this.mode,
    required this.onManualSelected,
    required this.onAikenSelected,
    required this.onBack,
  });

  final _QuizBuildMode mode;
  final VoidCallback onManualSelected;
  final Future<void> Function() onAikenSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final Color outline =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.22);

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
                child: const Text(
                  '3',
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
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
                Text(
                  'Step 3 · Question setup',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how you want to add questions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onManualSelected,
                  icon: Icon(
                    Icons.edit_note_rounded,
                    color: mode == _QuizBuildMode.manual
                        ? quizWhatsAppTeal
                        : Colors.black,
                  ),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manual quiz setup',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Write questions directly in the app.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    side: BorderSide(
                      color: Colors.black,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onAikenSelected,
                  icon: Icon(
                    Icons.upload_file_rounded,
                    color: mode == _QuizBuildMode.aiken
                        ? quizWhatsAppTeal
                        : Colors.black,
                  ),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Import Aiken file',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Upload a .txt file in Aiken format.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    side: BorderSide(
                      color: Colors.black,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        foregroundColor: quizWhatsAppTeal,
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mode == _QuizBuildMode.aiken
                            ? 'Imported questions will appear next.'
                            : 'You\'ll write questions in the next step.',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
    final Color outline = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.22);

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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
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
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Options
                ...List.generate(question.options.length, (optionIndex) {
                  final optionController = question.options[optionIndex];
                  final bool canRemoveOption = question.options.length > 2;
                  final bool hasOptionText =
                      optionController.text.trim().isNotEmpty;

                  return Column(
                    children: [
                      // Option image preview (shown above the option row)
                      if (optionIndex < question.optionImages.length &&
                          question.optionImages[optionIndex] != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 32, top: 4, right: 8),
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
                                      color: Colors.black.withValues(alpha: 0.6),
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
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.25),
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
                                          left: 2, top: 4, bottom: 4),
                                      child: Icon(
                                        (optionIndex <
                                                    question.optionImages
                                                        .length &&
                                                question.optionImages[
                                                        optionIndex] !=
                                                    null)
                                            ? Icons.image
                                            : Icons.image_outlined,
                                        size: 22,
                                        color: (optionIndex <
                                                    question.optionImages
                                                        .length &&
                                                question.optionImages[
                                                        optionIndex] !=
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
                                    padding: const EdgeInsets.only(left: 2, top: 4, bottom: 4),
                                    child: Icon(
                                      question.correctIndex == optionIndex
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked,
                                      size: 24,
                                      color: question.correctIndex == optionIndex
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
                                      padding: EdgeInsets.only(left: 2, right: 4, top: 4, bottom: 4),
                                      child: Icon(Icons.close_rounded, size: 22),
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

