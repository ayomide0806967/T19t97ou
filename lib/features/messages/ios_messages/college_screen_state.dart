part of '../ios_messages_screen.dart';

class _CollegeScreenState extends ConsumerState<_CollegeScreen> {
  final TextEditingController _composer = TextEditingController();
  final List<_ClassMessage> _notes = <_ClassMessage>[];

  CollegeUiState get _uiState =>
      ref.watch(collegeScreenControllerProvider(widget.college.code));

  CollegeScreenController get _uiController =>
      ref.read(collegeScreenControllerProvider(widget.college.code).notifier);

  @override
  void initState() {
    super.initState();
    _bootstrapRoom();
    // Seed demo comments to match the provided reference image.
    if (_notes.isEmpty && widget.college.code == 'CVE220') {
      _notes.addAll(<_ClassMessage>[
        _ClassMessage(
          id: 'seed1',
          author: '@ArkhamLover7',
          handle: '@ArkhamLover7',
          timeAgo: '1d ago',
          body:
              'Before all of the “I was a Muslim” or “I was dying” comments come in, remember that even if your story feels insignificant, the God of the universe took on flesh, obeyed for YOU, died for YOU, and was raised for YOU. Your story in Him matters beyond measure.',
          likes: 663,
          replies: 19,
          heartbreaks: 0,
        ),
        _ClassMessage(
          id: 'seed2',
          author: '@RichardKearns',
          handle: '@RichardKearns',
          timeAgo: '1d ago',
          body:
              'My only issue with this song is that it’s not long enough! I’ve had to replay it 5 times in a row because it’s just so good, it needs to be just a full hour of nonstop worship! I LOVE IT!!!!',
          likes: 256,
          replies: 10,
          heartbreaks: 0,
        ),
        // ~378 words (below 400) — should NOT collapse now.
        _ClassMessage(
          id: 'seed5',
          author: 'System',
          handle: '@exam_board',
          timeAgo: '3d ago',
          body: '''
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early.''',
          likes: 5,
          replies: 1,
          heartbreaks: 0,
        ),
        // ~405 words (above 400) — should collapse with "Read more".
        _ClassMessage(
          id: 'seed6',
          author: 'System',
          handle: '@exam_board',
          timeAgo: '3d ago',
          body: '''
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early. 
Mock exam briefing extended update: please review chapters one through five, practice data interpretation, manage time carefully, bring ID, calculator, pencils, water, rest well, and arrive early.''',
          likes: 8,
          replies: 2,
          heartbreaks: 0,
        ),
        // Exactly ~40 words: should not collapse.
        _ClassMessage(
          id: 'seed3',
          author: 'System',
          handle: '@exam_board',
          timeAgo: '2d ago',
          body:
              'Mock exam guidelines: arrive early, bring ID, calculator, and water. Read every question carefully, manage time wisely, attempt all sections, show workings, review answers before submission, stay calm, breathe, and trust your preparation. Good luck to everyone participating this season.',
          likes: 14,
          replies: 2,
          heartbreaks: 0,
        ),
        // More than 50 words: should collapse with Read more.
        _ClassMessage(
          id: 'seed4',
          author: 'System',
          handle: '@exam_board',
          timeAgo: '2d ago',
          body:
              'Mock exam briefing: the paper covers chapters one to five, including case studies and data interpretation. Expect multiple choice, short answers, and one essay. Bring two pencils, an approved calculator, and your ID. Arrive thirty minutes early. Practice past questions tonight and sleep well; you’ve got this. Remember to label your scripts clearly and check page numbers.',
          likes: 8,
          replies: 1,
          heartbreaks: 0,
        ),
      ]);
    }
    // Replace demo notes with new aligned data
    if (widget.college.code == 'CVE220') {
      _notes
        ..clear()
        ..addAll(<_ClassMessage>[
          _ClassMessage(
            id: 'n1',
            author: '@StudyCouncil',
            handle: '@study_council',
            timeAgo: '3d ago',
            body:
                'Mid‑sem schedule posted on the portal. Lab sessions moved to Week 6.',
            likes: 12,
            replies: 4,
            heartbreaks: 0,
          ),
          _ClassMessage(
            id: 'n2',
            author: '@TutorAnika',
            handle: '@tutor_anika',
            timeAgo: '2d ago',
            body:
                'Cardio physiology slides added in Resources → Week 2. Read before lab.',
            likes: 7,
            replies: 3,
            heartbreaks: 0,
          ),
          _ClassMessage(
            id: 'n3',
            author: 'System',
            handle: '@exam_board',
            timeAgo: 'Yesterday',
            body: 'Mock exam on 18 Oct at 09:00. Bring ID and a calculator.',
            likes: 3,
            replies: 1,
            heartbreaks: 0,
          ),
        ]);
    }
  }

  Future<void> _bootstrapRoom() async {
    final controller =
        ref.read(classRoomControllerProvider(widget.college.code).notifier);
    await controller.bootstrap(
      initialMemberHandles: widget.college.memberHandles,
      currentUserHandle: _currentUserHandle,
    );
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  String get _currentUserHandle {
    return ref.read(currentUserHandleProvider);
  }

  ClassRoomState get _roomState =>
      ref.watch(classRoomControllerProvider(widget.college.code));

  Set<String> get _members => _roomState.members;

  bool get _isCurrentUserAdmin =>
      _roomState.admins.contains(_currentUserHandle);

  @override
  Widget build(BuildContext context) {
    final college = widget.college;
    final activeTopic = _uiState.activeTopic;
    // Auto-archive if schedule passed
    if (activeTopic != null && activeTopic.autoArchiveAt != null) {
      final at = activeTopic.autoArchiveAt!;
      if (DateTime.now().isAfter(at)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _uiController.archiveActiveTopic();
        });
      }
    }
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            if (_isCurrentUserAdmin)
              IconButton(
                tooltip: 'Class settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  _openSettingsSheet(context);
                },
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Builder(
                builder: (context) {
                  final TabController controller = DefaultTabController.of(
                    context,
                  );
                  return AnimatedBuilder(
                    animation: controller.animation ?? controller,
                    builder: (context, _) {
                      final int index = controller.index;
                      Color indicatorColor;
                      if (index == 1) {
                        indicatorColor = Colors.red;
                      } else if (index == 2) {
                        indicatorColor = Colors.black;
                      } else {
                        indicatorColor = _whatsAppDarkGreen;
                      }
                      return Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.9,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: TabBar(
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                          unselectedLabelStyle: theme.textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Roboto',
                              ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black,
                          indicator: BoxDecoration(
                            color: indicatorColor,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: indicatorColor.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          indicatorPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Class'),
                            Tab(text: 'Library'),
                            Tab(text: 'Students'),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            _ClassFeedTab(
              college: college,
              notes: _notes,
              activeTopic: _uiState.activeTopic,
              onSend: (text) => _handleSubmitLectureNote(context, text),
              isAdmin: _isCurrentUserAdmin,
              settings: _ClassSettings(
                adminOnlyPosting: _uiState.adminOnlyPosting,
                allowReplies: _uiState.allowReplies,
                allowMedia: _uiState.allowMedia,
                approvalRequired: _uiState.approvalRequired,
                isPrivate: _uiState.isPrivate,
                autoArchiveOnEnd: _uiState.autoArchiveOnEnd,
              ),
              memberCount: _members.length,
              onStartLecture: (course, tutor, topic, s) {
                _uiController.startLecture(
                  ClassTopic(
                    courseName: course,
                    tutorName: tutor.isEmpty ? 'Admin' : tutor,
                    topicTitle: topic,
                    createdAt: DateTime.now(),
                    privateLecture: s.privateLecture,
                    requirePin: s.requirePin,
                    pinCode: s.pinCode,
                    autoArchiveAt: s.autoArchiveAt,
                  ),
                );
              },
              onArchiveTopic: () {
                if (_uiState.activeTopic == null) return;
                _uiController.archiveActiveTopic();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Moved to Library')),
                );
              },
              onShare: (msg) async {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(S.useRepostToast)));
              },
              requiresPin: _uiState.activeTopic?.requirePin ?? false,
              pinCode: _uiState.activeTopic?.pinCode,
              unlocked: _uiState.activeTopic == null
                  ? true
                  : _uiState.unlockedTopicTags
                      .contains(_uiState.activeTopic!.topicTag),
              onUnlock: (attempt) {
                final active = _uiState.activeTopic;
                if (active?.pinCode != null &&
                    attempt.trim() == active!.pinCode) {
                  _uiController.unlockTopicTag(active.topicTag);
                  return true;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
                return false;
              },
            ),
            _ClassLibraryTab(college: college, topics: _uiState.archivedTopics),
            _ClassStudentsTab(
              members: _members,
              onAdd: _addMember,
              onExit: _exitClass,
              onSuspend: (h) {
                ref
                    .read(
                      classRoomControllerProvider(widget.college.code)
                          .notifier,
                    )
                    .removeMember(h);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Suspended $h')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    // Local snapshot so the bottom sheet can rebuild independently.
    var adminOnlyPosting = _uiState.adminOnlyPosting;
    var allowReplies = _uiState.allowReplies;
    var isPrivate = _uiState.isPrivate;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.8;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                            color: theme.dividerColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      SettingSwitchRow(
                        label: 'Admin-only posting',
                        value: adminOnlyPosting,
                        onChanged: (v) {
                          setSheetState(() {
                            adminOnlyPosting = v;
                          });
                          _uiController.setAdminOnlyPosting(v);
                        },
                      ),
                      SettingSwitchRow(
                        label: 'Allow replies',
                        value: allowReplies,
                        onChanged: (v) {
                          setSheetState(() {
                            allowReplies = v;
                          });
                          _uiController.setAllowReplies(v);
                        },
                      ),
                      SettingSwitchRow(
                        label: 'Private class',
                        value: isPrivate,
                        onChanged: (v) {
                          setSheetState(() {
                            isPrivate = v;
                          });
                          _uiController.setIsPrivate(v);
                        },
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.tune, size: 18),
                              label: const Text('Open full settings'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 0),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                side: BorderSide(
                                  color:
                                      Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CreateClassScreen(
                                      initialStep: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 0),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color:
                                      Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                              icon: const Icon(Icons.link_outlined, size: 18),
                              label: const Text('Invite by code'),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                final code = await ref
                                    .read(classInvitesSourceProvider)
                                    .getOrCreateCode(widget.college.code);
                                if (!context.mounted) return;
                                showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (sheet) => SafeArea(
                                    top: false,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        16,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                S.inviteByCode,
                                                style: Theme.of(sheet)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon:
                                                    const Icon(Icons.close),
                                                onPressed: () =>
                                                    Navigator.of(sheet).pop(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: Theme.of(sheet)
                                                      .dividerColor
                                                      .withValues(
                                                        alpha: 0.25,
                                                      ),
                                                ),
                                              ),
                                              child: Text(
                                                code,
                                                style: Theme.of(sheet)
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: FilledButton.icon(
                                              icon: const Icon(Icons.copy),
                                              onPressed: () async {
                                                await Clipboard.setData(
                                                  ClipboardData(text: code),
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        S.inviteCodeCopied,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              label: Text(S.copyCode),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          label: const Text('Delete class'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.4),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _exitClass(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSubmitLectureNote(
    BuildContext context,
    String body,
  ) async {
    final text = body.trim();
    if (text.isEmpty) return;
    if (!_isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can publish lecture notes')),
      );
      return;
    }
    final activeTopic = _uiState.activeTopic;
    if (activeTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start a lecture above before adding notes'),
        ),
      );
      return;
    }
    final String topicTag = activeTopic.topicTag;
    await ref.read(classNotesControllerProvider.notifier).publishLectureNote(
          tutorName: activeTopic.tutorName,
          currentUserHandle: _currentUserHandle,
          body: text,
          topicTag: topicTag,
          classCode: widget.college.code,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added note to "${activeTopic.topicTitle}"')),
    );
  }

  Future<void> _addMember(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add student'),
        content: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          cursorColor: Colors.black,
          decoration: const InputDecoration(hintText: '@handle'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
              FilledButton(
            onPressed: () {
              String h = controller.text.trim();
              if (h.isEmpty) return;
              if (!h.startsWith('@')) h = '@$h';
              ref
                  .read(
                    classRoomControllerProvider(widget.college.code).notifier,
                  )
                  .addMember(h);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Added $h')));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _exitClass(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit class?'),
        content: const Text('You will stop receiving updates from this class.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Exited class')));
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
