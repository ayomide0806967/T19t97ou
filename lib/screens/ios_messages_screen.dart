import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
// Note: file_picker is optional. We avoid importing it so the app builds even
// when the dependency hasn't been fetched. If you add file_picker to
// pubspec and run `flutter pub get`, you can re-enable file attachments by
// switching _handleAttachFile() to use FilePicker.
import 'quiz_hub_screen.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../widgets/tweet_post_card.dart';
import '../services/simple_auth_service.dart';
import '../widgets/hexagon_avatar.dart';
import '../services/roles_service.dart';
import '../services/members_service.dart';
import 'student_profile_screen.dart';
import '../widgets/equal_width_buttons_row.dart';
// Removed unused tweet widgets imports

// Lightweight attachment model used by the class composer
class _Attachment {
  _Attachment({required this.bytes, this.name, this.mimeType});
  final Uint8List bytes;
  final String? name;
  final String? mimeType;
  bool get isImage {
    final mt = (mimeType ?? '').toLowerCase();
    return mt.startsWith('image/');
  }
}

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
        _CreateClassTile(onCreate: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const _CreateClassPage()),
          );
          if (result is College) {
            // Open the newly created class immediately
            // Ignore persistence for now; this is a demo flow
            // and mirrors the seeded college behavior.
            // Members/admin role will be derived in the class screen.
            // Navigate to the class detail screen.
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _CollegeScreen(college: result)),
              );
            }
          }
        }),
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

class _CreateClassPage extends StatefulWidget {
  const _CreateClassPage({this.initialStep = 0});

  final int initialStep;

  @override
  State<_CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<_CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _facilitator = TextEditingController();
  final TextEditingController _description = TextEditingController();
  late int _step; // 0 = basics, 1 = settings
  bool _isPrivate = true;
  bool _adminOnlyPosting = true;
  bool _approvalRequired = false;
  bool _allowMedia = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _facilitator.dispose();
    _description.dispose();
    super.dispose();
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;
    final String name = _name.text.trim();
    final String codeRaw = _code.text.trim();
    final String code = codeRaw.isEmpty
        ? name.replaceAll(RegExp(r'\s+'), '').toUpperCase()
        : codeRaw.toUpperCase();
    final String facilitator =
        _facilitator.text.trim().isEmpty ? 'Admin' : _facilitator.text.trim();

    final College result = College(
      name: name,
      code: code,
      facilitator: facilitator,
      members: 1,
      deliveryMode: _isPrivate ? 'Private' : 'Open',
      upcomingExam: '',
      resources: const <CollegeResource>[],
      memberHandles: <String>{'@yourprofile'},
      lectureNotes: const <LectureNote>[],
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0F1114) : Colors.white;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.18);

    return Scaffold(
      appBar: AppBar(title: const Text('Create a class')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vertical step rail: 1 | 2
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 6),
                    child: _StepRailVertical(
                      steps: const ['1', '2'],
                      activeIndex: _step,
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 0 ? 'Basics' : 'Settings',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (_step == 0) ...[
                          TextFormField(
                            controller: _name,
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              labelText: 'Class name',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.6)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a class name' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _code,
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              labelText: 'Code (optional)',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.6)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _facilitator,
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              labelText: 'Facilitator / Admin (optional)',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.6)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _description,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.6)),
                            ),
                          ),
                        ] else ...[
                          _SwitchRow(label: 'Private class', value: _isPrivate, onChanged: (v) => setState(() => _isPrivate = v)),
                          _SwitchRow(label: 'Admin-only posting', value: _adminOnlyPosting, onChanged: (v) => setState(() => _adminOnlyPosting = v)),
                          _SwitchRow(label: 'Require approval for notes', value: _approvalRequired, onChanged: (v) => setState(() => _approvalRequired = v)),
                          _SwitchRow(label: 'Allow media attachments', value: _allowMedia, onChanged: (v) => setState(() => _allowMedia = v)),
                        ],
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Wrap buttons on small widths to avoid overflow, while
                            // keeping a consistent button height/width where space allows.
                            final BorderRadiusGeometry radius = BorderRadius.circular(12);
                            final ButtonStyle outlineStyle = OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              side: const BorderSide(color: Colors.black),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: radius),
                              visualDensity: VisualDensity.compact,
                            );
                            final ButtonStyle filledStyle = FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: radius),
                              visualDensity: VisualDensity.compact,
                            );

                            final List<Widget> btns = [
                              OutlinedButton(
                                style: outlineStyle,
                                onPressed: () => Navigator.of(context).pop(),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Cancel', maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              if (_step == 1)
                                OutlinedButton(
                                  style: outlineStyle,
                                  onPressed: () => setState(() => _step = 0),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Back', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              FilledButton(
                                style: filledStyle,
                                onPressed: () {
                                  if (_step == 0) {
                                    if (_formKey.currentState!.validate()) setState(() => _step = 1);
                                  } else {
                                    _create();
                                  }
                                },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(_step == 0 ? 'Next' : 'Create', maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ];
                            return EqualWidthButtonsRow(children: btns, gap: 8, height: 40);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            body: 'Mid‑sem schedule posted on the portal. Lab sessions moved to Week 6.',
            likes: 12,
            replies: 4,
            heartbreaks: 0,
          ),
          _ClassMessage(
            id: 'n2',
            author: '@TutorAnika',
            handle: '@tutor_anika',
            timeAgo: '2d ago',
            body: 'Cardio physiology slides added in Resources → Week 2. Read before lab.',
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
    final List<String> members = _members.toList()..sort((a, b) => a.compareTo(b));
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
                    Text('Manage admins', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
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
                                    const SnackBar(content: Text('At least one admin is required')),
                                  );
                                  return;
                                }
                                setState(() => _admins.remove(handle));
                              } else {
                                setState(() => _admins.add(handle));
                              }
                              await RolesService.saveAdminsFor(code, _admins);
                              if (isSelf && !_admins.contains(_currentUserHandle)) {
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
    final List<String> members = _members.toList()..sort((a, b) => a.compareTo(b));
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
                    Text('Suspend members', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
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
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                onPressed: isSelf
                                    ? null
                                    : () async {
                                        final ok = await showDialog<bool>(
                                              context: ctx,
                                              builder: (d) => AlertDialog(
                                                title: const Text('Remove member?'),
                                                content: Text('Remove $handle from this class?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('Cancel')),
                                                  FilledButton(onPressed: () => Navigator.of(d).pop(true), child: const Text('Remove')),
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
                                        await RolesService.saveAdminsFor(code, _admins);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Removed $handle')),
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
      final initial = <String>{...widget.college.memberHandles, _currentUserHandle};
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
          title: Text(college.name),
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
          bottom: TabBar(
            labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            labelColor: Colors.black,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            tabs: const [
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use Repost to share this note to the global timeline'),
                  ),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN')),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Suspended $h')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.8;
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
                  Row(
                    children: [
                      Text('Class settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SwitchRow(
                    label: 'Admin-only posting',
                    value: _adminOnlyPosting,
                    onChanged: (v) => setState(() => _adminOnlyPosting = v),
                  ),
                  _SwitchRow(
                    label: 'Allow replies',
                    value: _allowReplies,
                    onChanged: (v) => setState(() => _allowReplies = v),
                  ),
                  _SwitchRow(
                    label: 'Allow media attachments',
                    value: _allowMedia,
                    onChanged: (v) => setState(() => _allowMedia = v),
                  ),
                  _SwitchRow(
                    label: 'Private class',
                    value: _isPrivate,
                    onChanged: (v) => setState(() => _isPrivate = v),
                  ),
                  _SwitchRow(
                    label: 'Auto-archive when ending topic',
                    value: _autoArchiveOnEnd,
                    onChanged: (v) => setState(() => _autoArchiveOnEnd = v),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.tune),
                        label: const Text('Setting detail'),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const _CreateClassPage(initialStep: 1),
                            ),
                          );
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.group_outlined),
                        label: const Text('Manage admins'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openManageAdminsSheet(context);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Invite member'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _addMember(context);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_remove_alt_1_outlined),
                        label: const Text('Suspend members'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openSuspendMembersSheet(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmitLectureNote(BuildContext context, String body) async {
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
        const SnackBar(content: Text('Start a lecture above before adding notes')),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              String h = controller.text.trim();
              if (h.isEmpty) return;
              if (!h.startsWith('@')) h = '@$h';
              setState(() => _members.add(h));
              _persistMembers();
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

class _ClassFeedTab extends StatefulWidget {
  const _ClassFeedTab({
    required this.college,
    required this.notes,
    required this.onSend,
    required this.onShare,
    required this.onStartLecture,
    required this.onArchiveTopic,
    required this.isAdmin,
    required this.settings,
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
  final void Function(String course, String tutor, String topic, _TopicSettings settings) onStartLecture;
  final VoidCallback onArchiveTopic;
  final bool isAdmin;
  final _ClassSettings settings;
  final bool requiresPin;
  final String? pinCode;
  final bool unlocked;
  final bool Function(String attempt)? onUnlock;

  @override
  State<_ClassFeedTab> createState() => _ClassFeedTabState();
}

class _ClassFeedTabState extends State<_ClassFeedTab> {
  static const int _pageSize = 10;
  int _visibleNotes = 0;
  bool _loadingMoreNotes = false;

  @override
  void initState() {
    super.initState();
    _visibleNotes = widget.notes.isEmpty
        ? 0
        : (widget.notes.length < _pageSize ? widget.notes.length : _pageSize);
  }

  @override
  void didUpdateWidget(covariant _ClassFeedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes.length != widget.notes.length) {
      final int minNeeded = widget.notes.isEmpty ? 0 : _pageSize;
      _visibleNotes = _visibleNotes.clamp(minNeeded, widget.notes.length);
      if (_visibleNotes == 0 && widget.notes.isNotEmpty) {
        _visibleNotes = widget.notes.length < _pageSize ? widget.notes.length : _pageSize;
      }
    }
  }

  Future<void> _loadMoreNotes() async {
    if (_loadingMoreNotes) return;
    setState(() => _loadingMoreNotes = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final next = _visibleNotes + _pageSize;
    setState(() {
      _visibleNotes = next > widget.notes.length ? widget.notes.length : next;
      _loadingMoreNotes = false;
    });
  }

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
              _ClassTopInfo(college: widget.college, memberCount: _members.length),
              const SizedBox(height: 16),
              if (widget.activeTopic != null)
                _ActiveTopicCard(topic: widget.activeTopic!, onArchive: widget.onArchiveTopic)
              else if (widget.isAdmin)
                _StartLectureCard(onStart: (c, t, k, s) => widget.onStartLecture(c, t, k, s))
              else
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
              Text('Class discussion', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (widget.notes.isEmpty)
                Center(
                  child: Text(
                    'No messages yet. Be the first to post!',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else ...[
                for (final msg in widget.notes.take(_visibleNotes))
                  _ClassMessageTile(message: msg, onShare: () => widget.onShare(msg)),
                if (_visibleNotes < widget.notes.length) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 36,
                      child: OutlinedButton(
                        onPressed: _loadingMoreNotes ? null : _loadMoreNotes,
                        child: _loadingMoreNotes
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Load more'),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
        if (widget.isAdmin && widget.activeTopic != null) ...[
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _ClassComposer(
              controller: textController,
              hintText: 'Message',
              onSend: () {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                widget.onSend(text);
                textController.clear();
              },
            ),
          ),
        ]
        else ...[
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Lecture notes are shared by admins in real time.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveTopicCard extends StatelessWidget {
  const _ActiveTopicCard({required this.topic, required this.onArchive});
  final ClassTopic topic;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.2);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(topic.courseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const SizedBox(height: 10),
                Text(topic.topicTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tutor ${topic.tutorName}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text('Started ${_formatRelative(topic.createdAt)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Move to Library'),
          ),
        ],
      ),
    );
  }
}

class _StartLectureCard extends StatefulWidget {
  const _StartLectureCard({required this.onStart});
  final void Function(String course, String tutor, String topic, _TopicSettings settings) onStart;
  @override
  State<_StartLectureCard> createState() => _StartLectureCardState();
}

class _StartLectureCardState extends State<_StartLectureCard> {
  final _course = TextEditingController();
  final _tutor = TextEditingController();
  final _topic = TextEditingController();
  bool _expanded = true;
  int _step = 0;
  bool _privateLecture = false;
  bool _requirePin = false;
  final TextEditingController _pin = TextEditingController();
  DateTime? _autoArchiveAt;

  bool get _canStart =>
      _course.text.trim().isNotEmpty && _topic.text.trim().isNotEmpty;

  @override
  void dispose() {
    _course.dispose();
    _tutor.dispose();
    _topic.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0F1114) : Colors.white;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.18);
    final Color meta = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Start a lecture', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              _StepRailMini(activeIndex: _step, steps: const ['1', '2']),
              const Spacer(),
              IconButton(
                tooltip: _expanded ? 'Collapse' : 'Expand',
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            if (_step == 0) ...[
              TextField(
                controller: _course,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                cursorColor: Colors.black,
                decoration: const InputDecoration(labelText: 'Course name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tutor,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                cursorColor: Colors.black,
                decoration: const InputDecoration(labelText: 'Tutor name (optional)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _topic,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                cursorColor: Colors.black,
                decoration: const InputDecoration(labelText: 'Topic'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) { if (_canStart) setState(() => _step = 1); },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Create a lecture topic and start posting notes.',
                      style: theme.textTheme.bodySmall?.copyWith(color: meta),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    onPressed: _canStart ? () => setState(() => _step = 1) : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              _SwitchRow(
                label: 'Private lecture (disable repost)',
                value: _privateLecture,
                onChanged: (v) => setState(() => _privateLecture = v),
                monochrome: true,
              ),
              _SwitchRow(
                label: 'Require PIN to access',
                value: _requirePin,
                onChanged: (v) => setState(() => _requirePin = v),
                monochrome: true,
              ),
              if (_requirePin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TextField(
                    controller: _pin,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    cursorColor: Colors.black,
                    decoration: const InputDecoration(labelText: 'PIN code'),
                  ),
                ),
              const SizedBox(height: 6),
              // Auto-archive controls: label above, buttons below in one row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date/time', style: theme.textTheme.bodyMedium),
                  if (_autoArchiveAt != null) ...[
                    const SizedBox(height: 6),
                    Text(_autoArchiveAt!.toString(), style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                          onPressed: () async {
                            final now = DateTime.now();
                            final date = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: DateTime(now.year + 2),
                            );
                            if (date == null) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
                            );
                            if (time == null) return;
                            final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            setState(() => _autoArchiveAt = dt);
                          },
                          child: const Text('Date/time'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                          onPressed: () => setState(() => _autoArchiveAt = null),
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom action buttons aligned on one horizontal line
              EqualWidthButtonsRow(
                height: 40,
                gap: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () => setState(() => _step = 0),
                    child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Back', maxLines: 1)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: _canStart
                        ? () => widget.onStart(
                              _course.text.trim(),
                              _tutor.text.trim(),
                              _topic.text.trim(),
                              _TopicSettings(
                                privateLecture: _privateLecture,
                                requirePin: _requirePin,
                                pinCode: _requirePin ? _pin.text.trim() : null,
                                autoArchiveAt: _autoArchiveAt,
                              ),
                            )
                        : null,
                    child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Start', maxLines: 1)),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

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
    final posts = data.posts.where((p) => p.tags.contains(widget.topic.topicTag)).toList();
    final initial = posts.isEmpty ? 0 : (posts.length < _pageSize ? posts.length : _pageSize);
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
    final posts = data.posts.where((p) => p.tags.contains(widget.topic.topicTag)).toList();
    final next = _visible + _pageSize;
    setState(() {
      _visible = next > posts.length ? posts.length : next;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final posts = data.posts.where((p) => p.tags.contains(widget.topic.topicTag)).toList();
    if (posts.isEmpty) {
      return Text('No notes yet — your first note will appear here.');
    }
    final slice = posts.take(_visible == 0 ? posts.length : _visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Topic notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                    final toggled = await context.read<DataService>().toggleRepost(
                          postId: p.id,
                          userHandle: me,
                        );
                    if (!context.mounted) return toggled;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(toggled ? 'Reposted to your timeline' : 'Repost removed')),
                    );
                    return toggled;
                  },
          ),
          const SizedBox(height: 8),
        ],
        if ((_visible == 0 && posts.length > _pageSize) || (_visible > 0 && _visible < posts.length)) ...[
          Center(
            child: SizedBox(
              width: 200,
              height: 36,
              child: OutlinedButton(
                onPressed: _loading ? null : _loadMore,
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Load more notes'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ClassTopic {
  const ClassTopic({
    required this.courseName,
    required this.tutorName,
    required this.topicTitle,
    required this.createdAt,
    this.privateLecture = false,
    this.requirePin = false,
    this.pinCode,
    this.autoArchiveAt,
  });
  final String courseName;
  final String tutorName;
  final String topicTitle;
  final DateTime createdAt;
  final bool privateLecture;
  final bool requirePin;
  final String? pinCode;
  final DateTime? autoArchiveAt;
  String get topicTag {
    final t = topicTitle.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'topic_$t';
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
  });
  final bool privateLecture;
  final bool requirePin;
  final String? pinCode;
  final DateTime? autoArchiveAt;
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.monochrome = false,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool monochrome;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: monochrome ? Colors.white : null,
            activeTrackColor: monochrome ? Colors.black : null,
            inactiveThumbColor: monochrome ? Colors.black : null,
            inactiveTrackColor: monochrome ? Colors.white : null,
          ),
        ],
      ),
    );
  }
}

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
          Text('Enter PIN to view notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
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
  const _StepRailVertical({required this.steps, required this.activeIndex});
  final List<String> steps;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepDot(active: i == activeIndex, label: steps[i]),
          if (i < steps.length - 1)
            Container(
              width: 1,
              height: 28,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
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
  const _StepDot({required this.active, required this.label, this.size = 24});
  final bool active;
  final String label;
  final double size;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color border = theme.colorScheme.onSurface;
    final Color fill = active ? Colors.black : Colors.white;
    final Color text = active ? Colors.white : Colors.black;
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
    final posts = data.posts.where((p) => p.tags.contains(topic.topicTag)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(topic.topicTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('${topic.courseName} • Tutor ${topic.tutorName}', style: theme.textTheme.bodyMedium),
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
                child: Text('No notes found for this topic', style: theme.textTheme.bodyMedium),
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
    final emojis = [
      '😀','😂','😍','😊','😉','😎','😭','😅','🤔','🙌','👍','👏','🔥','💯','🎉','🙏','🤝','🫶','📚','📝','🧪','🩺','💊','⏰','📅','📎','📌','✅','❌','⚠️',
    ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: emojis.length,
              itemBuilder: (_, i) => InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _insertEmoji(emojis[i]);
                  Navigator.of(ctx).pop();
                },
                child: Center(
                  child: Text(
                    emojis[i],
                    style: const TextStyle(fontSize: 22),
                  ),
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
    final bool showAttach = widget.controller.text.trim().isEmpty;

    final input = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: 4,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.newline,
      cursorColor: Colors.black,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: Colors.black,
        fontSize: 16,
        height: 1.45,
        letterSpacing: 0.1,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: subtle,
          fontSize: 18,
          height: 1.45,
          letterSpacing: 0.1,
        ),
        prefixIcon: IconButton(
          tooltip: 'Emoji',
          onPressed: _openEmojiPicker,
          icon: Icon(Icons.emoji_emotions_outlined, color: subtle),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAttach)
              IconButton(
                tooltip: 'Attach',
                onPressed: _openAttachMenu,
                icon: Icon(Icons.attach_file_rounded, color: subtle),
              ),
            IconButton(
              tooltip: 'Send',
              onPressed: () {
                widget.onSend();
                if (_attachments.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sent with ${_attachments.length} attachment${_attachments.length == 1 ? '' : 's'}')),
                  );
                  setState(() => _attachments.clear());
                }
              },
              icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
            ),
          ],
        ),
        // Grey rounded corners
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.25 : 0.18),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.25 : 0.18),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.35 : 0.28),
            width: 1.3,
          ),
        ),
      ),
      onSubmitted: (_) => widget.onSend(),
    );

    if (_attachments.isEmpty) return input;

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
                  child: Image.memory(a.bytes, width: 76, height: 76, fit: BoxFit.cover),
                );
              } else {
                final ext = (a.name ?? '').split('.').last.toUpperCase();
                preview = Container(
                  width: 120,
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
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
                          child: Text(ext, style: const TextStyle(fontWeight: FontWeight.w700)),
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
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
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
        input,
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
        .map((w) => w.substring(0, 1).toUpperCase() + w.substring(1).toLowerCase())
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  // Match main tweet avatar size (48x48)
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.white,
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.25),
                      width: 1.5,
                    ),
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
              const SizedBox(width: 12),
              Expanded(
                child: Row(
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
    required this.count,
    required this.onPressed,
    this.label,
    this.icon,
    this.color,
    this.iconSize,
  });
  final String? label;
  final IconData? icon;
  final int count;
  final VoidCallback onPressed;
  final Color? color;
  final double? iconSize;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final bool veryTight = maxW.isFinite && maxW < 34;
            final bool ultraTight = maxW.isFinite && maxW < 28;
            final double padH = ultraTight ? 4 : (veryTight ? 6 : 10);
            final double gap = ultraTight ? 2 : (veryTight ? 3 : 6);
            final TextStyle? countStyle = theme.textTheme.bodySmall?.copyWith(color: meta);

            Widget inner = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: widget.iconSize ?? 18, color: meta),
                  SizedBox(width: gap),
                ] else if (widget.label != null && !ultraTight) ...[
                  Text(
                    // Shorten long labels when space is tight
                    veryTight && widget.label!.length > 3
                        ? widget.label!.substring(0, 1)
                        : widget.label!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: meta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: gap - 1),
                ],
                Text('${widget.count}', style: countStyle),
              ],
            );

            // Scale down the row content if width becomes too tight
            inner = FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: inner);

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onPressed,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padH, vertical: 6),
                child: inner,
              ),
            );
          },
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
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: widget.child,
    );
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
          child: child,
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
  final FocusNode _composerFocusNode = FocusNode();
  _ThreadNode? _replyTarget;
  late List<_ThreadNode> _threads;
  bool _composerVisible = true; // Keep composer open by default on comments
  final Set<_ThreadNode> _selected = <_ThreadNode>{};

  @override
  void initState() {
    super.initState();
    _threads = <_ThreadNode>[
      _ThreadNode(
        comment: const _ThreadComment(
          author: '@Naureen Ali',
          timeAgo: '14h',
          body: "Use Google authenticator instead of recovery Gmail and no what's ths??",
          likes: 1,
        ),
      ),
      _ThreadNode(
        comment: const _ThreadComment(
          author: '@Athisham Nawaz',
          timeAgo: '14h',
          body: 'Google authenticator app ha',
        ),
      ),
      _ThreadNode(
        comment: const _ThreadComment(
          author: '@Jan Mi',
          timeAgo: '2h',
          body: 'Naureen Ali Google auth app is more reliable.',
        ),
      ),
      _ThreadNode(
        comment: const _ThreadComment(
          author: '@Mahan Rehman',
          timeAgo: '13h',
          body: 'Channel suspended. Got a notification — what should I do?',
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _composer.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _setReplyTarget(_ThreadNode node) {
    setState(() {
      _replyTarget = node;
      _composerVisible = true;
    });
    // Bring up keyboard for quick reply
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _composerFocusNode.requestFocus();
      }
    });
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
                // Render the primary tweet using the canonical TweetPostCard
                TweetPostCard(
                  post: PostModel(
                    id: widget.message.id,
                    author: widget.message.author,
                    handle: widget.message.handle,
                    timeAgo: widget.message.timeAgo,
                    body: widget.message.body,
                    tags: const <String>[],
                    replies: widget.message.replies,
                    reposts: 0,
                    likes: widget.message.likes,
                    views: 0,
                    bookmarks: 0,
                  ),
                  currentUserHandle: widget.currentUserHandle,
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
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.22)),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 3, height: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyTarget!.comment.author.replaceFirst(RegExp(r'^\s*@'), ''),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _replyTarget!.comment.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _replyTarget = null;
                          // Keep composer visible even after clearing reply target
                          _composerVisible = true;
                        });
                        _composer
                          ..clear()
                          ..clearComposing();
                        _composerFocusNode.unfocus();
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_replyTarget != null || _composerVisible)
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _ClassComposer(
                controller: _composer,
                focusNode: _composerFocusNode,
                hintText: _replyTarget == null
                    ? 'Write a reply…'
                    : 'Replying to ${_replyTarget!.comment.author.replaceFirst(RegExp(r'^\s*@'), '')}',
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
  int _reposts = 0;
  bool _swipeHapticFired = false;

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
    // Strict black/white palette
    final Color lightMine = const Color(0xFFF8FAFC);
    final Color lightOther = Colors.white;
    final Color darkMine = const Color(0xFF131517);
    final Color darkOther = const Color(0xFF101214);
    final Color bubble = widget.isDark
        ? (isMine ? darkMine : darkOther)
        : (isMine ? lightMine : lightOther);

    // Meta text color uses default onSurface alpha in light theme
    final Color meta = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final bool isDark = widget.isDark;
    // Neutral grey shadow for all messages; selected gets stronger shadow
    final List<BoxShadow>? popShadow = [
      BoxShadow(
        color: Colors.grey.withValues(
          alpha: widget.selected
              ? (isDark ? 0.60 : 0.45)
              : (isDark ? 0.35 : 0.25),
        ),
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
                    comment.author.replaceFirst(RegExp(r'^\s*@'), ''),
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
                    Container(width: 3, height: 36, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (comment.quotedFrom ?? 'Reply')
                                .replaceFirst(RegExp(r'^\s*@'), ''),
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
            // Three equal columns: Like, Repost, Heartbreak
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: _LabelCountButton(
                      icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      iconSize: 20,
                      count: _likes,
                      color: _liked ? Colors.red : null,
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
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _ScaleTap(
                      onTap: () async {
                        // Comment tile repost stays local (UI only)
                        setState(() {
                          _reposted = !_reposted;
                          _reposts += _reposted ? 1 : -1;
                          if (_reposts < 0) _reposts = 0;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'REPOST',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _reposted
                                  ? Colors.green
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_reposts',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _reposted
                                  ? Colors.green
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _LabelCountButton(
                      icon: _disliked ? Icons.heart_broken_rounded : Icons.heart_broken_outlined,
                      iconSize: 18,
                      count: _dislikes,
                      color: _disliked ? Colors.black : null,
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

    // Swipe progress (0..1) for extra effects
    final double swipeT = (_dragOffset / 80.0).clamp(0.0, 1.0);
    final Widget swipeBackground = IgnorePointer(
      child: Opacity(
        opacity: swipeT,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: widget.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(Icons.reply_outlined, color: theme.colorScheme.primary),
            ),
          ),
        ),
      ),
    );

    // Prepare left-aligned avatar to match TweetPostCard sizing (size 48)
    final String _displayAuthor = comment.author.replaceFirst(RegExp(r'^\s*@'), '').trim();
    final String _initial = _displayAuthor.isNotEmpty
        ? _displayAuthor.substring(0, 1).toUpperCase()
        : 'U';
    final Widget avatar = HexagonAvatar(
      size: 48,
      borderWidth: 1.5,
      borderColor: theme.colorScheme.primary.withValues(alpha: 0.35),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          _initial,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
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
        if (!_swipeHapticFired && _dragOffset > 42) {
          HapticFeedback.mediumImpact();
          _swipeHapticFired = true;
        }
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
        _swipeHapticFired = false;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity(),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 6),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned.fill(child: swipeBackground),
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Transform.rotate(
                      angle: -0.03 * swipeT,
                      child: Transform.scale(
                        scale: 1.0 + (0.02 * swipeT),
                        child: poppedCard,
                      ),
                    ),
                  ),
                ],
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
  const _ClassLibraryTab({required this.college, required this.topics});
  final College college;
  final List<ClassTopic> topics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Library', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (topics.isEmpty)
          Text('No archived topics yet', style: theme.textTheme.bodyMedium)
        else ...[
          for (final t in topics)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                title: Text(t.topicTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('${t.courseName} • Tutor ${t.tutorName}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => _TopicDetailPage(topic: t, classCode: college.code)),
                  );
                },
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text('Resources', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in college.resources)
              _LibraryChip(resource: r),
          ],
        ),
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
    required this.onSuspend,
  });

  final Set<String> members;
  final Future<void> Function(BuildContext context) onAdd;
  final void Function(BuildContext context) onExit;
  final void Function(String handle) onSuspend;

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
              style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
              onPressed: () => onAdd(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add student'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                backgroundColor: Colors.white,
              ),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) => SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person_search_outlined),
                                title: const Text('View full profile'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => StudentProfileScreen(handle: h)),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.message_outlined),
                                title: const Text('Message'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Messaging $h…')),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.block_outlined),
                                title: const Text('Suspend student'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  onSuspend(h);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
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
                        const Icon(Icons.more_horiz),
                      ],
                    ),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

class _ClassTopInfo extends StatelessWidget {
  const _ClassTopInfo({required this.college, this.memberCount});

  final College college;
  final int? memberCount;

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
              Text('${memberCount ?? college.members} students', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
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
