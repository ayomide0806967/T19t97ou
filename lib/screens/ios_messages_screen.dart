import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
// Note: file_picker is optional. We avoid importing it so the app builds even
// when the dependency hasn't been fetched. If you add file_picker to
// pubspec and run `flutter pub get`, you can re-enable file attachments by
// switching _handleAttachFile() to use FilePicker.
import 'quiz_hub_screen.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../services/data_service.dart';
import '../widgets/tweet_post_card.dart';
import '../widgets/icons/x_retweet_icon.dart';
import '../theme/app_theme.dart';
import '../services/simple_auth_service.dart';
import '../services/roles_service.dart';
import '../screens/post_activity_screen.dart';
import '../screens/create_note_flow/teacher_note_creation_screen.dart';
import '../services/members_service.dart';
import '../services/invites_service.dart';
import 'student_profile_screen.dart';
import 'class_note_stepper_screen.dart';
import '../widgets/equal_width_buttons_row.dart';
import '../widgets/setting_switch_row.dart';
import '../models/class_note.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed unused tweet widgets imports

// In-memory lecture note buckets shared between tabs for this demo.
final List<ClassNoteSummary> _classNotes = <ClassNoteSummary>[];
final List<ClassNoteSummary> _libraryNotes = <ClassNoteSummary>[];
VoidCallback? _notifyClassNotesChanged;

const String _classNotesStoragePrefix = 'lecture_notes_';

Map<String, dynamic> _classNoteSectionToJson(ClassNoteSection s) => {
  'title': s.title,
  'subtitle': s.subtitle,
  'bullets': s.bullets,
  'imagePaths': s.imagePaths,
};

ClassNoteSection _classNoteSectionFromJson(Map<String, dynamic> json) =>
    ClassNoteSection(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      bullets: (json['bullets'] as List?)?.cast<String>() ?? const <String>[],
      imagePaths:
          (json['imagePaths'] as List?)?.cast<String>() ?? const <String>[],
    );

Map<String, dynamic> _classNoteSummaryToJson(ClassNoteSummary s) => {
  'title': s.title,
  'subtitle': s.subtitle,
  'steps': s.steps,
  'estimatedMinutes': s.estimatedMinutes,
  'createdAt': s.createdAt.toIso8601String(),
  'commentCount': s.commentCount,
  'sections': s.sections.map(_classNoteSectionToJson).toList(),
};

ClassNoteSummary _classNoteSummaryFromJson(Map<String, dynamic> json) =>
    ClassNoteSummary(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      steps: (json['steps'] as num).toInt(),
      estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      sections:
          (json['sections'] as List?)
              ?.map((e) => _classNoteSectionFromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ClassNoteSection>[],
    );

Future<void> _loadNotesForCollege(String code) async {
  final prefs = await SharedPreferences.getInstance();
  final base = '$_classNotesStoragePrefix$code';
  final rawClass = prefs.getString('${base}_class');
  final rawLibrary = prefs.getString('${base}_library');

  final List<ClassNoteSummary> classNotes;
  final List<ClassNoteSummary> libraryNotes;

  if (rawClass != null) {
    final decoded = (jsonDecode(rawClass) as List)
        .cast<Map<String, dynamic>>()
        .map(_classNoteSummaryFromJson)
        .toList();
    classNotes = decoded;
  } else {
    classNotes = <ClassNoteSummary>[];
  }

  if (rawLibrary != null) {
    final decoded = (jsonDecode(rawLibrary) as List)
        .cast<Map<String, dynamic>>()
        .map(_classNoteSummaryFromJson)
        .toList();
    libraryNotes = decoded;
  } else {
    libraryNotes = <ClassNoteSummary>[];
  }

  _classNotes
    ..clear()
    ..addAll(classNotes);
  _libraryNotes
    ..clear()
    ..addAll(libraryNotes);
}

Future<void> _saveNotesForCollege(String code) async {
  final prefs = await SharedPreferences.getInstance();
  final base = '$_classNotesStoragePrefix$code';
  final classJson = jsonEncode(
    _classNotes.map(_classNoteSummaryToJson).toList(),
  );
  final libraryJson = jsonEncode(
    _libraryNotes.map(_classNoteSummaryToJson).toList(),
  );
  await prefs.setString('${base}_class', classJson);
  await prefs.setString('${base}_library', libraryJson);
}

// WhatsApp color palette for Classes screen
const Color _whatsAppGreen = Color(0xFF25D366);
const Color _whatsAppDarkGreen = Color(0xFF128C7E);
const Color _whatsAppLightGreen = Color(0xFFDCF8C6);
const Color _whatsAppTeal = Color(0xFF075E54);

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
  const IosMinimalistMessagePage({super.key, this.openInboxOnStart = false});

  final bool openInboxOnStart;

  @override
  State<IosMinimalistMessagePage> createState() =>
      _IosMinimalistMessagePageState();
}

class _IosMinimalistMessagePageState extends State<IosMinimalistMessagePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _classesScrollController = ScrollController();
  bool _showFullPageButton = false;

  @override
  void initState() {
    super.initState();
    _classesScrollController.addListener(_handleClassesScroll);
    if (widget.openInboxOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final filtered = _filteredConversations();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _InboxPage(conversations: filtered),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _classesScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleClassesScroll() {
    const double showThreshold = 80.0;
    final offset = _classesScrollController.offset;
    if (!_showFullPageButton && offset > showThreshold) {
      setState(() {
        _showFullPageButton = true;
      });
    } else if (_showFullPageButton && offset < 20.0) {
      setState(() {
        _showFullPageButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background = Colors.white;
    final List<_Conversation> filtered = _filteredConversations();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Main column with hero + scrollable classes
            Column(
              children: [
                Builder(
                  builder: (context) {
                    final mediaQuery = MediaQuery.of(context);
                    return _SpotifyStyleHero(
                      topPadding: mediaQuery.padding.top,
                      onInboxTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _InboxPage(conversations: filtered),
                          ),
                        );
                      },
                      onCreateClassTap: () {
                        _handleCreateClass(context);
                      },
                      onJoinClassTap: () {
                        _handleJoinClass(context);
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _classesScrollController,
                    physics: const BouncingScrollPhysics(),
                    child: const _ClassesExperience(),
                  ),
                ),
              ],
            ),
            // Floating "open in full page" button that appears after scrolling
            if (_showFullPageButton)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 6,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _FullPageClassesScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Open in full page',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
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

class _FullPageClassesScreen extends StatelessWidget {
  const _FullPageClassesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.4,
      ),
      body: const SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: _ClassesExperience(),
        ),
      ),
    );
  }
}

class _ClassHeaderChip extends StatelessWidget {
  const _ClassHeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_whatsAppTeal, _whatsAppDarkGreen, _whatsAppGreen],
        ),
      ),
      child: Stack(
        children: [
          // Wave artwork background
          Positioned.fill(child: CustomPaint(painter: _WaveArtworkPainter())),
          // Decorative circles
          Positioned(
            top: -20,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 40,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                _HeaderIcon(
                  icon: Icons.quiz_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuizHubScreen()),
                    );
                  },
                  color: Colors.white.withValues(alpha: 0.95),
                ),
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Messages',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _HeaderIcon(
                  icon: CupertinoIcons.add,
                  onTap: () {},
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for wave artwork in header
class _WaveArtworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // First wave
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.65,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.6,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    // Second wave
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.85);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.6,
      size.width * 0.6,
      size.height * 0.75,
    );
    path2.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.9,
      size.width,
      size.height * 0.7,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

class _SchoolTabBar extends StatelessWidget {
  const _SchoolTabBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color label = theme.colorScheme.onSurface;
    final Color unselected = label.withValues(alpha: 0.5);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TabBar(
          isScrollable: false,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          labelColor: _whatsAppDarkGreen,
          unselectedLabelColor: unselected,
          indicatorColor: _whatsAppGreen,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Inbox'),
            Tab(text: 'Classes'),
          ],
        ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your classes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a class',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new class space for your learners.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => _handleCreateClass(context),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: const Text('Create a class'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075E54),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                      elevation: 3,
                      textStyle: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grid layout for class cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth =
                    (constraints.maxWidth - 12) / 2; // 12 = gap between cards
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (int i = 0; i < _demoColleges.length; i++)
                      SizedBox(
                        width: cardWidth,
                        child: _ModernCollegeCard(
                          college: _demoColleges[i],
                          isDark: i % 2 == 0, // Alternate dark/light
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleCreateClass(BuildContext context) async {
  final result = await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const _CreateClassPage()));
  if (result is College) {
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _CollegeScreen(college: result)),
      );
    }
  }
}

Future<void> _handleJoinClass(BuildContext context) async {
  final handle = _deriveHandle(SimpleAuthService());
  final code = await _promptForInviteCode(context);
  if (code == null) return;
  final resolved = await InvitesService.resolve(code);
  if (resolved == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.invalidInviteCode)));
    }
    return;
  }
  final match = _demoColleges.firstWhere(
    (c) => c.code.toUpperCase() == resolved.toUpperCase(),
    orElse: () => _demoColleges.first,
  );
  final members = await MembersService.getMembersFor(match.code);
  members.add(handle);
  await MembersService.saveMembersFor(match.code, members);
  if (context.mounted) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _CollegeScreen(college: match)));
  }
}

class _InboxPage extends StatelessWidget {
  const _InboxPage({required this.conversations});

  final List<_Conversation> conversations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: _MessagesList(conversations: conversations),
      backgroundColor: Colors.white,
    );
  }
}

// Spotify-style full-bleed hero that extends to the top of the screen
class _SpotifyStyleHero extends StatelessWidget {
  const _SpotifyStyleHero({
    required this.topPadding,
    required this.onInboxTap,
    required this.onCreateClassTap,
    required this.onJoinClassTap,
  });

  final double topPadding;
  final VoidCallback onInboxTap;
  final VoidCallback onCreateClassTap;
  final VoidCallback onJoinClassTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main hero content with curved bottom
        ClipPath(
          clipper: _CurvedBottomClipper(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 50), // Extra padding for wave
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000000), // Pure black at the top
                  Color(0xFF111111), // Dark grey mid
                  Color(0xFF181818), // Dark grey at the bottom
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Background artwork/pattern
                Positioned.fill(
                  child: CustomPaint(painter: _HeroArtworkPainter()),
                ),
                // Decorative elements
                Positioned(
                  top: topPadding + 40,
                  right: -20,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _whatsAppGreen.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: topPadding + 100,
                  left: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with small Inbox button
                      Row(
                        children: [
                          Text(
                            'Classes',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: onInboxTap,
                            child: const Text(
                              'Inbox',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Main heading
                      const Text(
                        'Learn Together,\nGrow Together',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create or join a class to collaborate with your peers and share knowledge.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Small secondary button for joining a class
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: onJoinClassTap,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                            label: const Text(
                              'Join a class',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Primary pill button for creating a class
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onCreateClassTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _whatsAppDarkGreen,
                            elevation: 6,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: const Text(
                            'Create a class group',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
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

// Custom clipper for curved bottom edge
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);

    // Create a smooth curve at the bottom
    path.quadraticBezierTo(
      size.width / 2, // Control point X (center)
      size.height + 20, // Control point Y (creates the curve depth)
      size.width, // End point X
      size.height - 50, // End point Y
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Custom painter for hero artwork
class _HeroArtworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Abstract curved lines
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      path.moveTo(0, size.height * (0.3 + i * 0.15));
      path.quadraticBezierTo(
        size.width * 0.4,
        size.height * (0.2 + i * 0.1),
        size.width,
        size.height * (0.4 + i * 0.12),
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Derive a normalized @handle from current user email
String _deriveHandle(SimpleAuthService auth) {
  final email = auth.currentUserEmail;
  if (email == null || email.isEmpty) return '@yourprofile';
  final normalized = email
      .split('@')
      .first
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
      .toLowerCase();
  return normalized.isEmpty ? '@yourprofile' : '@$normalized';
}

class _CreateClassTile extends StatelessWidget {
  const _CreateClassTile({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0E0F12) : Colors.white;
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.3 : 0.2,
    );
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
                  color: _whatsAppGreen.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.group_add_outlined,
                  size: 28,
                  color: _whatsAppDarkGreen,
                ),
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 32,
                color: _whatsAppDarkGreen.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinClassTile extends StatelessWidget {
  const _JoinClassTile({required this.onJoin});
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? const Color(0xFF0E0F12) : Colors.white;
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.3 : 0.2,
    );
    final Color subtitle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onJoin,
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
                  color: _whatsAppGreen.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 28,
                  color: _whatsAppDarkGreen,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.joinByCodeTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      S.joinByCodeSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 32,
                color: _whatsAppDarkGreen.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _promptForInviteCode(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(S.enterInviteCode),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'e.g. AB23YZ'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(S.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: Text(S.join),
        ),
      ],
    ),
  );
  return result == null || result.isEmpty ? null : result;
}

// Modern card design matching the reference - alternating dark/light
class _ModernCollegeCard extends StatelessWidget {
  const _ModernCollegeCard({required this.college, required this.isDark});

  final College college;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Colors based on dark/light variant
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);
    final pillBgColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFF0F0F0);
    final accentColor = const Color(
      0xFF7DD3E8,
    ); // Light cyan/teal for play button

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _CollegeScreen(college: college)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title (class name - truncated to 2 lines)
            Text(
              college.name.split(':').first.trim(), // Get short name
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Facilitator name
            Text(
              college.facilitator.split('•').first.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: subtleTextColor, fontSize: 12),
            ),
            const SizedBox(height: 24),
            // Bottom row with schedule and play button
            Row(
              children: [
                // Schedule pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pillBgColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      college.upcomingExam.isEmpty
                          ? 'Schedule'
                          : college.upcomingExam,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtleTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Play/Go button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
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
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.3 : 0.2,
    );
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
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                      const Icon(
                        CupertinoIcons.person_2,
                        size: 16,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '\${college.members} students',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
    final String facilitator = _facilitator.text.trim().isEmpty
        ? 'Admin'
        : _facilitator.text.trim();

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
    const List<String> stepTitles = [
      'Basics',
      'Privacy & roles',
      'Features',
      'Review',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Create a class')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Stack(
                children: [
                  // Vertical rail line behind all steps
                  Positioned(
                    left: 12,
                    top: 12,
                    bottom: 0,
                    child: Container(width: 1, color: Colors.black26),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < stepTitles.length; i++) ...[
                        // Header row: dot + title
                        Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (i <= _step)
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: 2,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(() => _step = i),
                                        child: _StepDot(
                                          active: i == _step,
                                          label: '${i + 1}',
                                          size: 24,
                                          dimmed: i > _step,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          stepTitles[i],
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: i == _step
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: i > _step
                                                    ? Colors.black45
                                                    : theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: i == _step
                                                                ? 1.0
                                                                : 0.85,
                                                          ),
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Active step content directly under the number/title
                        if (i == _step) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: _CreateClassStepContent(
                                theme: theme,
                                step: _step,
                                name: _name,
                                code: _code,
                                facilitator: _facilitator,
                                description: _description,
                                isPrivate: _isPrivate,
                                adminOnlyPosting: _adminOnlyPosting,
                                approvalRequired: _approvalRequired,
                                allowMedia: _allowMedia,
                                onBack: () => setState(() => _step -= 1),
                                onNext: () => setState(() => _step += 1),
                                onCreate: _create,
                                formKey: _formKey,
                                stepTitles: stepTitles,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: i == _step ? 16 : 32),
                      ],
                    ],
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
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) onNext();
              },
              child: const Text('Next'),
            ),
          )
        else
          Row(
            children: [
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
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onBack, child: const Text('Back')),
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
  const LectureNote({required this.title, this.subtitle, this.size});

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
    const whatsappGreen = Color(0xFF075E54);
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
            preferredSize: const Size.fromHeight(140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        college.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        college.facilitator,
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
                            label: '${college.members} students',
                          ),
                          const SizedBox(width: 8),
                          if (college.upcomingExam.isNotEmpty)
                            _ClassHeaderChip(
                              icon: Icons.schedule_rounded,
                              label: college.upcomingExam,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
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
              ],
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
    var allowMedia = _allowMedia;
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
                      Row(
                        children: [
                          Text(
                            S.classSettings,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.link_outlined, size: 18),
                            label: const Text('Invite by code'),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              final code = await InvitesService.getOrCreateCode(
                                widget.college.code,
                              );
                              if (!context.mounted) return;
                              showModalBottomSheet<void>(
                                context: context,
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
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.of(sheet).pop(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Theme.of(sheet)
                                                    .dividerColor
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Text(
                                              code,
                                              style: Theme.of(sheet)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
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
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                        label: 'Allow media attachments',
                        value: allowMedia,
                        onChanged: (v) {
                          setSheetState(() {
                            allowMedia = v;
                          });
                          setState(() {
                            _allowMedia = v;
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
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.tune),
                          label: const Text('Open full settings'),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const _CreateClassPage(initialStep: 1),
                              ),
                            );
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
  State<_ClassFeedTab> createState() => _ClassFeedTabState();
}

class _ClassFeedTabState extends State<_ClassFeedTab> {
  static const int _pageSize = 10;
  int _visibleNotes = 0;
  bool _loadingMoreNotes = false;

  @override
  void initState() {
    super.initState();
    _notifyClassNotesChanged = () {
      if (mounted) setState(() {});
    };
    _initNotes();
  }

  Future<void> _initNotes() async {
    await _loadNotesForCollege(widget.college.code);
    if (!mounted) return;
    setState(() {
      _visibleNotes = _classNotes.isEmpty
          ? 0
          : (_classNotes.length < _pageSize ? _classNotes.length : _pageSize);
    });
  }

  @override
  void didUpdateWidget(covariant _ClassFeedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes.length != widget.notes.length) {
      final int minNeeded = widget.notes.isEmpty ? 0 : _pageSize;
      _visibleNotes = _visibleNotes.clamp(minNeeded, widget.notes.length);
      if (_visibleNotes == 0 && widget.notes.isNotEmpty) {
        _visibleNotes = widget.notes.length < _pageSize
            ? widget.notes.length
            : _pageSize;
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

  Future<void> _confirmDeleteNote(ClassNoteSummary note) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    setState(() {
      _classNotes.remove(note);
    });
    await _saveNotesForCollege(widget.college.code);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lecture note deleted')));
  }

  @override
  void dispose() {
    _notifyClassNotesChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    final TextEditingController textController = TextEditingController();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              // Class discussion label sits above the lecture CTA so
              // both the create button and cards feel grouped under it.
              Text(
                S.classDiscussion,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.activeTopic == null && widget.isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _ClassActionCard(
                        title: 'Create lecture note',
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
                            setState(() {
                              _classNotes.insert(0, summary);
                            });
                            await _saveNotesForCollege(widget.college.code);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _ClassActionCard(
                        title: 'Quiz',
                        backgroundColor: _whatsAppGreen.withValues(alpha: 0.15),
                        playIconColor: _whatsAppTeal,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QuizHubScreen(),
                            ),
                          );
                        },
                      ),
                    ),
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
              if (_classNotes.isEmpty) ...[
                Text(
                  'Class notes you create will appear here.',
                  style: theme.textTheme.bodySmall?.copyWith(color: subtle),
                ),
                const SizedBox(height: 4),
              ] else ...[
                Column(
                  children: [
                    for (final note in _classNotes) ...[
                      _ClassNotesCard(
                        summary: note,
                        onUpdated: (updated) {
                          setState(() {
                            final int index = _classNotes.indexOf(note);
                            if (index != -1) {
                              _classNotes[index] = updated;
                            }
                          });
                          _saveNotesForCollege(widget.college.code);
                        },
                        onMoveToLibrary: () {
                          setState(() {
                            _classNotes.remove(note);
                          });
                          _libraryNotes.insert(0, note);
                          _saveNotesForCollege(widget.college.code);
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
    );
  }
}

class _ClassActionCard extends StatelessWidget {
  const _ClassActionCard({
    required this.title,
    required this.onTap,
    required this.backgroundColor,
    this.chips = const <String>[],
    this.playIconColor = Colors.black,
  });

  final String title;
  final VoidCallback onTap;
  final Color backgroundColor;
  final List<String> chips;
  final Color playIconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                        fontSize: 15,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final chip in chips)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                chip,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: playIconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed legacy _ActiveTopicCard: details are now surfaced in the class header
// and a compact "Move to Library" pill above the discussion instead of a full card.

class _StartLectureCard extends StatefulWidget {
  const _StartLectureCard({required this.onStart});
  final void Function(
    String course,
    String tutor,
    String topic,
    _TopicSettings settings,
  )
  onStart;
  @override
  State<_StartLectureCard> createState() => _StartLectureCardState();
}

/// Full-page lecture setup experience, opened from the "CREATE LECTURE NOTE"
/// button on the class feed. Wraps the existing _StartLectureCard in a
/// dedicated screen with a black aesthetic banner.
class _LectureSetupPage extends StatelessWidget {
  const _LectureSetupPage({
    required this.college,
    required this.onStartLecture,
  });

  final College college;
  final void Function(
    String course,
    String tutor,
    String topic,
    _TopicSettings settings,
  )
  onStartLecture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // WhatsApp-style header green for the create-lecture page.
    const Color bannerColor = Color(0xFF075E54);
    final Color bannerText = Colors.white;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top black banner with class context and description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              college.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: bannerText.withValues(alpha: 0.75),
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Create lecture note',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: bannerText,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Set up the course, tutor, topic, and access before you start posting notes in real time.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: bannerText.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Lecture setup form
            Expanded(
              child: SingleChildScrollView(
                // Push the form closer to the vertical middle on
                // taller screens while remaining scrollable.
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                child: _LectureSetupForm(
                  onSubmit: (course, tutor, topic, settings) async {
                    // Notify parent to mark the topic as active
                    onStartLecture(course, tutor, topic, settings);
                    // Then take the user straight into the note creation flow
                    final summary = await Navigator.of(context)
                        .push<ClassNoteSummary>(
                          MaterialPageRoute(
                            builder: (_) => TeacherNoteCreationScreen(
                              topic: topic,
                              subtitle: tutor.isNotEmpty ? tutor : course,
                            ),
                          ),
                        );
                    if (!context.mounted) return;
                    Navigator.of(context).pop<ClassNoteSummary>(summary);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boxed lecture setup form that mirrors the "Create Lecture" note style.
class _LectureSetupForm extends StatefulWidget {
  const _LectureSetupForm({required this.onSubmit});

  final void Function(
    String course,
    String tutor,
    String topic,
    _TopicSettings settings,
  )
  onSubmit;

  @override
  State<_LectureSetupForm> createState() => _LectureSetupFormState();
}

class _LectureSetupFormState extends State<_LectureSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _tutorController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  int _step = 0; // 0 = details, 1 = privacy
  bool _privateLecture = false;
  bool _requirePin = false;
  DateTime? _autoArchiveAt;

  @override
  void dispose() {
    _courseController.dispose();
    _tutorController.dispose();
    _topicController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  /// Simple, stable time picker that avoids the Material
  /// time picker layout bug on some devices by using a
  /// Cupertino-style wheel in a custom bottom sheet.
  Future<TimeOfDay?> _pickTimeSheet(
    BuildContext context,
    TimeOfDay initial,
  ) async {
    TimeOfDay temp = initial;
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String _format(TimeOfDay t) {
          final int hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
          final String minute = t.minute.toString().padLeft(2, '0');
          final String period = t.period == DayPeriod.am ? 'AM' : 'PM';
          return '$hour:$minute $period';
        }

        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      Text(
                        'Select time',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(temp),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Large, centered time preview for better readability.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Builder(
                    builder: (_) => StatefulBuilder(
                      builder: (context, setLocalState) {
                        // This StatefulBuilder is only used to refresh
                        // the preview text when the wheel changes.
                        return Text(
                          _format(temp),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(
                      2020,
                      1,
                      1,
                      initial.hour,
                      initial.minute,
                    ),
                    use24hFormat: false,
                    onDateTimeChanged: (dt) {
                      final next = TimeOfDay(hour: dt.hour, minute: dt.minute);
                      if (next == temp) return;
                      temp = next;
                      // Rebuild the preview text only.
                      (ctx as Element).markNeedsBuild();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    final time = await _pickTimeSheet(
      context,
      TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    setState(() {
      _autoArchiveAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final course = _courseController.text.trim();
    final tutor = _tutorController.text.trim();
    final topic = _topicController.text.trim();
    final settings = _TopicSettings(
      privateLecture: _privateLecture,
      requirePin: _requirePin,
      pinCode: _requirePin ? _pinController.text.trim() : null,
      autoArchiveAt: _autoArchiveAt,
    );
    widget.onSubmit(course, tutor, topic, settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final InputDecorationTheme inputTheme = InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.black, width: 1.8),
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini stepper header showing 1 and 2
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: _StepRailMini(activeIndex: _step, steps: const ['1', '2']),
            ),
          ),
          if (_step == 0) ...[
            // Step 1: Lecture details
            Text(
              'Lecture details',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: Theme(
                data: theme.copyWith(
                  inputDecorationTheme: inputTheme,
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Colors.black,
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _courseController,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Course name',
                        hintText: 'e.g., Biology 401 · Genetics',
                      ),
                      style: const TextStyle(color: Colors.black),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter course name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tutorController,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Tutor name (optional)',
                        hintText: 'e.g., Dr. Tayo Ajayi',
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _topicController,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        hintText: 'e.g., Mendelian inheritance, DNA structure',
                      ),
                      style: const TextStyle(color: Colors.black),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter topic' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Next button (step 1 of 2)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _step = 1);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF075E54),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Next'),
              ),
            ),
          ] else ...[
            // Step 2: Access & privacy
            Text(
              'Access & privacy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingSwitchRow(
                    label: 'Private lecture (disable repost)',
                    value: _privateLecture,
                    onChanged: (v) => setState(() => _privateLecture = v),
                    monochrome: true,
                  ),
                  SettingSwitchRow(
                    label: 'Require PIN to access',
                    value: _requirePin,
                    onChanged: (v) => setState(() => _requirePin = v),
                    monochrome: true,
                  ),
                  if (_requirePin) ...[
                    const SizedBox(height: 6),
                    Theme(
                      data: theme.copyWith(
                        inputDecorationTheme: inputTheme,
                        textSelectionTheme: const TextSelectionThemeData(
                          cursorColor: Colors.black,
                        ),
                      ),
                      child: TextFormField(
                        controller: _pinController,
                        decoration: const InputDecoration(
                          labelText: 'PIN code',
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (v) {
                          if (!_requirePin) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a PIN code';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Auto-archive', style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      if (_autoArchiveAt != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _autoArchiveAt = null),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                  if (_autoArchiveAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _autoArchiveAt!.toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: const Color(0xFF075E54),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _pickDateTime(context),
                      child: const Text('Date/time'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Back + Start buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 0),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF075E54),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start lecture'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
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
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.28 : 0.18,
    );
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
              Text(
                'Start a lecture',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                decoration: const InputDecoration(
                  labelText: 'Tutor name (optional)',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _topic,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                cursorColor: Colors.black,
                decoration: const InputDecoration(labelText: 'Topic'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_canStart) setState(() => _step = 1);
                },
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
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _canStart
                        ? () => setState(() => _step = 1)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              SettingSwitchRow(
                label: 'Private lecture (disable repost)',
                value: _privateLecture,
                onChanged: (v) => setState(() => _privateLecture = v),
                monochrome: true,
              ),
              SettingSwitchRow(
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
                    Text(
                      _autoArchiveAt!.toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
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
                              initialTime: TimeOfDay.fromDateTime(
                                now.add(const Duration(hours: 1)),
                              ),
                            );
                            if (time == null) return;
                            final dt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            setState(() => _autoArchiveAt = dt);
                          },
                          child: const Text('Date/time'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () =>
                              setState(() => _autoArchiveAt = null),
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
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => setState(() => _step = 0),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Back', maxLines: 1),
                    ),
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
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Start', maxLines: 1),
                    ),
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
    final t = topicTitle.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
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

class _ClassNotesCard extends StatelessWidget {
  _ClassNotesCard({
    required this.summary,
    this.onUpdated,
    this.onMoveToLibrary,
    this.inLibrary = false,
    this.onDelete,
  });

  final ClassNoteSummary summary;
  final ValueChanged<ClassNoteSummary>? onUpdated;
  final VoidCallback? onMoveToLibrary;
  final bool inLibrary;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    final bool isDark = theme.brightness == Brightness.dark;
    const whatsappGreen = Color(0xFF075E54);
    final DateTime createdAt = summary.createdAt;
    final String dateLabel =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClassNoteStepperScreen(summary: summary),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: whatsappGreen,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: whatsappGreen),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withValues(alpha: 0.14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lecture note',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Topic: ${summary.title}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: onDelete,
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: () async {
                          final updated = await Navigator.of(context)
                              .push<ClassNoteSummary>(
                                MaterialPageRoute(
                                  builder: (_) => TeacherNoteCreationScreen(
                                    topic: summary.title,
                                    subtitle: summary.subtitle,
                                    initialSections: summary.sections,
                                    initialCreatedAt: summary.createdAt,
                                    initialCommentCount: summary.commentCount,
                                  ),
                                ),
                              );
                          if (updated != null &&
                              onUpdated != null &&
                              context.mounted) {
                            onUpdated!(updated);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.list_alt_outlined,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.steps} step${summary.steps == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.estimatedMinutes} min review',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onMoveToLibrary != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: inLibrary
                            ? Colors.grey.shade300
                            : Colors.white,
                        foregroundColor: inLibrary
                            ? Colors.grey.shade700
                            : whatsappGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: inLibrary
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClassNoteStepperScreen(summary: summary),
                                ),
                              );
                            },
                      icon: Icon(
                        inLibrary ? Icons.block : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(inLibrary ? 'Deactivate' : 'Open'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: whatsappGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: onMoveToLibrary,
                          icon: const Icon(Icons.archive_outlined, size: 18),
                          label: Text(
                            inLibrary ? 'Move to Class' : 'Move to Library',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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
    final Color meta =
        widget.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6);
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
            final TextStyle? countStyle = theme.textTheme.bodySmall?.copyWith(
              color: meta,
            );

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
            inner = FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: inner,
            );

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

class _EmojiReactionChip extends StatelessWidget {
  const _EmojiReactionChip({
    required this.emoji,
    required this.count,
    this.isActive = false,
    this.onTap,
  });

  final String emoji;
  final int count;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isHeart = emoji == '❤️';
    final Color fg = isHeart
        ? Colors.red
        : (isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.8));

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(emoji, style: TextStyle(fontSize: 14, color: fg))],
      ),
    );
  }
}

// Repost now rendered as text label "repost"

class _MessageCommentsPage extends StatefulWidget {
  const _MessageCommentsPage({
    required this.message,
    required this.currentUserHandle,
  });

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
          body:
              "Use Google authenticator instead of recovery Gmail and no what's ths??",
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

  Future<void> _ensureRepostForReply() async {
    final handle = widget.currentUserHandle.trim();
    if (handle.isEmpty) return;

    final data = context.read<DataService>();
    final String targetId = widget.message.id;

    final bool alreadyReposted = data.hasUserRetweeted(targetId, handle);
    if (alreadyReposted) return;

    await data.toggleRepost(postId: targetId, userHandle: handle);
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

    // Ensure replying also surfaces the post on the global feed as a repost.
    _ensureRepostForReply();

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

  void _replyToSelected() {
    if (_selected.isEmpty) return;
    // Reply to the first selected node
    final _ThreadNode target = _selected.first;
    _setReplyTarget(target);
  }

  void _showInfoForSelected() {
    if (_selected.isEmpty) return;
    final theme = Theme.of(context);
    final int count = _selected.length;
    final preview = _selected
        .take(3)
        .map((n) => '• ${n.comment.author}: ${n.comment.body}')
        .join('\n');
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected: $count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              style: theme.textTheme.bodyMedium,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSelected() {
    if (_selected.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comments?'),
        content: Text(
          'This will remove ${_selected.length} selected ${_selected.length == 1 ? 'comment' : 'comments'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _threads = _filterNodes(_threads, _selected);
                _selected.clear();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<_ThreadNode> _filterNodes(
    List<_ThreadNode> nodes,
    Set<_ThreadNode> remove,
  ) {
    final List<_ThreadNode> out = <_ThreadNode>[];
    for (final n in nodes) {
      if (remove.contains(n)) continue;
      final children = _filterNodes(n.children, remove);
      out.add(_ThreadNode(comment: n.comment, children: children));
    }
    return out;
  }

  Future<void> _forwardSelected() async {
    if (_selected.isEmpty) return;
    final text = _selected
        .map((n) => '${n.comment.author}: ${n.comment.body}')
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied selected comments')));
  }

  void _showMoreMenu() {
    if (_selected.isEmpty) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () async {
                Navigator.pop(ctx);
                await _forwardSelected();
              },
            ),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('Select all'),
              onTap: () {
                setState(() {
                  _selected
                    ..clear()
                    ..addAll(_flatten(_threads));
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear selection'),
              onTap: () {
                Navigator.pop(ctx);
                _clearSelection();
              },
            ),
          ],
        ),
      ),
    );
  }

  Iterable<_ThreadNode> _flatten(List<_ThreadNode> nodes) sync* {
    for (final n in nodes) {
      yield n;
      yield* _flatten(n.children);
    }
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
                  onPressed: _replyToSelected,
                ),
                IconButton(
                  tooltip: 'Info',
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showInfoForSelected,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _deleteSelected,
                ),
                IconButton(
                  tooltip: 'Forward',
                  icon: const Icon(Icons.redo_rounded),
                  onPressed: _forwardSelected,
                ),
                IconButton(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showMoreMenu,
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
                  fullWidthHeader: true,
                  showTimeInHeader: false,
                ),
                const SizedBox(height: 12),
                // Top / View activity bar, matching X-style replies header
                Builder(
                  builder: (context) {
                    final ThemeData theme = Theme.of(context);
                    // Make the separators around the Top / View activity bar
                    // more prominent so they clearly match the reference UI.
                    final Color divider = theme.colorScheme.onSurface
                        .withValues(
                          // Slightly softer than before so the lines
                          // are visible but not overpowering.
                          alpha: theme.brightness == Brightness.dark
                              ? 0.28
                              : 0.12,
                        );
                    final Color subtle = theme.colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Divider(height: 1, thickness: 0.8, color: divider),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Left: Top ▼
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Top',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: subtle,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Right: View activity >
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {
                                  final post = PostModel(
                                    id: widget.message.id,
                                    author: widget.message.author,
                                    handle: widget.message.handle,
                                    timeAgo: widget.message.timeAgo,
                                    body: widget.message.body,
                                    tags: const <String>[],
                                    replies: widget.message.replies,
                                    reposts: 0, // Not tracked in message model
                                    likes: widget.message.likes,
                                    views: 0,
                                    bookmarks: 0,
                                  );
                                  Navigator.of(
                                    context,
                                  ).push(PostActivityScreen.route(post: post));
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View activity',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: subtle,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: subtle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, thickness: 0.8, color: divider),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
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
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.22),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyTarget!.comment.author.replaceFirst(
                              RegExp(r'^\s*@'),
                              '',
                            ),
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
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
              minimum: const EdgeInsets.fromLTRB(16, 2, 8, 4),
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

/// Simple "Post activity" surface shown from the Replies screen when
/// the user taps "View activity".
class _PostActivityPage extends StatelessWidget {
  const _PostActivityPage({required this.message});

  final _ClassMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color divider = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.2,
    );
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.7 : 0.6,
    );

    // Derive simple demo counts from the message.
    final int likes = message.likes > 0 ? message.likes : 3261;
    final int reposts = message.replies > 0 ? message.replies : 801;
    const int quotes = 54;

    String _format(int value) {
      if (value >= 1000000) {
        final formatted = value / 1000000;
        return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}M';
      }
      if (value >= 1000) {
        final formatted = value / 1000;
        return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}K';
      }
      return value.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post activity'),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Sort',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Compact preview of the original message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      message.author.isNotEmpty
                          ? message.author.substring(0, 1).toUpperCase()
                          : 'Y',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.author,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Likes / Reposts / Quotes summary
          _ActivitySummaryRow(
            icon: Icons.favorite_border_rounded,
            label: 'Likes',
            value: _format(likes),
            dividerColor: divider,
          ),
          _ActivitySummaryRow(
            icon: Icons.repeat_rounded,
            label: 'Reposts',
            value: _format(reposts),
            dividerColor: divider,
          ),
          _ActivitySummaryRow(
            icon: Icons.mode_comment_outlined,
            label: 'Quotes',
            value: _format(quotes),
            dividerColor: divider,
          ),
          const SizedBox(height: 16),
          Text(
            'Recent activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Simple mocked list of users who interacted
          for (final user in _demoActivityUsers)
            _ActivityUserTile(
              name: user.name,
              subtitle: user.subtitle,
              isFollowing: user.isFollowing,
            ),
          if (_demoActivityUsers.isEmpty)
            Text(
              'No activity yet',
              style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
            ),
        ],
      ),
    );
  }
}

class _ActivitySummaryRow extends StatelessWidget {
  const _ActivitySummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.dividerColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.onSurface),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: dividerColor),
      ],
    );
  }
}

class _ActivityUser {
  const _ActivityUser({
    required this.name,
    required this.subtitle,
    required this.isFollowing,
  });

  final String name;
  final String subtitle;
  final bool isFollowing;
}

const List<_ActivityUser> _demoActivityUsers = <_ActivityUser>[
  _ActivityUser(
    name: 'aanya_naznin',
    subtitle: '24h • Reacted with ✅📩📌',
    isFollowing: true,
  ),
  _ActivityUser(
    name: 'urfav_jecel14',
    subtitle: '5h • Real',
    isFollowing: false,
  ),
  _ActivityUser(
    name: 'sa__mrtnz',
    subtitle: '40m • 36 followers',
    isFollowing: false,
  ),
];

class _ActivityUserTile extends StatelessWidget {
  const _ActivityUserTile({
    required this.name,
    required this.subtitle,
    required this.isFollowing,
  });

  final String name;
  final String subtitle;
  final bool isFollowing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color avatarBg = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
        : theme.colorScheme.primary.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared "chat-style" discussion thread UI used by the class note stepper.
class ClassDiscussionThreadPage extends StatefulWidget {
  const ClassDiscussionThreadPage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  State<ClassDiscussionThreadPage> createState() =>
      _ClassDiscussionThreadPageState();
}

class _ClassDiscussionThreadPageState extends State<ClassDiscussionThreadPage> {
  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  _ThreadNode? _replyTarget;
  late List<_ThreadNode> _threads;

  @override
  void initState() {
    super.initState();
    _threads = <_ThreadNode>[];
  }

  @override
  void dispose() {
    _composer.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  String get _currentUserHandle {
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
    return me;
  }

  void _setReplyTarget(_ThreadNode node) {
    setState(() {
      _replyTarget = node;
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String handle = _currentUserHandle;

    return Scaffold(
      appBar: AppBar(title: const Text('Class discussion')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                if (_threads.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'Ask a question to start the discussion.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  _ThreadCommentsView(
                    nodes: _threads,
                    currentUserHandle: handle,
                    onReply: _setReplyTarget,
                    selectionMode: false,
                    selected: const <_ThreadNode>{},
                    onToggleSelect: (_) {},
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
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.22),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyTarget!.comment.author.replaceFirst(
                              RegExp(r'^\s*@'),
                              '',
                            ),
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
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
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _ClassComposer(
              controller: _composer,
              focusNode: _composerFocusNode,
              hintText: _replyTarget == null
                  ? 'Ask a question or share a thought…'
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
    : children = children != null
          ? List<_ThreadNode>.from(children)
          : <_ThreadNode>[];
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (depth > 0) ...[
                Container(
                  width: 10,
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 2,
                    margin: EdgeInsets.only(top: 8, bottom: isLast ? 18 : 4),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(
                        alpha: isDark ? 0.45 : 0.35,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: _CommentTile(
                  comment: node.comment,
                  isDark: isDark,
                  currentUserHandle: currentUserHandle,
                  onSwipeReply: selectionMode
                      ? null
                      : () => onReply?.call(node),
                  selected: selected.contains(node),
                  onLongPress: onToggleSelect,
                  onTap: selectionMode ? onToggleSelect : null,
                ),
              ),
            ],
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
  // Track which comment currently shows inline repost actions so only one is open.
  static _CommentTileState? _openRepostTile;

  bool _highlight = false;
  double _dx = 0;
  double _dragOffset = 0; // visual slide during swipe-to-reply
  int _likes = 0;
  bool _liked = false;
  bool _reposted = false;
  int _reposts = 0;
  bool _swipeHapticFired = false;
  bool _showRepostActions = false;
  final Map<String, int> _reactions = <String, int>{};
  String? _currentUserReaction;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
    _seedMockReactions();
  }

  @override
  void dispose() {
    if (identical(_openRepostTile, this)) {
      _openRepostTile = null;
    }
    super.dispose();
  }

  void _closeRepostActions() {
    if (!_showRepostActions) return;
    setState(() {
      _showRepostActions = false;
    });
  }

  void _toggleRepostActions() {
    setState(() {
      final bool opening = !_showRepostActions;
      if (opening) {
        _openRepostTile?._closeRepostActions();
        _openRepostTile = this;
        _showRepostActions = true;
      } else {
        _showRepostActions = false;
        if (identical(_openRepostTile, this)) {
          _openRepostTile = null;
        }
      }
    });
  }

  void _showReactionDetails(String emoji) {
    final theme = Theme.of(context);
    final int count = _reactions[emoji] ?? 0;
    if (count <= 0) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: false,
      builder: (BuildContext ctx) {
        final String title = '$count reaction${count == 1 ? '' : 's'}';
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // Emoji filters row – show all reaction emojis with counts.
                Builder(
                  builder: (_) {
                    final List<MapEntry<String, int>> sorted =
                        _reactions.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < sorted.length; i++) ...[
                            _EmojiReactionChip(
                              emoji: sorted[i].key,
                              count: sorted[i].value,
                              isActive: sorted[i].key == emoji,
                            ),
                            if (i != sorted.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    itemCount: count,
                    itemBuilder: (BuildContext _, int index) {
                      final bool isYou =
                          index == 0 && _currentUserReaction == emoji;
                      final String name = isYou
                          ? 'You'
                          : '${widget.comment.author} #${index + 1}';
                      final String subtitle = isYou
                          ? widget.currentUserHandle
                          : widget.currentUserHandle;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            name.substring(0, 1).toUpperCase(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isYou
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        trailing: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _seedMockReactions() {
    if (_reactions.isNotEmpty) return;
    final List<String> pool = <String>['👍', '❤️', '😂', '😮', '😢', '👏'];
    final int base = widget.comment.body.hashCode.abs();
    // Between 0 and 3 mock reactions.
    final int reactionCount = (base % 4); // 0–3
    for (int i = 0; i < reactionCount; i++) {
      final String emoji = pool[(base + i * 5) % pool.length];
      final int value = 1 + ((base >> (i * 3)) & 0x3); // 1–4
      _reactions[emoji] = value;
    }
  }

  Future<void> _openReactionPicker() async {
    const List<String> emojis = <String>[
      '👍',
      '❤️',
      '😂',
      '😮',
      '😢',
      '👏',
      '🔥',
      '🎉',
      '🙏',
      '😍',
    ];
    final theme = Theme.of(context);
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset origin = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    String? choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final double top = (origin.dy - 72).clamp(16.0, double.infinity);
        final double centerX = origin.dx + size.width / 2;
        return Stack(
          children: [
            Positioned(
              top: top,
              left: centerX - 160,
              right: centerX - 160,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scrollable emoji strip
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final String emoji in emojis)
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.of(dialogContext).pop(emoji),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Text(
                                        emoji,
                                        style: TextStyle(
                                          fontSize: 26,
                                          color: emoji == '❤️'
                                              ? Colors.red
                                              : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.95),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Plus button (always visible)
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(dialogContext).pop('__more__'),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.0,
                                  ),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (choice == '__more__') {
      choice = await _openFullEmojiSheet();
    }
    if (choice == null) return;
    final String selected = choice;
    setState(() {
      // Enforce a single active reaction per user.
      if (_currentUserReaction == selected) {
        // Tapping the same reaction again clears it.
        final int existing = _reactions[selected] ?? 0;
        if (existing > 0) {
          final int next = existing - 1;
          if (next > 0) {
            _reactions[selected] = next;
          } else {
            _reactions.remove(selected);
          }
        }
        _currentUserReaction = null;
      } else {
        // Remove previous reaction, if any.
        final String? previous = _currentUserReaction;
        if (previous != null) {
          final int current = _reactions[previous] ?? 0;
          if (current > 0) {
            final int next = current - 1;
            if (next > 0) {
              _reactions[previous] = next;
            } else {
              _reactions.remove(previous);
            }
          }
        }
        // Apply new reaction.
        _reactions[selected] = (_reactions[selected] ?? 0) + 1;
        _currentUserReaction = selected;
      }
    });
  }

  Future<String?> _openFullEmojiSheet() async {
    final theme = Theme.of(context);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
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
                Navigator.of(ctx).pop(emoji.emoji);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final _ThreadComment comment = widget.comment;
    final bool isMine =
        comment.author == widget.currentUserHandle || comment.author == 'You';
    // Light: subtle card variants. Dark: glassy card with semi-transparent white.
    final Color lightMine = const Color(0xFFF8FAFC);
    final Color lightOther = Colors.white;
    final Color baseLight = isMine
        ? lightMine
        : lightOther; // used only in light mode
    final Color bubble = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : baseLight;

    // Meta text color uses default onSurface alpha in light theme
    final Color meta = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final bool isDark = widget.isDark;
    // Soft material-style card shadow for each reply (matches app card style).
    final List<BoxShadow> popShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.45 : 0.06),
        offset: const Offset(0, 6),
        blurRadius: 18,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
        offset: const Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
    const double bubbleRadius = 18;
    const double avatarSize = 48;

    final Color selectedHover = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);
    // When a reply has been reposted, highlight its card border in green.
    final Color borderColor = _reposted
        ? const Color(0xFF00BA7C)
        : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE5E7EB));
    // Avatar used inside the card for other users.
    final String displayAuthor = comment.author
        .replaceFirst(RegExp(r'^\s*@'), '')
        .trim();
    final String initial = displayAuthor.isNotEmpty
        ? displayAuthor.substring(0, 1).toUpperCase()
        : 'U';
    final Widget avatarWidget = isMine
        ? const SizedBox.shrink()
        : Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1EC),
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child: Text(
                initial,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
    // Padding inside the reply card.
    final EdgeInsets bubblePadding = const EdgeInsets.fromLTRB(12, 8, 12, 8);

    final Widget bubbleCore = Container(
      padding: bubblePadding,
      decoration: BoxDecoration(
        color: widget.selected ? selectedHover : bubble,
        borderRadius: BorderRadius.circular(bubbleRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: popShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isMine) avatarWidget,
          if (!isMine) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Row(
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
                ),
                const SizedBox(height: 2),
                if (comment.quotedBody != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : theme.colorScheme.surfaceVariant.withValues(
                              alpha: 0.9,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(
                          alpha: widget.isDark ? 0.4 : 0.3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 3,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (comment.quotedFrom ?? 'Reply').replaceFirst(
                                  RegExp(r'^\s*@'),
                                  '',
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.quotedBody!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: widget.isDark ? 0.9 : 0.85,
                                  ),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  comment.body,
                  style: AppTheme.tweetBody(
                    widget.isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                  ),
                ),
                if (_reposted && !_showRepostActions) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const XRetweetIcon(size: 14, color: Color(0xFF00BA7C)),
                        const SizedBox(width: 4),
                        Text(
                          'Reposted',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00BA7C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_showRepostActions) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: widget.isDark ? 0.25 : 0.06,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _reposted = !_reposted;
                                _reposts += _reposted ? 1 : -1;
                                if (_reposts < 0) _reposts = 0;
                                _showRepostActions = false;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  XRetweetIcon(
                                    size: 16,
                                    color: _reposted
                                        ? const Color(0xFF00BA7C)
                                        : meta,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _reposted ? 'Unrepost' : 'Repost',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                      color: _reposted ? Colors.green : meta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: widget.isDark ? 0.35 : 0.25,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              setState(() {
                                _showRepostActions = false;
                              });
                              widget.onSwipeReply?.call();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.reply_rounded, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reply',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: meta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
              color: theme.colorScheme.primary.withValues(
                alpha: widget.isDark ? 0.18 : 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.reply_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _highlight = true),
      onTapUp: (_) => setState(() => _highlight = false),
      onTapCancel: () => setState(() => _highlight = false),
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          _toggleRepostActions();
        }
      },
      onDoubleTap: _openReactionPicker,
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
            (details.primaryVelocity != null &&
                details.primaryVelocity! > 250) ||
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
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Reply bubble + swipe background
            Padding(
              padding: EdgeInsets.only(
                left: 0,
                bottom: _reactions.isNotEmpty ? 14 : 0,
              ),
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
            if (_reactions.isNotEmpty)
              Positioned(
                left: isMine ? 12 : avatarSize / 2 + 12,
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Builder(
                    builder: (_) {
                      final List<MapEntry<String, int>> sorted =
                          _reactions.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                      const int maxVisible = 4;
                      final int visibleCount = sorted.length > maxVisible
                          ? maxVisible
                          : sorted.length;

                      int totalCount = 0;
                      for (final entry in sorted) {
                        totalCount += entry.value;
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < visibleCount; i++) ...[
                            _EmojiReactionChip(
                              emoji: sorted[i].key,
                              count: sorted[i].value,
                              isActive: sorted[i].key == _currentUserReaction,
                              onTap: () => _showReactionDetails(sorted[i].key),
                            ),
                            if (i != visibleCount - 1) const SizedBox(width: 8),
                          ],
                          if (totalCount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '$totalCount',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
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

class _ClassLibraryTab extends StatefulWidget {
  const _ClassLibraryTab({required this.college, required this.topics});
  final College college;
  final List<ClassTopic> topics;

  @override
  State<_ClassLibraryTab> createState() => _ClassLibraryTabState();
}

class _ClassLibraryTabState extends State<_ClassLibraryTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Library',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'No note yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF upload coming soon')),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Add PDF to library'),
              ),
            ],
          ),
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
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.3 : 0.2,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Opening "${note.title}"')));
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
                child: Icon(
                  Icons.article_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.subtitle != null || note.size != null)
                      Builder(
                        builder: (context) {
                          final String meta =
                              <String?>[note.subtitle, note.size]
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
                        },
                      ),
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

class _ClassStudentsTab extends StatefulWidget {
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
  State<_ClassStudentsTab> createState() => _ClassStudentsTabState();
}

class _ClassStudentsTabState extends State<_ClassStudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> list = widget.members.toList()..sort();

    final List<String> filteredList = _query.isEmpty
        ? list
        : list
              .where(
                (handle) => handle.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    void _showStudentActions(String handle) {
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
                      MaterialPageRoute(
                        builder: (_) => StudentProfileScreen(handle: handle),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message_outlined),
                  title: const Text('Message'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Messaging $handle…')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('Suspend student'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onSuspend(handle);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => widget.onAdd(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add student'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide.none,
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => widget.onExit(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete class'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                prefixIconColor: Colors.black.withValues(alpha: 0.55),
                hintText: 'Search students',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _query = value.trim();
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No students listed yet',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else if (filteredList.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No students found',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 0,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final String handle = filteredList[index];
                return _StudentCard(
                  handle: handle,
                  index: index,
                  onTap: () => _showStudentActions(handle),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.handle,
    required this.index,
    required this.onTap,
  });

  final String handle;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color cardColor = theme.colorScheme.surface;
    final Color nameColor = const Color(0xFF111827);
    final Color frameColor = theme.colorScheme.surfaceVariant.withValues(
      alpha: 0.8,
    );

    final String cleanHandle = handle.replaceFirst(RegExp('^@'), '');
    final List<String> parts = cleanHandle
        .split(RegExp(r'[_\.]'))
        .where((p) => p.isNotEmpty)
        .toList();
    final String displayName = parts.isEmpty
        ? cleanHandle
        : parts
              .map(
                (p) => p.length == 1
                    ? p.toUpperCase()
                    : '${p[0].toUpperCase()}${p.substring(1)}',
              )
              .join(' ');
    final String initials = cleanHandle.isEmpty
        ? '--'
        : cleanHandle
              .replaceAll(RegExp(r'[^a-zA-Z]'), '')
              .toUpperCase()
              .padRight(2, cleanHandle[0].toUpperCase())
              .substring(0, 2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(color: Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: frameColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: nameColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName.isEmpty ? handle : displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nameColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassTopInfo extends StatelessWidget {
  const _ClassTopInfo({
    required this.college,
    this.memberCount,
    this.activeTopic,
  });

  final College college;
  final int? memberCount;
  final ClassTopic? activeTopic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color whatsappGreen = Color(0xFF075E54);
    final Color onGreen = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: whatsappGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  college.code,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onGreen,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${memberCount ?? college.members} students',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onGreen.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            college.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: onGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            college.facilitator,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onGreen.withValues(alpha: 0.8),
            ),
          ),
          if (activeTopic != null) ...[
            const SizedBox(height: 10),
            Text(
              'Topic: ${activeTopic!.topicTitle}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: onGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tutor ${activeTopic!.tutorName} • Started ${_formatRelative(activeTopic!.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onGreen.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Removed unused _CollegeHeader widget
