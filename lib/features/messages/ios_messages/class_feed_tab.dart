part of '../ios_messages_screen.dart';

class _ClassFeedTab extends ConsumerStatefulWidget {
  const _ClassFeedTab({
    required this.college,
    required this.notes,
    required this.onSend,
    required this.onShare,
    required this.onStartLecture,
    required this.onArchiveTopic,
    required this.isAdmin,
    required this.settings,
    required this.memberCount,
    this.activeTopic,
    this.requiresPin = false,
    this.pinCode,
    this.unlocked = true,
    this.onUnlock,
  });
  final College college;
  final List<_ClassMessage> notes;
  final ClassTopic? activeTopic;
  final ValueChanged<String> onSend;
  final Future<void> Function(_ClassMessage message) onShare;
  final void Function(
    String course,
    String tutor,
    String topic,
    _TopicSettings settings,
  )
  onStartLecture;
  final VoidCallback onArchiveTopic;
  final bool isAdmin;
  final _ClassSettings settings;
  final int memberCount;
  final bool requiresPin;
  final String? pinCode;
  final bool unlocked;
  final bool Function(String attempt)? onUnlock;

  @override
  ConsumerState<_ClassFeedTab> createState() => _ClassFeedTabState();
}

class _ClassFeedTabState extends ConsumerState<_ClassFeedTab> {
  @override
  void initState() {
    super.initState();
    _initNotes();
  }

  Future<void> _initNotes() async {
    await ref
        .read(classNotesShelfControllerProvider(widget.college.code).notifier)
        .load();
  }

  Future<void> _confirmDeleteNote(ClassNoteSummary note) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete lecture note?'),
        content: const Text(
          'This will permanently remove the note from this class.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(classNotesShelfControllerProvider(widget.college.code).notifier)
        .deleteClassNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lecture note deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    final notesState =
        ref.watch(classNotesShelfControllerProvider(widget.college.code));
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              // Class header now scrolls away with the feed so that
              // the tab bar becomes the sticky hero at the top.
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.college.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.college.facilitator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ClassHeaderChip(
                          icon: Icons.people_alt_outlined,
                          label: '${widget.college.members} students',
                        ),
                        const SizedBox(width: 8),
                        if (widget.college.upcomingExam.isNotEmpty)
                          _ClassHeaderChip(
                            icon: Icons.schedule_rounded,
                            label: widget.college.upcomingExam,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Class discussion label sits above the lecture CTA so
              // both the create button and cards feel grouped under it.
              Text(
                S.classDiscussion,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _ClassActionCard(
                        title: 'Create a lecture note',
                        backgroundColor: _whatsAppGreen.withValues(alpha: 0.15),
                        playIconColor: _whatsAppTeal,
                        onTap: () async {
                          final summary = await Navigator.of(context)
                              .push<ClassNoteSummary>(
                                MaterialPageRoute(
                                  builder: (_) => _LectureSetupPage(
                                    college: widget.college,
                                    onStartLecture: widget.onStartLecture,
                                  ),
                                ),
                              );
                          if (summary != null && mounted) {
                            await ref
                                .read(
                                  classNotesShelfControllerProvider(
                                    widget.college.code,
                                  ).notifier,
                                )
                                .addClassNote(summary);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ] else
                const SizedBox.shrink(),
              const SizedBox(height: 12),
              if (widget.activeTopic != null) ...[
                if (widget.requiresPin && !widget.unlocked)
                  _PinGateCard(
                    onUnlock: (code) {
                      if (widget.onUnlock != null) widget.onUnlock!(code);
                    },
                  )
                else
                  _TopicFeedList(topic: widget.activeTopic!),
                const SizedBox(height: 16),
              ],
              if (notesState.classNotes.isEmpty) ...[
                Text(
                  'Class notes you create will appear here.',
                  style: theme.textTheme.bodySmall?.copyWith(color: subtle),
                ),
                const SizedBox(height: 4),
              ] else ...[
                Column(
                  children: [
                    for (final note in notesState.classNotes) ...[
                      _ClassNotesCard(
                        summary: note,
                        onUpdated: (updated) {
                          ref
                              .read(
                                classNotesShelfControllerProvider(
                                  widget.college.code,
                                ).notifier,
                              )
                              .updateClassNote(note, updated);
                        },
                        onMoveToLibrary: () async {
                          await ref
                              .read(
                                classNotesShelfControllerProvider(
                                  widget.college.code,
                                ).notifier,
                              )
                              .moveToLibrary(note);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Moved to Library')),
                          );
                        },
                        onDelete: () {
                          _confirmDeleteNote(note);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
