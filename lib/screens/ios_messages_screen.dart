import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// Note: file_picker is optional. We avoid importing it so the app builds even
// when the dependency hasn't been fetched. If you add file_picker to
// pubspec and run `flutter pub get`, you can re-enable file attachments by
// switching _handleAttachFile() to use FilePicker.
import 'quiz_hub_screen.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../services/data_service.dart';
import '../models/post.dart';
import '../widgets/tweet_post_card.dart';
import '../widgets/icons/x_retweet_icon.dart';
import '../theme/app_theme.dart';
import '../services/simple_auth_service.dart';
import '../services/roles_service.dart';
import '../screens/post_activity_screen.dart';
import '../screens/create_note_flow/teacher_note_creation_screen.dart';
import '../services/members_service.dart';
import '../services/invites_service.dart';
import 'user_profile_screen.dart';
import 'create_class_screen.dart';
import 'class_note_stepper_screen.dart';
import '../widgets/equal_width_buttons_row.dart';
import '../widgets/setting_switch_row.dart';
import '../models/class_note.dart';
import '../models/college.dart';
import '../models/class_topic.dart';
import '../features/notes/class_notes_store.dart';
// Removed unused tweet widgets imports

part 'ios_messages/replies_route.dart';
part 'ios_messages/minimalist_message_page.dart';
part 'ios_messages/full_page_classes_screen.dart';
part 'ios_messages/spotify_style_hero.dart';
part 'ios_messages/inbox_list.dart';
part 'ios_messages/classes_experience.dart';
part 'ios_messages/create_class_page.dart';
part 'ios_messages/college_detail_screen.dart';
part 'ios_messages/discussion_thread_page.dart';
part 'ios_messages/thread_models.dart';

part 'ios_messages/interaction_widgets.dart';
part 'ios_messages/message_comments_page.dart';
part 'ios_messages/comment_tile.dart';

part 'ios_messages/class_notes_card.dart';
part 'ios_messages/class_message_model.dart';
part 'ios_messages/class_library_tab.dart';
part 'ios_messages/class_students_tab.dart';

part 'ios_messages/college_screen_state.dart';

part 'ios_messages/class_feed_tab.dart';

// WhatsApp color palette for Classes screen
const Color _whatsAppGreen = Color(0xFF25D366);
const Color _whatsAppDarkGreen = Color(0xFF128C7E);
const Color _whatsAppLightGreen = Color(0xFFDCF8C6);
const Color _whatsAppTeal = Color(0xFF075E54);

// (moved to ios_messages/create_class_page.dart)

class _CreateClassStepContent extends StatelessWidget {
  const _CreateClassStepContent({
    required this.theme,
    required this.step,
    required this.name,
    required this.code,
    required this.facilitator,
    required this.description,
    required this.isPrivate,
    required this.adminOnlyPosting,
    required this.approvalRequired,
    required this.allowMedia,
    required this.onBack,
    required this.onNext,
    required this.onCreate,
    required this.formKey,
    required this.stepTitles,
  });

  final ThemeData theme;
  final int step;
  final TextEditingController name;
  final TextEditingController code;
  final TextEditingController facilitator;
  final TextEditingController description;
  final bool isPrivate;
  final bool adminOnlyPosting;
  final bool approvalRequired;
  final bool allowMedia;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onCreate;
  final GlobalKey<FormState> formKey;
  final List<String> stepTitles;

  @override
  Widget build(BuildContext context) {
    Widget panel(Widget child) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
          ),
        ),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepTitles[step],
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (step == 0) ...[
          panel(
            Theme(
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
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
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
              child: LayoutBuilder(
                builder: (context, inner) {
                  final twoCols = inner.maxWidth >= 520;
                  if (twoCols) {
                    final double col = (inner.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: name,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Class name',
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter a class name'
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: code,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Code (optional)',
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: facilitator,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Facilitator (optional)',
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          width: col,
                          child: TextFormField(
                            controller: description,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Class name',
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a class name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: code,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Code (optional)',
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: facilitator,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Facilitator (optional)',
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: description,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ] else if (step == 1) ...[
          SettingSwitchRow(
            label: 'Private class',
            subtitle: 'Join via invite only',
            value: isPrivate,
            onChanged: (_) {},
          ),
          SettingSwitchRow(
            label: 'Only admins can post',
            subtitle: 'Members can still reply',
            value: adminOnlyPosting,
            onChanged: (_) {},
          ),
          SettingSwitchRow(
            label: 'Approval required for member posts',
            subtitle: 'Admins receive requests to approve',
            value: approvalRequired,
            onChanged: (_) {},
          ),
        ] else if (step == 2) ...[
          SettingSwitchRow(
            label: 'Allow media attachments',
            subtitle: 'Images and files in posts',
            value: allowMedia,
            onChanged: (_) {},
          ),
        ] else ...[
          _ReviewSummary(
            name: name.text.trim(),
            code: code.text.trim(),
            facilitator: facilitator.text.trim(),
            description: description.text.trim(),
            isPrivate: isPrivate,
            adminOnlyPosting: adminOnlyPosting,
            approvalRequired: approvalRequired,
            allowMedia: allowMedia,
          ),
        ],
        const SizedBox(height: 16),
        if (step == 0)
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) onNext();
                },
                child: const Text('Next'),
              ),
            ],
          )
        else
          Row(
            children: [
              OutlinedButton(onPressed: onBack, child: const Text('Back')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (step < 3) {
                    onNext();
                  } else {
                    onCreate();
                  }
                },
                child: Text(step == 3 ? 'Create' : 'Next'),
              ),
            ],
          ),
      ],
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({
    required this.name,
    required this.code,
    required this.facilitator,
    required this.description,
    required this.isPrivate,
    required this.adminOnlyPosting,
    required this.approvalRequired,
    required this.allowMedia,
  });

  final String name;
  final String code;
  final String facilitator;
  final String description;
  final bool isPrivate;
  final bool adminOnlyPosting;
  final bool approvalRequired;
  final bool allowMedia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColorMuted = theme.colorScheme.onSurface.withValues(alpha: 0.75);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColorMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Class name', name),
        row('Code', code),
        row('Facilitator / Admin', facilitator),
        row('Description', description),
        const SizedBox(height: 8),
        Divider(color: theme.dividerColor.withValues(alpha: 0.25)),
        const SizedBox(height: 8),
        row('Private class', isPrivate ? 'On' : 'Off'),
        row('Only admins can post', adminOnlyPosting ? 'On' : 'Off'),
        row('Approval required', approvalRequired ? 'On' : 'Off'),
        row('Media attachments', allowMedia ? 'On' : 'Off'),
      ],
    );
  }
}

// Removed unused _ClassStatChip widget

class _LibraryChip extends StatelessWidget {
  const _LibraryChip({required this.resource});

  final CollegeResource resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${resource.fileType.toUpperCase()} • ${resource.size}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Removed unused _TweetCard widget

// Removed unused _TweetStat widget

// Removed unused _TweetMessage model

const List<_Conversation> _demoConversations = <_Conversation>[
  _Conversation(
    name: 'Project Group A',
    initials: 'PG',
    lastMessage: 'Draft submitted. Review due Friday.',
    timeLabel: '09:40',
    unreadCount: 3,
  ),
  _Conversation(
    name: 'Tutor Anika',
    initials: 'TA',
    lastMessage: 'Slides for cardio uploaded.',
    timeLabel: 'Yesterday',
  ),
  _Conversation(
    name: 'Admissions Office',
    initials: 'AO',
    lastMessage: 'Reminder: fee payment closes Fri.',
    timeLabel: 'Mon',
    unreadCount: 1,
  ),
  _Conversation(
    name: 'Lab Team',
    initials: 'LT',
    lastMessage: 'Bring lab coats tomorrow.',
    timeLabel: '08:12',
  ),
  _Conversation(
    name: 'Study Hub',
    initials: 'SH',
    lastMessage: 'OSCE checklist updated.',
    timeLabel: 'Sun',
  ),
  _Conversation(
    name: 'Class Rep',
    initials: 'CR',
    lastMessage: 'Venue changed to Hall B.',
    timeLabel: 'Sat',
    unreadCount: 2,
  ),
];

const List<College> _demoColleges = <College>[
  College(
    name: 'Biology 401: Genetics',
    code: 'BIO401',
    facilitator: 'Dr. Tayo Ajayi • Tuesdays & Thursdays',
    members: 42,
    deliveryMode: 'Hybrid cohort',
    upcomingExam: 'Mid-sem • 18 Oct',
    resources: <CollegeResource>[
      CollegeResource(
        title: 'Gene Expression Slides',
        fileType: 'pdf',
        size: '3.2 MB',
      ),
      CollegeResource(
        title: 'CRISPR Lab Manual',
        fileType: 'pdf',
        size: '1.1 MB',
      ),
      CollegeResource(title: 'Exam Blueprint', fileType: 'pdf', size: '820 KB'),
    ],
    memberHandles: <String>{'@year3_shift', '@osce_ready', '@skillslab'},
    lectureNotes: <LectureNote>[
      LectureNote(
        title: 'Mendelian inheritance overview',
        subtitle: 'Week 1 notes',
        size: '6 pages',
      ),
      LectureNote(
        title: 'Gene regulation basics',
        subtitle: 'Week 2 notes',
        size: '9 pages',
      ),
      LectureNote(
        title: 'CRISPR: principles + ethics',
        subtitle: 'Seminar handout',
        size: '4 pages',
      ),
    ],
  ),
  College(
    name: 'Civic Education: Governance & Policy',
    code: 'CVE220',
    facilitator: 'Mrs. Amaka Eze • Mondays',
    members: 58,
    deliveryMode: 'Virtual classroom',
    upcomingExam: 'Mock exam • 26 Oct',
    resources: <CollegeResource>[
      CollegeResource(
        title: 'Policy Case Studies',
        fileType: 'pdf',
        size: '2.5 MB',
      ),
      CollegeResource(title: 'Past Questions', fileType: 'pdf', size: '4.1 MB'),
    ],
    memberHandles: <String>{'@coach_amaka', '@community_rounds'},
    lectureNotes: <LectureNote>[
      LectureNote(
        title: 'Arms of government',
        subtitle: 'Introductory lecture',
        size: '8 pages',
      ),
      LectureNote(
        title: 'Policy lifecycle',
        subtitle: 'Framework + examples',
        size: '5 pages',
      ),
    ],
  ),
  College(
    name: 'Chemistry 202: Organic Basics',
    code: 'CHM202',
    facilitator: 'Dr. Musa Bello • Wednesdays',
    members: 38,
    deliveryMode: 'On‑campus',
    upcomingExam: 'Quiz • 4 Nov',
    resources: <CollegeResource>[
      CollegeResource(
        title: 'Intro to Organic Reactions',
        fileType: 'pdf',
        size: '2.1 MB',
      ),
      CollegeResource(
        title: 'Lab Safety Checklist',
        fileType: 'pdf',
        size: '940 KB',
      ),
    ],
    memberHandles: <String>{'@lab_group_a', '@study_circle'},
    lectureNotes: <LectureNote>[
      LectureNote(
        title: 'Hydrocarbons overview',
        subtitle: 'Week 1 notes',
        size: '7 pages',
      ),
      LectureNote(
        title: 'Functional groups',
        subtitle: 'Week 2 notes',
        size: '6 pages',
      ),
    ],
  ),
  College(
    name: 'Mathematics 101: Calculus I',
    code: 'MTH101',
    facilitator: 'Prof. Kemi Adesina • Fridays',
    members: 120,
    deliveryMode: 'Lecture theatre',
    upcomingExam: 'Revision test • 12 Nov',
    resources: <CollegeResource>[
      CollegeResource(
        title: 'Limits & Continuity slides',
        fileType: 'pdf',
        size: '1.8 MB',
      ),
      CollegeResource(
        title: 'Problem set – Derivatives',
        fileType: 'pdf',
        size: '600 KB',
      ),
    ],
    memberHandles: <String>{'@calc_club', '@math_helpers'},
    lectureNotes: <LectureNote>[
      LectureNote(
        title: 'Introduction to limits',
        subtitle: 'Lecture 1',
        size: '5 pages',
      ),
      LectureNote(
        title: 'Derivative rules',
        subtitle: 'Lecture 3',
        size: '9 pages',
      ),
    ],
  ),
];

// Quiz screens exist separately; access via header quiz icon.

/// Public wrapper so other parts of the app (e.g. quiz dashboard)
/// can navigate to the class detail experience using the same layout.
// (moved to ios_messages/college_screen_state.dart)



// (moved to ios_messages/class_feed_tab.dart)



class _TopicFeedList extends StatefulWidget {
  const _TopicFeedList({required this.topic});
  final ClassTopic topic;
  @override
  State<_TopicFeedList> createState() => _TopicFeedListState();
}

class _TopicFeedListState extends State<_TopicFeedList> {
  static const int _pageSize = 10;
  int _visible = 0;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = context.watch<DataService>();
    final posts = data.posts
        .where((p) => p.tags.contains(widget.topic.topicTag))
        .toList();
    final initial = posts.isEmpty
        ? 0
        : (posts.length < _pageSize ? posts.length : _pageSize);
    if (_visible == 0 && initial != 0) {
      _visible = initial;
    } else if (_visible > posts.length) {
      _visible = posts.length;
    }
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final data = context.read<DataService>();
    final posts = data.posts
        .where((p) => p.tags.contains(widget.topic.topicTag))
        .toList();
    final next = _visible + _pageSize;
    setState(() {
      _visible = next > posts.length ? posts.length : next;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final posts = data.posts
        .where((p) => p.tags.contains(widget.topic.topicTag))
        .toList();
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }
    final slice = posts.take(_visible == 0 ? posts.length : _visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.topicNotes,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final p in slice) ...[
          // Reuse the class message-style tile so the replies pill remains
          _ClassMessageTile(
            message: _ClassMessage(
              id: p.id,
              author: p.author,
              handle: p.handle,
              timeAgo: p.timeAgo,
              body: p.body,
              likes: p.likes,
              replies: p.replies,
              heartbreaks: 0,
            ),
            onShare: () async {},
            repostEnabled: !widget.topic.privateLecture,
            onRepost: widget.topic.privateLecture
                ? null
                : () async {
                    // Derive current user handle (same as used elsewhere)
                    String me = '@yourprofile';
                    final email = SimpleAuthService().currentUserEmail;
                    if (email != null && email.isNotEmpty) {
                      final normalized = email
                          .split('@')
                          .first
                          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
                          .toLowerCase();
                      if (normalized.isNotEmpty) me = '@$normalized';
                    }
                    final toggled = await context
                        .read<DataService>()
                        .toggleRepost(postId: p.id, userHandle: me);
                    if (!context.mounted) return toggled;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          toggled
                              ? 'Reposted to your timeline'
                              : 'Repost removed',
                        ),
                      ),
                    );
                    return toggled;
                  },
          ),
          const SizedBox(height: 8),
        ],
        if ((_visible == 0 && posts.length > _pageSize) ||
            (_visible > 0 && _visible < posts.length)) ...[
          Center(
            child: SizedBox(
              width: 200,
              height: 36,
              child: OutlinedButton(
                onPressed: _loading ? null : _loadMore,
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(S.loadMoreNotes),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Lightweight relative time formatter used by ActiveTopicCard
String _formatRelative(DateTime time) {
  final Duration diff = DateTime.now().difference(time);
  if (diff.inDays >= 1) {
    final d = diff.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  }
  if (diff.inHours >= 1) {
    final h = diff.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  if (diff.inMinutes >= 1) {
    final m = diff.inMinutes;
    return m == 1 ? '1 min ago' : '$m mins ago';
  }
  return 'just now';
}

class _ClassSettings {
  const _ClassSettings({
    required this.adminOnlyPosting,
    required this.allowReplies,
    required this.allowMedia,
    required this.approvalRequired,
    required this.isPrivate,
    required this.autoArchiveOnEnd,
  });
  final bool adminOnlyPosting;
  final bool allowReplies;
  final bool allowMedia;
  final bool approvalRequired;
  final bool isPrivate;
  final bool autoArchiveOnEnd;
}

class _TopicSettings {
  const _TopicSettings({
    this.privateLecture = false,
    this.requirePin = false,
    this.pinCode,
    this.autoArchiveAt,
    this.attachQuizForNote = false,
  });
  final bool privateLecture;
  final bool requirePin;
  final String? pinCode;
  final DateTime? autoArchiveAt;
  final bool attachQuizForNote;
}

// Replaced by SettingSwitchRow in widgets/setting_switch_row.dart

class _PinGateCard extends StatefulWidget {
  const _PinGateCard({required this.onUnlock});
  final void Function(String code) onUnlock;
  @override
  State<_PinGateCard> createState() => _PinGateCardState();
}

class _PinGateCardState extends State<_PinGateCard> {
  final TextEditingController _code = TextEditingController();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter PIN to view notes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () => widget.onUnlock(_code.text.trim()),
              child: const Text('Unlock'),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reusable step rails ---
class _StepRailVertical extends StatelessWidget {
  const _StepRailVertical({
    required this.steps,
    required this.activeIndex,
    this.titles,
    this.onStepTap,
  });

  final List<String> steps; // Dot labels (e.g., 1..4)
  final List<String>? titles; // Step titles shown to the right
  final int activeIndex;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasTitles = titles != null && titles!.length == steps.length;
    final Color connectorColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.25,
    );
    const double dotSize = 24;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          InkWell(
            onTap: onStepTap == null ? null : () => onStepTap!(i),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StepDot(
                    active: i == activeIndex,
                    label: steps[i],
                    size: dotSize,
                  ),
                  if (hasTitles) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titles![i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: i == activeIndex
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: i == activeIndex
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (i < steps.length - 1)
            Row(
              children: [
                const SizedBox(width: dotSize / 2),
                Container(width: 1, height: 28, color: connectorColor),
                if (hasTitles) const SizedBox(width: 10),
                if (hasTitles) const Expanded(child: SizedBox()),
              ],
            ),
        ],
      ],
    );
  }
}

class _StepRailHorizontal extends StatelessWidget {
  const _StepRailHorizontal({
    required this.steps,
    required this.activeIndex,
    this.onStepTap,
  });

  final List<String> steps;
  final int activeIndex;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color connectorColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.25,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          InkWell(
            onTap: onStepTap == null ? null : () => onStepTap!(i),
            borderRadius: BorderRadius.circular(12),
            child: _StepDot(
              active: i == activeIndex,
              label: steps[i],
              size: 24,
            ),
          ),
          if (i < steps.length - 1)
            Container(
              width: 28,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: connectorColor,
            ),
        ],
      ],
    );
  }
}

class _StepRailMini extends StatelessWidget {
  const _StepRailMini({required this.activeIndex, required this.steps});
  final int activeIndex;
  final List<String> steps;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepDot(active: i == activeIndex, label: steps[i], size: 18),
          if (i < steps.length - 1)
            Container(
              width: 24,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.active,
    required this.label,
    this.size = 24,
    this.dimmed = false,
  });
  final bool active;
  final String label;
  final double size;
  final bool dimmed;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color border = dimmed ? Colors.black26 : theme.colorScheme.onSurface;
    final Color fill = active ? Colors.black : Colors.white;
    final Color text = active
        ? Colors.white
        : (dimmed ? Colors.black38 : Colors.black);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: size == 24 ? 12 : 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _TopicDetailPage extends StatelessWidget {
  const _TopicDetailPage({required this.topic, required this.classCode});
  final ClassTopic topic;
  final String classCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = context.watch<DataService>();
    final posts = data.posts
        .where((p) => p.tags.contains(topic.topicTag))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(topic.topicTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '${topic.courseName} • Tutor ${topic.tutorName}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          for (final p in posts) ...[
            _ClassMessageTile(
              message: _ClassMessage(
                id: p.id,
                author: p.author,
                handle: p.handle,
                timeAgo: p.timeAgo,
                body: p.body,
                likes: p.likes,
                replies: p.replies,
                heartbreaks: 0,
              ),
              onShare: () async {},
            ),
            const SizedBox(height: 8),
          ],
          if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No notes found for this topic',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClassComposer extends StatefulWidget {
  const _ClassComposer({
    required this.controller,
    required this.onSend,
    required this.hintText,
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final FocusNode? focusNode;

  @override
  State<_ClassComposer> createState() => _ClassComposerState();
}

class _ClassComposerState extends State<_ClassComposer> {
  final ImagePicker _picker = ImagePicker();
  final List<_Attachment> _attachments = <_Attachment>[];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant _ClassComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _openEmojiPicker() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: EmojiPicker(
              onEmojiSelected: (Category? category, Emoji emoji) {
                _insertEmoji(emoji.emoji);
                Navigator.of(ctx).pop();
              },
              config: Config(
                height: 320,
                // Avoid platform channel call for getSupportedEmojis on
                // platforms where the plugin is not registered.
                checkPlatformCompatibility: false,
                // Order: search bar on top, emoji grid in middle,
                // category bar at the very bottom like WhatsApp.
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.searchBar,
                  middle: EmojiPickerItem.emojiView,
                  bottom: EmojiPickerItem.categoryBar,
                ),
                emojiViewConfig: EmojiViewConfig(
                  columns: 8,
                  emojiSizeMax: 30,
                  backgroundColor: theme.colorScheme.surface,
                  verticalSpacing: 8,
                  horizontalSpacing: 8,
                  gridPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  buttonMode: ButtonMode.CUPERTINO,
                ),
                // Start on RECENT so frequently used emojis are shown first,
                // then users can scroll through other categories.
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.SMILEYS,
                  recentTabBehavior: RecentTabBehavior.RECENT,
                  backgroundColor: theme.colorScheme.surface,
                  iconColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.45,
                  ),
                  iconColorSelected: theme.colorScheme.primary,
                  indicatorColor: theme.colorScheme.primary,
                  backspaceColor: theme.colorScheme.primary,
                  dividerColor: theme.dividerColor.withValues(alpha: 0.2),
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  enabled: false,
                  backgroundColor: theme.colorScheme.surface,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.98,
                  ),
                  buttonIconColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                  hintText: 'Search emoji',
                  hintTextStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  inputTextStyle: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _handleAttachImage() async {
    // Prefer multi-image selection if available
    final List<XFile> files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (files.isEmpty) return;
    final List<_Attachment> items = [];
    for (final f in files) {
      final bytes = await f.readAsBytes();
      items.add(_Attachment(bytes: bytes, name: f.name, mimeType: 'image/*'));
    }
    setState(() => _attachments.addAll(items));
  }

  Future<void> _handleAttachFile() async {
    // Fallback path that doesn't require `file_picker` package.
    // Inform the user how to enable real file picking.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'File attach requires the file_picker package. Run "flutter pub add file_picker" and restart.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openAttachMenu() async {
    final theme = Theme.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo or video'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: const Text('File'),
              onTap: () => Navigator.of(ctx).pop('file'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'gallery') {
      await _handleAttachImage();
    } else if (choice == 'file') {
      await _handleAttachFile();
    }
  }

  void _removeAttachmentAt(int index) {
    setState(() => _attachments.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.55);
    // Show the camera shortcut only when there's no text yet.
    final bool showCamera = widget.controller.text.trim().isEmpty;

    final input = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: 3,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.newline,
      cursorColor: Colors.black,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: Colors.black,
        fontSize: 16,
        height: 1.35,
        letterSpacing: 0.1,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: subtle,
          fontSize: 13,
          height: 1.25,
          letterSpacing: 0.1,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        prefixIcon: IconButton(
          tooltip: 'Emoji',
          onPressed: _openEmojiPicker,
          icon: Icon(Icons.emoji_emotions_outlined, color: subtle, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          visualDensity: VisualDensity.compact,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Attach',
              onPressed: _openAttachMenu,
              icon: Icon(Icons.attach_file_rounded, color: subtle, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              visualDensity: VisualDensity.compact,
            ),
            if (showCamera)
              IconButton(
                tooltip: 'Camera',
                onPressed: _handleAttachImage,
                icon: Icon(
                  Icons.photo_camera_outlined,
                  color: subtle,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        // Grey rounded corners
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.25 : 0.18,
            ),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.25 : 0.18,
            ),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.35 : 0.28,
            ),
            width: 1.3,
          ),
        ),
      ),
      onSubmitted: (_) => widget.onSend(),
    );

    // Standalone pill send button to the right of the input.
    final Widget sendButton = SizedBox(
      height: 48,
      width: 48,
      child: Material(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            widget.onSend();
            if (_attachments.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sent with ${_attachments.length} attachment${_attachments.length == 1 ? '' : 's'}',
                  ),
                ),
              );
              setState(() => _attachments.clear());
            }
          },
          child: const Center(
            child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );

    // Keep the composer at a comfortable, slightly larger height.
    final compactInput = SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: input),
          const SizedBox(width: 4),
          sendButton,
        ],
      ),
    );

    if (_attachments.isEmpty) return compactInput;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) {
              final a = _attachments[i];
              Widget preview;
              if (a.isImage) {
                preview = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    a.bytes,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                final ext = (a.name ?? '').split('.').last.toUpperCase();
                preview = Container(
                  width: 120,
                  height: 76,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.name ?? 'File',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ext.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            ext,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return Stack(
                children: [
                  preview,
                  Positioned(
                    right: 4,
                    top: 4,
                    child: InkWell(
                      onTap: () => _removeAttachmentAt(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _attachments.length,
          ),
        ),
        const SizedBox(height: 8),
        compactInput,
      ],
    );
  }
}

class _ClassMessageTile extends StatefulWidget {
  const _ClassMessageTile({
    required this.message,
    required this.onShare,
    this.showReplyButton = true,
    this.onRepost, // when provided, triggers a real repost action
    this.repostEnabled = true,
  });

  final _ClassMessage message;
  final Future<void> Function() onShare;
  final Future<bool> Function()? onRepost; // returns new repost state (active?)
  final bool repostEnabled;
  final bool showReplyButton;

  @override
  State<_ClassMessageTile> createState() => _ClassMessageTileState();
}

class _ClassMessageTileState extends State<_ClassMessageTile> {
  bool _expanded = false;
  bool _saved = false;
  int _good = 0;
  int _bad = 0;
  int _reposts = 0;
  bool _goodActive = false;
  bool _badActive = false;

  String _formatDisplayName(String author, String handle) {
    String base = (author.trim().isNotEmpty ? author : handle).trim();
    // Strip leading @ if present
    base = base.replaceFirst(RegExp(r'^\s*@'), '');
    // Replace underscores/hyphens with spaces
    base = base.replaceAll(RegExp(r'[_-]+'), ' ');
    // Insert spaces in camelCase or PascalCase (e.g., StudyCouncil -> Study Council)
    base = base.replaceAllMapped(
      RegExp(r'(?<=[a-z])([A-Z])'),
      (m) => ' ${m.group(1)}',
    );
    // Title-case words
    final parts = base.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final titled = parts
        .map(
          (w) => w.substring(0, 1).toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');
    return titled.isEmpty ? base : titled;
  }

  @override
  void initState() {
    super.initState();
    _good = widget.message.likes;
    _bad = widget.message.heartbreaks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color nameColor = theme.colorScheme.onSurface;
    final Color meta = nameColor.withValues(alpha: 0.6);

    final message = widget.message;

    String avatarText() {
      final base = message.author.isNotEmpty ? message.author : message.handle;
      final t = base.trim();
      if (t.isEmpty) return '?';
      final first = t.substring(0, 1);
      return first.toUpperCase();
    }

    // Card container for note – reuse the same cut-in avatar + rounded border
    // treatment as the Replies cards.
    final Color cardBackground = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFFAFAFA);
    final Color borderColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.30 : 0.14,
    );

    /*return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 24, bottom: 16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: _formatDisplayName(message.author, message.handle),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: nameColor,
                          ),
                          children: [
                            TextSpan(
                              text: ' • ${message.timeAgo}',
                              style: theme.textTheme.bodySmall?.copyWith(color: meta),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      color: meta,
                      onPressed: () {},
                      tooltip: 'More',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
          const SizedBox(height: 6),
          // Body now uses full width (no left indent under avatar)
          LayoutBuilder(builder: (context, constraints) {
            // Determine if text exceeds 22 lines (truncate threshold)
            final textStyle = theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.0,
            );
            final span = TextSpan(text: message.body, style: textStyle);
            final tp = TextPainter(
              text: span,
              maxLines: null,
              textDirection: Directionality.of(context),
            );
            tp.layout(maxWidth: constraints.maxWidth);
            final int totalLines = tp.computeLineMetrics().length;
            final bool longLines = totalLines > 22; // Collapse if more than 22 lines

            if (!_expanded && longLines) {
              final linkStyle = theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              );
              int low = 0, high = message.body.length, best = 0;
              while (low <= high) {
                final mid = (low + high) >> 1;
                final prefix = '${message.body.substring(0, mid).trimRight()} ';
                final spanTry = TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(text: prefix),
                    TextSpan(text: 'Read more', style: linkStyle),
                  ],
                );
                final tpTry = TextPainter(
                  text: spanTry,
                  maxLines: 22,
                  textDirection: Directionality.of(context),
                )..layout(maxWidth: constraints.maxWidth);
                if (!tpTry.didExceedMaxLines) {
                  best = mid;
                  low = mid + 1;
                } else {
                  high = mid - 1;
                }
              }
              final visible = message.body.substring(0, best).trimRight();
              // Reserve extra room by removing the last 3 words so the link
              // reliably sits on the same final line and not below.
              String visibleTrimmed = visible;
              final words = visibleTrimmed.split(RegExp(r"\s+"));
              if (words.length > 3) {
                visibleTrimmed = words.sublist(0, words.length - 3).join(' ');
              }
              return Text.rich(
                TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(text: '$visibleTrimmed '),
                    TextSpan(
                      text: 'Read more',
                      style: linkStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => setState(() => _expanded = true),
                    ),
                  ],
                ),
                maxLines: 22,
                overflow: TextOverflow.clip,
              );
            }

            return Text(message.body, style: textStyle);
          }),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Always show the View replies pill when enabled, even at 0
              if (widget.showReplyButton)
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _openComments(context, message),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            // Use neutral grey instead of accent/primary
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'View ${message.replies} ${message.replies == 1 ? 'reply' : 'replies'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              // Keep neutral text to match grey outline
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(width: 8),
              // Three equal columns: Like, Repost, Heartbreak
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _LabelCountButton(
                          icon: _goodActive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconSize: 20,
                          count: _good,
                          color: _goodActive ? Colors.red : null,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_goodActive) {
                                _good = (_good - 1).clamp(0, 1 << 30);
                                _goodActive = false;
                              } else {
                                _good += 1;
                                _goodActive = true;
                                if (_badActive) {
                                  _bad = (_bad - 1).clamp(0, 1 << 30);
                                  _badActive = false;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: widget.repostEnabled
                            ? _ScaleTap(
                                onTap: () async {
                                  if (widget.onRepost != null) {
                                    final bool next = await widget.onRepost!.call();
                                    setState(() {
                                      if (_saved != next) {
                                        _reposts += next ? 1 : -1;
                                        if (_reposts < 0) _reposts = 0;
                                      }
                                      _saved = next;
                                    });
                                  } else {
                                    setState(() {
                                      _saved = !_saved;
                                      _reposts += _saved ? 1 : -1;
                                      if (_reposts < 0) _reposts = 0;
                                    });
                                  }
                                },
                                child: LayoutBuilder(
                                  builder: (context, c) {
                                    final maxW = c.maxWidth;
                                    final bool tight = maxW.isFinite && maxW < 60;
                                    final bool ultra = maxW.isFinite && maxW < 38;
                                    final String label = ultra ? 'R' : (tight ? 'Rep' : 'Repost');
                                    final double gap = ultra ? 2 : (tight ? 4 : 6);
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          label,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: _saved ? Colors.green : meta,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: gap),
                                        Text(
                                          '$_reposts',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: _saved ? Colors.green : meta,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : LayoutBuilder(
                            builder: (context, c) {
                              final maxW = c.maxWidth;
                              final bool tight = maxW.isFinite && maxW < 60;
                              final bool ultra = maxW.isFinite && maxW < 38;
                              final String label = ultra ? 'R' : (tight ? 'Rep' : 'Repost');
                              final double gap = ultra ? 2 : (tight ? 4 : 6);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: meta,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Text(
                                    '$_reposts',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: meta,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _LabelCountButton(
                          icon: _badActive ? Icons.heart_broken_rounded : Icons.heart_broken_outlined,
                          iconSize: 18,
                          count: _bad,
                          color: _badActive ? Colors.black : null,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_badActive) {
                                _bad = (_bad - 1).clamp(0, 1 << 30);
                                _badActive = false;
                              } else {
                                _bad += 1;
                                _badActive = true;
                                if (_goodActive) {
                                  _good = (_good - 1).clamp(0, 1 << 30);
                                  _goodActive = false;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Picture-frame avatar overlapping the left edge of the card.
        Positioned(
          left: 0,
          top: 16,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1EC),
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );*/

    final Widget card = Container(
      margin: const EdgeInsets.only(left: 24, bottom: 16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: _formatDisplayName(message.author, message.handle),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                      ),
                      children: [
                        TextSpan(
                          text: ' • ${message.timeAgo}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: meta,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: meta,
                  onPressed: () {},
                  tooltip: 'More',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.showReplyButton)
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _openComments(context, message),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Text(
                              'View ${message.replies} ${message.replies == 1 ? 'reply' : 'replies'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: _LabelCountButton(
                            icon: _goodActive
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            iconSize: 20,
                            count: _good,
                            color: _goodActive ? Colors.red : null,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (_goodActive) {
                                  _good = (_good - 1).clamp(0, 1 << 30);
                                  _goodActive = false;
                                } else {
                                  _good += 1;
                                  _goodActive = true;
                                  if (_badActive) {
                                    _bad = (_bad - 1).clamp(0, 1 << 30);
                                    _badActive = false;
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: widget.repostEnabled
                              ? _ScaleTap(
                                  onTap: () async {
                                    if (widget.onRepost != null) {
                                      final bool next = await widget.onRepost!
                                          .call();
                                      setState(() {
                                        if (_saved != next) {
                                          _reposts += next ? 1 : -1;
                                          if (_reposts < 0) _reposts = 0;
                                        }
                                        _saved = next;
                                      });
                                    } else {
                                      setState(() {
                                        _saved = !_saved;
                                        _reposts += _saved ? 1 : -1;
                                        if (_reposts < 0) _reposts = 0;
                                      });
                                    }
                                  },
                                  child: LayoutBuilder(
                                    builder: (context, c) {
                                      final maxW = c.maxWidth;
                                      final bool tight =
                                          maxW.isFinite && maxW < 60;
                                      final bool ultra =
                                          maxW.isFinite && maxW < 38;
                                      final String label = ultra
                                          ? 'R'
                                          : (tight ? 'Rep' : 'Repost');
                                      final double gap = ultra
                                          ? 2
                                          : (tight ? 4 : 6);
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            label,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: _saved
                                                      ? Colors.green
                                                      : meta,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          SizedBox(width: gap),
                                          Text(
                                            '$_reposts',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color: _saved
                                                      ? Colors.green
                                                      : meta,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, c) {
                                    final maxW = c.maxWidth;
                                    final bool tight =
                                        maxW.isFinite && maxW < 60;
                                    final bool ultra =
                                        maxW.isFinite && maxW < 38;
                                    final String label = ultra
                                        ? 'R'
                                        : (tight ? 'Rep' : 'Repost');
                                    final double gap = ultra
                                        ? 2
                                        : (tight ? 4 : 6);
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          label,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: meta,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        SizedBox(width: gap),
                                        Text(
                                          '$_reposts',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: meta,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _LabelCountButton(
                            icon: _badActive
                                ? Icons.heart_broken_rounded
                                : Icons.heart_broken_outlined,
                            iconSize: 18,
                            count: _bad,
                            color: _badActive ? Colors.black : null,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (_badActive) {
                                  _bad = (_bad - 1).clamp(0, 1 << 30);
                                  _badActive = false;
                                } else {
                                  _bad += 1;
                                  _badActive = true;
                                  if (_goodActive) {
                                    _good = (_good - 1).clamp(0, 1 << 30);
                                    _goodActive = false;
                                  }
                                }
                              });
                            },
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
      ),
    );

    // Picture-frame avatar overlapping the left edge of the card.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: 0,
          top: 16,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1EC),
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openComments(BuildContext context, _ClassMessage message) {
    String me = '@yourprofile';
    final email = SimpleAuthService().currentUserEmail;
    if (email != null && email.isNotEmpty) {
      final normalized = email
          .split('@')
          .first
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
          .toLowerCase();
      if (normalized.isNotEmpty) me = '@$normalized';
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _MessageCommentsPage(message: message, currentUserHandle: me),
      ),
    );
  }
}







