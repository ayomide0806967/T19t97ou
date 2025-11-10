import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'quiz_hub_screen.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../widgets/hexagon_avatar.dart';
// Removed unused tweet widgets imports

/// Public helper to open the "Replies" UI (classes/messages style)
/// for a given timeline post. This keeps the private types local to this
/// file while exposing a simple route factory for other screens.
Route<void> messageRepliesRouteFromPost({
  required PostModel post,
  required String currentUserHandle,
}) {
  final _ClassMessage msg = _ClassMessage(
    id: post.id,
    author: post.author,
    handle: post.handle,
    timeAgo: post.timeAgo,
    body: post.body,
    likes: post.likes,
    replies: post.replies,
    heartbreaks: 0,
  );
  return MaterialPageRoute<void>(
    builder: (_) => _MessageCommentsPage(
      message: msg,
      currentUserHandle: currentUserHandle,
    ),
  );
}

/// Minimalist iOS-style messages inbox page.
class IosMinimalistMessagePage extends StatefulWidget {
  const IosMinimalistMessagePage({super.key});

  @override
  State<IosMinimalistMessagePage> createState() =>
      _IosMinimalistMessagePageState();
}

class _IosMinimalistMessagePageState extends State<IosMinimalistMessagePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background = Colors.white;
    final List<_Conversation> filtered = _filteredConversations();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _MessagesHeader(theme: theme),
              const SizedBox(height: 8),
              const _SchoolTabBar(),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _MessagesList(conversations: filtered),
                    const _ClassesExperience(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_Conversation> _filteredConversations() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _demoConversations;
    return _demoConversations
        .where(
          (conversation) =>
              conversation.name.toLowerCase().contains(query) ||
              conversation.lastMessage.toLowerCase().contains(query),
        )
        .toList();
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _HeaderIcon(
            icon: Icons.quiz_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuizHubScreen()),
              );
            },
            color: iconColor.withValues(alpha: 0.85),
          ),
          const Spacer(),
          Text(
            'Messages',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: iconColor,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          _HeaderIcon(
            icon: CupertinoIcons.add,
            onTap: () {},
            color: iconColor.withValues(alpha: 0.85),
          ),
      ],
    ),
  );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Icon(icon, size: 24, color: color),
    );
  }
}

class _SchoolTabBar extends StatelessWidget {
  const _SchoolTabBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color label = theme.colorScheme.onSurface;
    final Color indicator = theme.colorScheme.primary;
    final Color unselected = label.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        isScrollable: false,
        labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelColor: label,
        unselectedLabelColor: unselected,
        indicatorColor: indicator,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Inbox'),
          Tab(text: 'Classes'),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({required this.conversations});

  final List<_Conversation> conversations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _ConversationTile(conversation: conversation);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemCount: conversations.length,
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final _Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color nameColor = const Color(0xFF1C274C);
    final Color messageColor = const Color(0xFF64748B);

    return Material(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConversationAvatar(initials: conversation.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: nameColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          conversation.timeLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: messageColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: messageColor,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: conversation.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFCFD8FF), Color(0xFFE7EAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF1C274C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4A5CFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Conversation {
  const _Conversation({
    required this.name,
    required this.initials,
    required this.lastMessage,
    required this.timeLabel,
    this.unreadCount = 0,
  });

  final String name;
  final String initials;
  final String lastMessage;
  final String timeLabel;
  final int unreadCount;
}

class _ClassesExperience extends StatelessWidget {
  const _ClassesExperience();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        _CreateClassTile(onCreate: () {}),
        const SizedBox(height: 12),
        Text(
          'Your classes',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final college in _demoColleges) ...[
          _CollegeCard(college: college),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CreateClassTile extends StatelessWidget {
  const _CreateClassTile({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0E0F12) : Colors.white;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.2);
    final Color subtitle = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onCreate,
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.group_add_outlined, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a class group',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Invite members, share tweets, and attach PDF resources.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: subtitle),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollegeCard extends StatelessWidget {
  const _CollegeCard({required this.college});

  final College college;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0E0F12) : Colors.white;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.2);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _CollegeScreen(college: college)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        
child: Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            college.name,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            college.facilitator,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(CupertinoIcons.person_2, size: 16, color: Color(0xFF475569)),
              const SizedBox(width: 6),
              Text(
                '\${college.members} students',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    ),
    const Icon(Icons.chevron_right, size: 28),
  ],
),
      ),
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
          Icon(Icons.picture_as_pdf, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
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

class College {
  const College({
    required this.name,
    required this.code,
    required this.facilitator,
    required this.members,
    required this.deliveryMode,
    required this.upcomingExam,
    required this.resources,
    required this.memberHandles,
    this.lectureNotes = const <LectureNote>[],
  });

  final String name;
  final String code;
  final String facilitator;
  final int members;
  final String deliveryMode;
  final String upcomingExam;
  final List<CollegeResource> resources;
  final Set<String> memberHandles;
  final List<LectureNote> lectureNotes;
}

class CollegeResource {
  const CollegeResource({
    required this.title,
    required this.fileType,
    required this.size,
  });

  final String title;
  final String fileType;
  final String size;
}

class LectureNote {
  const LectureNote({
    required this.title,
    this.subtitle,
    this.size,
  });

  final String title;
  final String? subtitle; // e.g., Week 3, Chapter, or brief description
  final String? size; // e.g., 540 KB
}

// Removed unused _TweetMessage model


const List<_Conversation> _demoConversations = <_Conversation>[
  _Conversation(
    name: 'Hannah Nguyen',
    initials: 'HN',
    lastMessage: 'Sending now. Also, meeting moved to 10:30.',
    timeLabel: '09:22',
  ),
  _Conversation(
    name: 'Nursing Study Group',
    initials: 'NS',
    lastMessage: 'Practice test starts at 4pm today.',
    timeLabel: 'Sun',
    unreadCount: 5,
  ),
  _Conversation(
    name: 'Wale Adebayo',
    initials: 'WA',
    lastMessage: 'On my way 🚍',
    timeLabel: '08:55',
    unreadCount: 2,
  ),
  _Conversation(
    name: 'Hadiza Umar',
    initials: 'HU',
    lastMessage: 'I shared the doc.',
    timeLabel: 'Yesterday',
  ),
  _Conversation(
    name: 'Sam Obi',
    initials: 'SO',
    lastMessage: 'Lol true 😂',
    timeLabel: 'Sat',
  ),
  _Conversation(
    name: 'Maria Idowu',
    initials: 'MI',
    lastMessage: 'Voice note (0:23)',
    timeLabel: 'Fri',
    unreadCount: 1,
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
      CollegeResource(title: 'Gene Expression Slides', fileType: 'pdf', size: '3.2 MB'),
      CollegeResource(title: 'CRISPR Lab Manual', fileType: 'pdf', size: '1.1 MB'),
      CollegeResource(title: 'Exam Blueprint', fileType: 'pdf', size: '820 KB'),
    ],
    memberHandles: <String>{
      '@year3_shift', '@osce_ready', '@skillslab'
    },
    lectureNotes: <LectureNote>[
      LectureNote(title: 'Mendelian inheritance overview', subtitle: 'Week 1 notes', size: '6 pages'),
      LectureNote(title: 'Gene regulation basics', subtitle: 'Week 2 notes', size: '9 pages'),
      LectureNote(title: 'CRISPR: principles + ethics', subtitle: 'Seminar handout', size: '4 pages'),
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
      CollegeResource(title: 'Policy Case Studies', fileType: 'pdf', size: '2.5 MB'),
      CollegeResource(title: 'Past Questions', fileType: 'pdf', size: '4.1 MB'),
    ],
    memberHandles: <String>{
      '@coach_amaka', '@community_rounds'
    },
    lectureNotes: <LectureNote>[
      LectureNote(title: 'Arms of government', subtitle: 'Introductory lecture', size: '8 pages'),
      LectureNote(title: 'Policy lifecycle', subtitle: 'Framework + examples', size: '5 pages'),
    ],
  ),
];

// Quiz screens exist separately; access via header quiz icon.

class _CollegeScreen extends StatefulWidget {
  const _CollegeScreen({required this.college});

  final College college;

  @override
  State<_CollegeScreen> createState() => _CollegeScreenState();
}

class _CollegeScreenState extends State<_CollegeScreen> {
  final TextEditingController _composer = TextEditingController();
  late Set<String> _members;
  final List<_ClassMessage> _notes = <_ClassMessage>[];

  @override
  void initState() {
    super.initState();
    _members = Set<String>.from(widget.college.memberHandles);
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
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  String get _currentUserHandle {
    final email = SimpleAuthService().currentUserEmail;
    if (email == null || email.isEmpty) return '@yourprofile';
    final normalized = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
    if (normalized.isEmpty) return '@yourprofile';
    return '@$normalized';
  }

  @override
  Widget build(BuildContext context) {
    final college = widget.college;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(college.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Class'),
              Tab(text: 'Library'),
              Tab(text: 'Students'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            _ClassFeedTab(
              college: college,
              notes: _notes,
              onSend: (text) {
                final id = 'note_${DateTime.now().microsecondsSinceEpoch}';
                setState(() {
                  _notes.insert(
                    0,
                  _ClassMessage(
                    id: id,
                    author: 'You',
                    handle: _currentUserHandle,
                    timeAgo: 'just now',
                    body: text,
                    likes: 0,
                    replies: 0,
                    heartbreaks: 0,
                  ),
                );
              });
            },
              onShare: (msg) async {
                final truncated = msg.body.length > 280
                    ? msg.body.substring(0, 280)
                    : msg.body;
                await context.read<DataService>().addPost(
                      author: msg.author,
                      handle: _currentUserHandle,
                      body: '$truncated  #${college.code}',
                      tags: <String>[college.code],
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shared to your page')),
                );
              },
            ),
            _ClassLibraryTab(college: college),
            _ClassStudentsTab(members: _members, onAdd: _addMember, onExit: _exitClass),
          ],
        ),
      ),
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
          decoration: const InputDecoration(hintText: '@handle'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              String h = controller.text.trim();
              if (h.isEmpty) return;
              if (!h.startsWith('@')) h = '@$h';
              setState(() => _members.add(h));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $h')),
              );
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exited class')),
              );
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _ClassFeedTab extends StatelessWidget {
  const _ClassFeedTab({
    required this.college,
    required this.notes,
    required this.onSend,
    required this.onShare,
  });

  final College college;
  final List<_ClassMessage> notes;
  final ValueChanged<String> onSend;
  final Future<void> Function(_ClassMessage message) onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextEditingController textController = TextEditingController();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              _ClassTopInfo(college: college),
              const SizedBox(height: 16),
              if (notes.isEmpty)
                Center(
                  child: Text(
                    'No messages yet. Be the first to post!',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ...[
                  for (final msg in notes)
                    _ClassMessageTile(
                      message: msg,
                      onShare: () => onShare(msg),
                    ),
                ],
              const SizedBox(height: 4),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _ClassComposer(
            controller: textController,
            hintText: 'Write a note to ${college.code}…',
            onSend: () {
              final text = textController.text.trim();
              if (text.isEmpty) return;
              onSend(text);
              textController.clear();
            },
          ),
        ),
      ],
    );
  }
}

class _ClassComposer extends StatelessWidget {
  const _ClassComposer({
    required this.controller,
    required this.onSend,
    required this.hintText,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.22);

    // A compact, modern input with the send action built-in as a suffix icon.
    return TextField(
      controller: controller,
      maxLines: null,
      minLines: 1,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: theme.colorScheme.surface,
        suffixIcon: IconButton(
          tooltip: 'Send',
          onPressed: onSend,
          icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.55), width: 1.2),
        ),
      ),
      onSubmitted: (_) => onSend(),
    );
  }
}

class _ClassMessageTile extends StatefulWidget {
  const _ClassMessageTile({
    required this.message,
    required this.onShare,
    this.showReplyButton = true,
  });

  final _ClassMessage message;
  final Future<void> Function() onShare;
  final bool showReplyButton;

  @override
  State<_ClassMessageTile> createState() => _ClassMessageTileState();
}

class _ClassMessageTileState extends State<_ClassMessageTile> {
  bool _expanded = false;
  bool _saved = false;
  int _good = 0;
  int _bad = 0;
  bool _goodActive = false;
  bool _badActive = false;

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

    // Card container for note
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.25)
                    : theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  avatarText(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: message.handle,
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
              final linkStyle = theme.textTheme.bodyMedium?.copyWith(color: Colors.cyan);
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
              if (widget.showReplyButton && message.replies > 0)
                TextButton(
                  onPressed: () => _openComments(context, message),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.primary),
                    ),
                    child: Text(
                      'View ${message.replies} ${
                        message.replies == 1 ? 'reply' : 'replies'
                      }',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      _LabelCountButton(
                        label: 'Good',
                        count: _good,
                        color: _goodActive ? Colors.green : null,
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
                      _LabelCountButton(
                        label: 'Bad',
                        count: _bad,
                        color: _badActive ? Colors.red : null,
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
                _ScaleTap(
                  onTap: () => setState(() => _saved = !_saved),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'repost',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: meta,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      MaterialPageRoute(builder: (_) => _MessageCommentsPage(message: message, currentUserHandle: me)),
    );
  }
}

class _LabelCountButton extends StatefulWidget {
  const _LabelCountButton({
    required this.label,
    required this.count,
    required this.onPressed,
    this.color,
  });
  final String label;
  final int count;
  final VoidCallback onPressed;
  final Color? color;

  @override
  State<_LabelCountButton> createState() => _LabelCountButtonState();
}

class _LabelCountButtonState extends State<_LabelCountButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color meta = widget.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 1.08 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: meta,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.count}',
                  style: theme.textTheme.bodySmall?.copyWith(color: meta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  const _ScaleTap({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 1.08 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: widget.child,
        ),
      ),
    );
  }
}

// Repost now rendered as text label "repost"

class _MessageCommentsPage extends StatefulWidget {
  const _MessageCommentsPage({required this.message, required this.currentUserHandle});

  final _ClassMessage message;
  final String currentUserHandle;

  @override
  State<_MessageCommentsPage> createState() => _MessageCommentsPageState();
}

class _MessageCommentsPageState extends State<_MessageCommentsPage> {
  final TextEditingController _composer = TextEditingController();
  _ThreadNode? _replyTarget;
  late List<_ThreadNode> _threads;
  final Set<_ThreadNode> _selected = <_ThreadNode>{};

  @override
  void initState() {
    super.initState();
    _threads = <_ThreadNode>[
      _ThreadNode(
        comment: _ThreadComment(
          author: '@Naureen Ali',
          timeAgo: '14h',
          body: 'Use Google authenticator instead of recovery Gmail and no what\'s ths??',
          likes: 1,
        ),
        children: [
          _ThreadNode(
            comment: _ThreadComment(
              author: '@Athisham Nawaz',
              timeAgo: '14h',
              body: 'Google authenticator app ha',
            ),
            children: [
              _ThreadNode(
                comment: _ThreadComment(
                  author: '@Jan Mi',
                  timeAgo: '2h',
                  body: 'Naureen Ali Google auth app is more reliable.',
                ),
              ),
            ],
          ),
        ],
      ),
      _ThreadNode(
        comment: _ThreadComment(
          author: '@Mahan Rehman',
          timeAgo: '13h',
          body:
              'Meny koi alag content ya kuch be policies k against nae kia but my channel is also suspended and this is the notification i get what to do',
        ),
        children: [
          _ThreadNode(
            comment: _ThreadComment(
              author: 'Gilchrist Calunia · Follow',
              timeAgo: '9h',
              body: 'Mahan Rehman make an appeal',
            ),
          ),
          _ThreadNode(
            comment: _ThreadComment(
              author: '@Ata Ur Rehman',
              timeAgo: '9h',
              body: 'Niche kya hai bro?\nSee translation',
            ),
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  void _setReplyTarget(_ThreadNode node) {
    setState(() => _replyTarget = node);
  }

  void _sendReply() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;

    final _ThreadNode newNode = _ThreadNode(
      comment: _ThreadComment(
        author: 'You',
        timeAgo: 'now',
        body: text,
        quotedFrom: _replyTarget?.comment.author,
        quotedBody: _replyTarget?.comment.body,
      ),
    );

    bool appended = false;
    if (_replyTarget != null) {
      _replyTarget!.children.add(newNode);
      appended = true;
    }
    if (!appended) {
      _threads.add(newNode);
    }

    setState(() {
      _replyTarget = null;
      _composer.clear();
    });
  }

  void _toggleSelection(_ThreadNode node) {
    setState(() {
      if (_selected.contains(node)) {
        _selected.remove(node);
      } else {
        _selected.add(node);
      }
    });
  }

  void _clearSelection() {
    if (_selected.isEmpty) return;
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool selectionMode = _selected.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: selectionMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _clearSelection,
              )
            : null,
        title: selectionMode
            ? Text('${_selected.length}')
            : const Text('Replies'),
        actions: selectionMode
            ? [
                IconButton(
                  tooltip: 'Reply',
                  icon: const Icon(Icons.reply_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  tooltip: 'Info',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {},
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () {},
                ),
                IconButton(
                  tooltip: 'Forward',
                  icon: const Icon(Icons.redo_rounded),
                  onPressed: () {},
                ),
                IconButton(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                _ClassMessageTile(
                  message: widget.message,
                  onShare: () async {},
                  showReplyButton: false,
                ),
                const SizedBox(height: 12),
                _ThreadCommentsView(
                  nodes: _threads,
                  currentUserHandle: widget.currentUserHandle,
                  onReply: _setReplyTarget,
                  selectionMode: selectionMode,
                  selected: _selected,
                  onToggleSelect: _toggleSelection,
                ),
              ],
            ),
          ),
          if (_replyTarget != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Container(width: 3, height: 36, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_replyTarget!.comment.author, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            _replyTarget!.comment.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _replyTarget = null),
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _ClassComposer(
              controller: _composer,
              hintText: _replyTarget == null ? 'Write a reply…' : 'Replying to ${_replyTarget!.comment.author}',
              onSend: _sendReply,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadNode {
  _ThreadNode({required this.comment, List<_ThreadNode>? children})
      : children = children != null ? List<_ThreadNode>.from(children) : <_ThreadNode>[];
  final _ThreadComment comment;
  final List<_ThreadNode> children;
}

class _ThreadCommentsView extends StatelessWidget {
  const _ThreadCommentsView({
    required this.nodes,
    required this.currentUserHandle,
    this.onReply,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
  });
  final List<_ThreadNode> nodes;
  final String currentUserHandle;
  final ValueChanged<_ThreadNode>? onReply;
  final bool selectionMode;
  final Set<_ThreadNode> selected;
  final void Function(_ThreadNode node) onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < nodes.length; i++)
          _ThreadNodeTile(
            node: nodes[i],
            depth: 0,
            isLast: i == nodes.length - 1,
            currentUserHandle: currentUserHandle,
            onReply: onReply,
            selectionMode: selectionMode,
            selected: selected,
            onToggleSelect: () => onToggleSelect(nodes[i]),
          ),
      ],
    );
  }
}

class _ThreadNodeTile extends StatelessWidget {
  const _ThreadNodeTile({
    required this.node,
    required this.depth,
    required this.isLast,
    required this.currentUserHandle,
    this.onReply,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
  });
  final _ThreadNode node;
  final int depth;
  final bool isLast;
  final String currentUserHandle;
  final ValueChanged<_ThreadNode>? onReply;
  final bool selectionMode;
  final Set<_ThreadNode> selected;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final indent = 18.0 * depth;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentTile(
            comment: node.comment,
            isDark: isDark,
            currentUserHandle: currentUserHandle,
            onSwipeReply: selectionMode ? null : () => onReply?.call(node),
            selected: selected.contains(node),
            onLongPress: onToggleSelect,
            onTap: selectionMode ? onToggleSelect : null,
          ),
          if (node.children.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < node.children.length; i++)
                  _ThreadNodeTile(
                    node: node.children[i],
                    depth: depth + 1,
                    isLast: i == node.children.length - 1,
                    currentUserHandle: currentUserHandle,
                    onReply: onReply,
                    selectionMode: selectionMode,
                    selected: selected,
                    onToggleSelect: onToggleSelect,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// WhatsApp-style: no connector painter; indentation only

// Removed unused _ParentCommentTile widget

class _ThreadComment {
  const _ThreadComment({
    required this.author,
    required this.timeAgo,
    required this.body,
    this.likes = 0,
    this.quotedFrom,
    this.quotedBody,
  });
  final String author;
  final String timeAgo;
  final String body;
  final int likes;
  final String? quotedFrom;
  final String? quotedBody;
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.isDark,
    required this.currentUserHandle,
    this.onSwipeReply,
    this.selected = false,
    this.onLongPress,
    this.onTap,
  });
  final _ThreadComment comment;
  final bool isDark;
  final String currentUserHandle;
  final VoidCallback? onSwipeReply;
  final bool selected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _highlight = false;
  double _dx = 0;
  double _dragOffset = 0; // visual slide during swipe-to-reply
  int _likes = 0;
  int _dislikes = 0;
  bool _liked = false;
  bool _disliked = false;
  bool _reposted = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final _ThreadComment comment = widget.comment;
    final bool isMine =
        comment.author == widget.currentUserHandle || comment.author == 'You';
    // Light theme: mine = offwhite, others = very light cyan.
    // Dark theme: mine = subtle cyan tint, others = dark surface.
    final Color lightMineOffwhite = const Color(0xFFF8FAFC);
    final Color lightOtherVeryLightCyan = const Color(0xFFE0F7FA); // cyan 50
    final Color darkMine = theme.colorScheme.primary.withValues(alpha: 0.22);
    final Color darkOther = const Color(0xFF1F2226);
    final Color bubble = widget.isDark
        ? (isMine ? darkMine : darkOther)
        : (isMine ? lightMineOffwhite : lightOtherVeryLightCyan);

    // Meta text color uses default onSurface alpha in light theme
    final Color meta = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final bool isDark = widget.isDark;
    final Color cyan = theme.colorScheme.primary;
    final List<BoxShadow>? popShadow = [
      BoxShadow(
        color: isDark
            ? cyan.withValues(alpha: widget.selected ? 0.70 : 0.45)
            : cyan.withValues(alpha: widget.selected ? 0.45 : 0.25),
        blurRadius: widget.selected ? 30 : 18,
        spreadRadius: widget.selected ? 2 : 1,
        offset: widget.selected ? const Offset(0, 14) : const Offset(0, 6),
      ),
    ];

    final Widget bubbleCore = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubble,
          borderRadius: BorderRadius.circular(16),
          boxShadow: popShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    comment.author,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  comment.timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(color: meta),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (comment.quotedBody != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 3, height: 36, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.quotedFrom ?? 'Reply',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: meta,
                            ),
                          ),
                          Text(
                            comment.quotedBody!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              comment.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.isDark ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LabelCountButton(
                  label: 'Good',
                  count: _likes,
                  color: _liked ? Colors.green : null,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_liked) {
                        _likes = (_likes - 1).clamp(0, 1 << 30);
                        _liked = false;
                      } else {
                        _likes += 1;
                        _liked = true;
                        if (_disliked) {
                          _dislikes = (_dislikes - 1).clamp(0, 1 << 30);
                          _disliked = false;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(width: 16),
                _LabelCountButton(
                  label: 'Bad',
                  count: _dislikes,
                  color: _disliked ? Colors.red : null,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_disliked) {
                        _dislikes = (_dislikes - 1).clamp(0, 1 << 30);
                        _disliked = false;
                      } else {
                        _dislikes += 1;
                        _disliked = true;
                        if (_liked) {
                          _likes = (_likes - 1).clamp(0, 1 << 30);
                          _liked = false;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(width: 16),
                _ScaleTap(
                  onTap: () => setState(() => _reposted = !_reposted),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'repost',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: _reposted ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

    // Pop effect on selection
    final Widget poppedCard = AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      scale: widget.selected ? 1.06 : 1.02,
      child: bubbleCore,
    );

    // Prepare left-aligned avatar (fixed size), separate from content card
    final Widget avatar = HexagonAvatar(
      size: 40,
      borderWidth: 1.0,
      borderColor: theme.dividerColor,
      backgroundColor: theme.colorScheme.surface,
      child: Text(
        (comment.author.isNotEmpty ? comment.author.substring(0, 1) : 'U')
            .toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _highlight = true),
      onTapUp: (_) => setState(() => _highlight = false),
      onTapCancel: () => setState(() => _highlight = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onHorizontalDragUpdate: (details) {
        _dx += details.delta.dx;
        // visual slide to the right only
        final double next = (_dragOffset + details.delta.dx).clamp(0, 56);
        setState(() {
          _dragOffset = next;
          _highlight = true;
        });
        if (_dx > 42) {
          _dx = 0;
          widget.onSwipeReply?.call();
        }
      },
      onHorizontalDragEnd: (details) {
        final bool trigger =
            (details.primaryVelocity != null && details.primaryVelocity! > 250) ||
            _dragOffset >= 42;
        if (trigger) {
          widget.onSwipeReply?.call();
        }
        setState(() {
          _highlight = false;
          _dragOffset = 0; // animate back to rest
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(_dragOffset, 0, 0),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 4),
            Expanded(child: poppedCard),
          ],
        ),
      ),
    );
  }
}

class _ClassMessage {
  const _ClassMessage({
    required this.id,
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    this.likes = 0,
    this.replies = 0,
    this.heartbreaks = 0,
  });

  final String id;
  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final int likes;
  final int replies;
  final int heartbreaks;
}

class _ClassLibraryTab extends StatelessWidget {
  const _ClassLibraryTab({required this.college});
  final College college;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Library', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in college.resources)
              _LibraryChip(resource: r),
          ],
        ),
        const SizedBox(height: 20),
        Text('Lecture notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (college.lectureNotes.isEmpty)
          Text('No lecture notes yet', style: theme.textTheme.bodyMedium)
        else
          ...[
            for (final n in college.lectureNotes)
              _LectureNoteTile(note: n),
          ],
      ],
    );
  }
}

class _LectureNoteTile extends StatelessWidget {
  const _LectureNoteTile({required this.note});

  final LectureNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening "${note.title}"')),
          );
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
                child: Icon(Icons.article_outlined, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.subtitle != null || note.size != null)
                      Builder(builder: (context) {
                        final String meta = <String?>[note.subtitle, note.size]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(' • ');
                        return meta.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                meta,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                      }),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassStudentsTab extends StatelessWidget {
  const _ClassStudentsTab({
    required this.members,
    required this.onAdd,
    required this.onExit,
  });

  final Set<String> members;
  final Future<void> Function(BuildContext context) onAdd;
  final void Function(BuildContext context) onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = members.toList()..sort();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: () => onAdd(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add student'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => onExit(context),
              icon: const Icon(Icons.logout),
              label: const Text('Exit class'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Center(
            child: Text('No students listed yet', style: theme.textTheme.bodyMedium),
          )
        else
          ...[
            for (final h in list)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 8),
                    Expanded(child: Text(h, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
      ],
    );
  }
}

class _ClassTopInfo extends StatelessWidget {
  const _ClassTopInfo({required this.college});

  final College college;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0F1114) : Colors.white;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.18);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  college.code,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Text('${college.members} students', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            college.name,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
          const SizedBox(height: 4),
          Text(
            college.facilitator,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
// Removed unused _CollegeHeader widget
