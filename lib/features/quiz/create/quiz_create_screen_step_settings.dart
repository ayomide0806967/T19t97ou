part of 'quiz_create_screen.dart';

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
    final Color outline = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.22,
    );
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );

    String deadlineLabel;
    if (!hasDeadline || closingDate == null) {
      deadlineLabel = 'Set closing time';
    } else {
      final date = localizations.formatMediumDate(closingDate!);
      final time = localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(closingDate!),
      );
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
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    final bool selected = states.contains(WidgetState.selected);
                    return selected ? Colors.white : Colors.black;
                  }),
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
                        Duration selected = Duration(
                          minutes: currentMinutes.clamp(1, 360),
                        );
                        await showModalBottomSheet<void>(
                          context: context,
                          useSafeArea: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (ctx) {
                            return StatefulBuilder(
                              builder: (ctx, setModalState) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    24,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
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
                                              () => selected = duration,
                                            );
                                            final int mins = duration.inMinutes
                                                .clamp(1, 360);
                                            timeLimitController.text = mins
                                                .toString();
                                            onTimeLimitChanged(mins.toDouble());
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
                                                  text: initialHours.toString(),
                                                );
                                            final TextEditingController
                                            minutesController =
                                                TextEditingController(
                                                  text: initialMinutes
                                                      .toString(),
                                                );

                                            final Duration?
                                            manualResult = await showDialog<Duration>(
                                              context: ctx,
                                              builder: (dialogCtx) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  title: const Text(
                                                    'Set duration manually',
                                                  ),
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
                                                              3,
                                                            ),
                                                          ],
                                                          decoration: InputDecoration(
                                                            labelText: 'HOUR',
                                                            border: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
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
                                                              2,
                                                            ),
                                                          ],
                                                          decoration: InputDecoration(
                                                            labelText: 'MINUTE',
                                                            border: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
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
                                                            dialogCtx,
                                                          ).pop(),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        final int h =
                                                            int.tryParse(
                                                              hoursController
                                                                  .text,
                                                            ) ??
                                                            0;
                                                        final int m =
                                                            int.tryParse(
                                                              minutesController
                                                                  .text,
                                                            ) ??
                                                            0;
                                                        int total = h * 60 + m;
                                                        if (total < 1) {
                                                          total = 1;
                                                        }
                                                        if (total > 360) {
                                                          total = 360;
                                                        }
                                                        Navigator.of(
                                                          dialogCtx,
                                                        ).pop(
                                                          Duration(
                                                            minutes: total,
                                                          ),
                                                        );
                                                      },
                                                      child: const Text(
                                                        'Apply',
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (manualResult != null) {
                                              setModalState(
                                                () => selected = manualResult,
                                              );
                                              final int mins = manualResult
                                                  .inMinutes
                                                  .clamp(1, 360);
                                              timeLimitController.text = mins
                                                  .toString();
                                              onTimeLimitChanged(
                                                mins.toDouble(),
                                              );
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
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    final bool selected = states.contains(WidgetState.selected);
                    return selected ? Colors.white : Colors.black;
                  }),
                ),
                if (hasDeadline) ...[
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: onPickDeadline,
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  key: ValueKey<int?>(attemptLimit),
                  initialValue: attemptLimit,
                  items: attemptItems,
                  onChanged: onAttemptsChanged,
                  decoration: const InputDecoration(
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
                  activeTrackColor: quizWhatsAppTeal,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    final bool selected = states.contains(WidgetState.selected);
                    return selected ? Colors.white : Colors.black;
                  }),
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
