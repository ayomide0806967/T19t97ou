import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'quiz_hub_screen.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../widgets/tweet_composer_card.dart';
import '../widgets/tweet_post_card.dart';

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
    // Close InkWell wrapper
    );
    );
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

class _ClassStatChip extends StatelessWidget {
  const _ClassStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF1F5F9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _TweetCard extends StatelessWidget {
  const _TweetCard({required this.tweet});

  final _TweetMessage tweet;

  String get _initials {
    final cleanedParts = tweet.author
        .trim()
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (cleanedParts.isEmpty) return '?';
    if (cleanedParts.length == 1) {
      return cleanedParts.first.substring(0, 1).toUpperCase();
    }
    final first = cleanedParts.first.substring(0, 1).toUpperCase();
    final last = cleanedParts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    _initials,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tweet.author,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${tweet.handle} • ${tweet.timeAgo}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (tweet.pinned)
                  Icon(CupertinoIcons.pin_fill, size: 16, color: theme.colorScheme.error),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tweet.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            if (tweet.hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in tweet.hashtags)
                    Text('#$tag', style: theme.textTheme.labelMedium),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _TweetStat(icon: CupertinoIcons.chat_bubble, value: tweet.replies),
                const SizedBox(width: 16),
                _TweetStat(icon: CupertinoIcons.heart, value: tweet.likes),
                const SizedBox(width: 16),
                _TweetStat(icon: CupertinoIcons.arrowshape_turn_up_right, value: tweet.shares),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TweetStat extends StatelessWidget {
  const _TweetStat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

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

class _TweetMessage {
  const _TweetMessage({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    this.hashtags = const <String>[],
    this.replies = 0,
    this.likes = 0,
    this.shares = 0,
    this.pinned = false,
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final List<String> hashtags;
  final int replies;
  final int likes;
  final int shares;
  final bool pinned;
}


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
                      body: truncated + '  #${college.code}',
                      tags: <String>[college.code],
                    );
                if (!mounted) return;
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
              if (!h.startsWith('@')) h = '@' + h;
              setState(() => _members.add(h));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ' + h)),
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
  });

  final _ClassMessage message;
  final Future<void> Function() onShare;

  @override
  State<_ClassMessageTile> createState() => _ClassMessageTileState();
}

class _ClassMessageTileState extends State<_ClassMessageTile> {
  bool _expanded = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color nameColor = theme.colorScheme.onSurface;
    final Color meta = nameColor.withValues(alpha: 0.6);

    final message = widget.message;

    String _avatarText() {
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
                  _avatarText(),
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
              color: Colors.black,
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
                final prefix = message.body.substring(0, mid).trimRight() + ' ';
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
                    TextSpan(text: visibleTrimmed + ' '),
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

            return Text(
              message.body,
              style: textStyle,
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              if (message.replies > 0)
                TextButton(
                  onPressed: () {},
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
                      'View ${message.replies} ' + (message.replies == 1 ? 'reply' : 'replies'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              _IconCountButton(
                icon: Icons.favorite_border,
                count: message.likes,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              _IconCountButton(
                icon: CupertinoIcons.hand_thumbsdown,
                count: message.heartbreaks,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _saved = !_saved),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Repost',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: meta,
                    fontWeight: _saved ? FontWeight.w700 : FontWeight.w500,
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _MessageCommentsSheet(message: message),
    );
  }
}

class _IconCountButton extends StatelessWidget {
  const _IconCountButton({required this.icon, required this.count, required this.onPressed});
  final IconData icon;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color meta = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(icon, size: 18, color: meta),
          ),
        ),
        const SizedBox(width: 4),
        Text('$count', style: theme.textTheme.bodySmall?.copyWith(color: meta)),
      ],
    );
  }
}

class _MessageCommentsSheet extends StatelessWidget {
  const _MessageCommentsSheet({required this.message});

  final _ClassMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<_ThreadComment> comments = <_ThreadComment>[
      _ThreadComment(
        author: '@chinedu',
        timeAgo: '3h',
        body: 'Thanks for the update! Will there be a formula sheet included or should we memorise the derivations?',
      ),
      _ThreadComment(
        author: '@amina',
        timeAgo: '1h',
        body: 'Please confirm if calculators with CAS are allowed. Also, can we staple extra working pages or will additional sheets be provided in the hall?',
      ),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Reuse the note container at the top
                  _ClassMessageTile(
                    message: message,
                    onShare: () async {},
                  ),
                  const SizedBox(height: 8),
                  Text('Comments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final c in comments)
                    _CommentTile(comment: c, isDark: isDark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThreadComment {
  const _ThreadComment({required this.author, required this.timeAgo, required this.body});
  final String author;
  final String timeAgo;
  final String body;
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.isDark});
  final _ThreadComment comment;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical descriptive line
            Container(
              width: 2.5,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(comment.author, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Text(comment.timeAgo, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment.body,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black, fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
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
class _CollegeHeader extends StatelessWidget {
  const _CollegeHeader({required this.college});
  final College college;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0E0F12) : Colors.white;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.2);
    return Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)), child: Text(college.code, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700))),
          const Spacer(),
          Text('${college.members} members', style: theme.textTheme.bodySmall),
        ]),
        const SizedBox(height: 10),
        Text(college.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(college.facilitator, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Text('Library', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in college.resources)
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.picture_as_pdf, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('${r.fileType.toUpperCase()} • ${r.size}', style: theme.textTheme.bodySmall),
              ]),
            ])),
        ]),
      ]),
    );
  }
}
