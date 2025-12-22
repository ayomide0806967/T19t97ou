part of 'quiz_live_monitor_screen.dart';

mixin _QuizLiveMonitorScreenActions on _QuizLiveMonitorScreenStateBase {
  void _onFilterChanged(String value) {
    setState(() => _filter = value);
  }

  void _openParticipantDetails(BuildContext context, LiveParticipant p) {
    final theme = Theme.of(context);
    final int remaining = (p.totalQuestions - p.answeredCount).clamp(
      0,
      p.totalQuestions,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      p.initials,
                      style: theme.textTheme.titleMedium?.copyWith(
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
                          p.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusLabel(p.status),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _statusColor(
                              theme,
                              p.status,
                            ).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _DetailMetric(
                    label: 'Answered',
                    value: '${p.answeredCount}/${p.totalQuestions}',
                  ),
                  const SizedBox(width: 16),
                  _DetailMetric(
                    label: 'Current question',
                    value: p.currentQuestion == 0
                        ? 'Not started'
                        : '${p.currentQuestion}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _DetailMetric(label: 'Remaining', value: '$remaining'),
                  const SizedBox(width: 16),
                  _DetailMetric(
                    label: 'Last seen',
                    value: _timeAgo(p.lastSeen),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (alertCtx) => AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            title: const Text('Send nudge?'),
                            content: Text(
                              'This will send a gentle reminder to ${p.name}.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(alertCtx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(alertCtx).pop(true),
                                child: const Text('Send'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        if (!context.mounted || !ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Nudge sent to ${p.name}.')),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: Text(
                        'Send nudge',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (alertCtx) => AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            title: const Text('Pause this quiz?'),
                            content: Text(
                              'This will temporarily pause the quiz for ${p.name}.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(alertCtx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(alertCtx).pop(true),
                                child: const Text('Pause'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        if (!context.mounted || !ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Quiz paused for ${p.name}.')),
                        );
                      },
                      icon: const Icon(Icons.pause_circle_outline, size: 18),
                      label: Text(
                        'Pause',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (alertCtx) => AlertDialog(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          title: const Text('Terminate this attempt?'),
                          content: Text(
                            'This will end ${p.name}\'s quiz immediately and flag it for malpractice.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(alertCtx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(alertCtx).pop(true),
                              child: const Text(
                                'Terminate',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      if (!context.mounted || !ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      setState(() {
                        final index = _participants.indexWhere(
                          (participant) => participant.id == p.id,
                        );
                        if (index != -1) {
                          final existing = _participants[index];
                          _participants[index] = LiveParticipant(
                            name: existing.name,
                            id: existing.id,
                            status: ParticipantStatus.terminated,
                            currentQuestion: existing.currentQuestion,
                            totalQuestions: existing.totalQuestions,
                            answeredCount: existing.answeredCount,
                            lastSeen: existing.lastSeen,
                          );
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Text(
                            'Attempt terminated and flagged for malpractice for ${p.name}.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.report_gmailerrorred_outlined,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: const Text(
                      'Terminate (malpractice)',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.inProgress:
        return 'Online · In progress';
      case ParticipantStatus.submitted:
        return 'Submitted';
      case ParticipantStatus.offline:
        return 'Offline';
      case ParticipantStatus.suspect:
        return 'Suspect activity';
      case ParticipantStatus.terminated:
        return 'Terminated';
    }
  }

  Color _statusColor(ThemeData theme, ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.inProgress:
        return Colors.green;
      case ParticipantStatus.submitted:
        return const Color(0xFF075E54);
      case ParticipantStatus.offline:
        return theme.colorScheme.onSurface.withValues(alpha: 0.55);
      case ParticipantStatus.suspect:
        return Colors.orange;
      case ParticipantStatus.terminated:
        return Colors.red;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
