part of '../ios_messages_screen.dart';

class _CollegeScreenState extends State<_CollegeScreen> {
  final TextEditingController _composer = TextEditingController();
  late Set<String> _members;
  final List<_ClassMessage> _notes = <_ClassMessage>[];
  // New UI state
  ClassTopic? _activeTopic;
  final List<ClassTopic> _archivedTopics = <ClassTopic>[];
  // Role + settings
  late final Set<String> _admins;
  bool _adminOnlyPosting = true;
  bool _allowReplies = true;
  bool _allowMedia = false;
  bool _approvalRequired = false;
  bool _isPrivate = true;
  bool _autoArchiveOnEnd = true;
  final Set<String> _unlockedTopicTags = <String>{};

  @override
  void initState() {
    super.initState();
    _members = Set<String>.from(widget.college.memberHandles);
    _admins = <String>{_currentUserHandle};
    _bootstrapAdmins();
    _bootstrapMembers();
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

  Future<void> _openManageAdminsSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final code = widget.college.code;
    final List<String> members = _members.toList()
      ..sort((a, b) => a.compareTo(b));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      S.manageAdmins,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final handle = members[index];
                        final bool isAdmin = _admins.contains(handle);
                        final bool isSelf = handle == _currentUserHandle;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_outline),
                          title: Text(handle),
                          trailing: Switch(
                            value: isAdmin,
                            onChanged: (v) async {
                              if (!mounted) return;
                              if (!v) {
                                // Prevent removing the last admin
                                if (_admins.length <= 1 && isAdmin) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'At least one admin is required',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _admins.remove(handle));
                              } else {
                                setState(() => _admins.add(handle));
                              }
                              await RolesService.saveAdminsFor(code, _admins);
                              if (isSelf &&
                                  !_admins.contains(_currentUserHandle)) {
                                // If user demoted self and sheet still open, update UI
                                setState(() {});
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSuspendMembersSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final code = widget.college.code;
    final List<String> members = _members.toList()
      ..sort((a, b) => a.compareTo(b));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      S.suspendMembers,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final handle = members[index];
                        final bool isSelf = handle == _currentUserHandle;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_outline),
                          title: Text(handle),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: isSelf
                                    ? null
                                    : () async {
                                        final ok =
                                            await showDialog<bool>(
                                              context: ctx,
                                              builder: (d) => AlertDialog(
                                                title: const Text(
                                                  'Remove member?',
                                                ),
                                                content: Text(
                                                  'Remove $handle from this class?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          d,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          d,
                                                        ).pop(true),
                                                    child: const Text('Remove'),
                                                  ),
                                                ],
                                              ),
                                            ) ??
                                            false;
                                        if (!ok) return;
                                        setState(() {
                                          _members.remove(handle);
                                          _admins.remove(handle);
                                        });
                                        await _persistMembers();
                                        await RolesService.saveAdminsFor(
                                          code,
                                          _admins,
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Removed $handle'),
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _bootstrapAdmins() async {
    final code = widget.college.code;
    final saved = await RolesService.getAdminsFor(code);
    if (saved.isEmpty) {
      // Initialize with current user as admin and persist
      _admins = <String>{_currentUserHandle};
      await RolesService.saveAdminsFor(code, _admins);
    } else {
      setState(() {
        _admins = saved;
      });
    }
  }

  Future<void> _bootstrapMembers() async {
    final code = widget.college.code;
    final saved = await MembersService.getMembersFor(code);
    if (saved.isEmpty) {
      final initial = <String>{
        ...widget.college.memberHandles,
        _currentUserHandle,
      };
      _members = initial;
      await MembersService.saveMembersFor(code, _members);
    } else {
      setState(() {
        _members = saved;
      });
    }
  }

  Future<void> _persistMembers() async {
    await MembersService.saveMembersFor(widget.college.code, _members);
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  String get _currentUserHandle {
    return deriveHandleFromEmail(
      SimpleAuthService().currentUserEmail,
      maxLength: 999,
    );
  }

  bool get _isCurrentUserAdmin => _admins.contains(_currentUserHandle);

  @override
  Widget build(BuildContext context) {
    final college = widget.college;
    // Auto-archive if schedule passed
    if (_activeTopic != null && _activeTopic!.autoArchiveAt != null) {
      final at = _activeTopic!.autoArchiveAt!;
      if (DateTime.now().isAfter(at)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _archivedTopics.add(_activeTopic!);
            _activeTopic = null;
          });
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
                  )!;
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
              activeTopic: _activeTopic,
              onSend: (text) => _handleSubmitLectureNote(context, text),
              isAdmin: _isCurrentUserAdmin,
              settings: _ClassSettings(
                adminOnlyPosting: _adminOnlyPosting,
                allowReplies: _allowReplies,
                allowMedia: _allowMedia,
                approvalRequired: _approvalRequired,
                isPrivate: _isPrivate,
                autoArchiveOnEnd: _autoArchiveOnEnd,
              ),
              memberCount: _members.length,
              onStartLecture: (course, tutor, topic, s) {
                setState(() {
                  _activeTopic = ClassTopic(
                    courseName: course,
                    tutorName: tutor.isEmpty ? 'Admin' : tutor,
                    topicTitle: topic,
                    createdAt: DateTime.now(),
                    privateLecture: s.privateLecture,
                    requirePin: s.requirePin,
                    pinCode: s.pinCode,
                    autoArchiveAt: s.autoArchiveAt,
                  );
                });
              },
              onArchiveTopic: () {
                if (_activeTopic == null) return;
                setState(() {
                  _archivedTopics.add(_activeTopic!);
                  _activeTopic = null;
                });
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
              requiresPin: _activeTopic?.requirePin ?? false,
              pinCode: _activeTopic?.pinCode,
              unlocked: _activeTopic == null
                  ? true
                  : _unlockedTopicTags.contains(_activeTopic!.topicTag),
              onUnlock: (attempt) {
                if (_activeTopic?.pinCode != null &&
                    attempt.trim() == _activeTopic!.pinCode) {
                  setState(() {
                    _unlockedTopicTags.add(_activeTopic!.topicTag);
                  });
                  return true;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
                return false;
              },
            ),
            _ClassLibraryTab(college: college, topics: _archivedTopics),
            _ClassStudentsTab(
              members: _members,
              onAdd: _addMember,
              onExit: _exitClass,
              onSuspend: (h) {
                setState(() => _members.remove(h));
                _persistMembers();
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
    var adminOnlyPosting = _adminOnlyPosting;
    var allowReplies = _allowReplies;
    var isPrivate = _isPrivate;

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
                          setState(() {
                            _adminOnlyPosting = v;
                          });
                        },
                      ),
                      SettingSwitchRow(
                        label: 'Allow replies',
                        value: allowReplies,
                        onChanged: (v) {
                          setSheetState(() {
                            allowReplies = v;
                          });
                          setState(() {
                            _allowReplies = v;
                          });
                        },
                      ),
                      SettingSwitchRow(
                        label: 'Private class',
                        value: isPrivate,
                        onChanged: (v) {
                          setSheetState(() {
                            isPrivate = v;
                          });
                          setState(() {
                            _isPrivate = v;
                          });
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
                                    builder: (_) => const _CreateClassPage(
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
                                final code =
                                    await InvitesService.getOrCreateCode(
                                  widget.college.code,
                                );
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
    if (_activeTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start a lecture above before adding notes'),
        ),
      );
      return;
    }
    final data = context.read<DataService>();
    final String topicTag = _activeTopic!.topicTag;
    await data.addPost(
      author: _activeTopic!.tutorName,
      handle: _currentUserHandle,
      body: text,
      tags: <String>[topicTag, widget.college.code],
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added note to "${_activeTopic!.topicTitle}"')),
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
              setState(() => _members.add(h));
              _persistMembers();
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
