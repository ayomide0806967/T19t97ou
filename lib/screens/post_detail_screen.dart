import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/x_comment_section.dart';

class PostDetailPayload {
  const PostDetailPayload({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    required this.initials,
    this.tags = const <String>[],
    this.replies = 0,
    this.reposts = 0,
    this.likes = 0,
    this.bookmarks = 0,
    this.views = 0,
    this.quoted,
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final String initials;
  final List<String> tags;
  final int replies;
  final int reposts;
  final int likes;
  final int bookmarks;
  final int views;
  final PostDetailQuote? quoted;
}

class PostDetailQuote {
  const PostDetailQuote({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
}

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.focusComposer = false,
    this.onReplyPosted,
  });

  final PostDetailPayload post;
  final bool focusComposer;
  final VoidCallback? onReplyPosted;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  static const List<List<Color>> _avatarPalettes = <List<Color>>[
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
    [Color(0xFFF97316), Color(0xFFF59E0B)],
    [Color(0xFF10B981), Color(0xFF34D399)],
    [Color(0xFFEC4899), Color(0xFFF472B6)],
    [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
  ];

  late List<XComment> _comments;
  late int _replyCount;

  @override
  void initState() {
    super.initState();
    _comments = _seedComments();
    final seededReplies = _comments.length;
    _replyCount = widget.post.replies > seededReplies
        ? widget.post.replies
        : seededReplies;
  }

  void _handleAddComment(String content) {
    setState(() {
      _replyCount += 1;
      _comments.add(
        XComment(
          id: 'local_${DateTime.now().microsecondsSinceEpoch}',
          author: 'You',
          handle: '@yourprofile',
          timeAgo: 'just now',
          body: content,
          avatarColors: [
            AppTheme.accent.withValues(alpha: 0.65),
            AppTheme.accent,
          ],
        ),
      );
    });
    widget.onReplyPosted?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reply added'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  List<XComment> _seedComments() {
    return <XComment>[
      XComment(
        id: 'c1',
        author: 'Nurse Ada Obi',
        handle: '@ada_clinical',
        timeAgo: '1h',
        body:
            'Love this reminder! We used it last night during handover and shaved 20 minutes off prep.',
        avatarColors: _paletteFor('@ada_clinical'),
        likes: 42,
      ),
      XComment(
        id: 'c1a',
        author: 'Student Grace Uche',
        handle: '@grace_year3',
        timeAgo: '45m',
        body: _withMention(
          '@ada_clinical',
          'Thanks ma! Adding it to my duty planner for this week. Any tip on documenting faster?',
        ),
        avatarColors: _paletteFor('@grace_year3'),
        likes: 11,
      ),
      XComment(
        id: 'c1b',
        author: 'Dr. Malik Musa',
        handle: '@malik_consult',
        timeAgo: '30m',
        body: _withMention(
          '@grace_year3',
          'Grace, draft notes during vitals then finalise before briefing. Works great with this checklist.',
        ),
        avatarColors: _paletteFor('@malik_consult'),
        likes: 19,
      ),
      XComment(
        id: 'c2',
        author: 'Midwife James Duru',
        handle: '@labourcoach',
        timeAgo: '2h',
        body:
            'Great cue for our maternity wing. We pair it with a silent checklist read-out before second stage.',
        avatarColors: _paletteFor('@labourcoach'),
        likes: 37,
      ),
      XComment(
        id: 'c2a',
        author: 'Matron Ijeoma Bello',
        handle: '@ijbello',
        timeAgo: '1h',
        body: _withMention(
          '@labourcoach',
          'James, could you share that silent read-out script? We\'d love to adopt it for night shift.',
        ),
        avatarColors: _paletteFor('@ijbello'),
        likes: 8,
      ),
      XComment(
        id: 'c3',
        author: 'Public Health Team',
        handle: '@communityshield',
        timeAgo: '4h',
        body:
            'Forwarding to our outreach cohort so they add it to the immunisation station setup.',
        avatarColors: _paletteFor('@communityshield'),
        likes: 15,
      ),
    ];
  }

  List<Color> _paletteFor(String seed) {
    final index = seed.hashCode.abs() % _avatarPalettes.length;
    return List<Color>.unmodifiable(_avatarPalettes[index]);
  }

  String _withMention(String? handle, String body) {
    if (handle == null || handle.isEmpty) return body;
    final normalized = handle.startsWith('@')
        ? handle
        : '@${handle.replaceAll(' ', '').toLowerCase()}';
    return '$normalized $body';
  }

  XQuotedPost? get _quotedPost {
    final quote = widget.post.quoted;
    if (quote == null) return null;
    return XQuotedPost(
      author: quote.author,
      handle: quote.handle,
      timeAgo: quote.timeAgo,
      body: quote.body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = XPostMetrics(
      replyCount: _replyCount,
      reposts: widget.post.reposts,
      likes: widget.post.likes,
      bookmarks: widget.post.bookmarks,
      views: widget.post.views,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: XCommentSection(
            postAuthor: widget.post.author,
            postHandle: widget.post.handle,
            postTimeAgo: widget.post.timeAgo,
            postBody: widget.post.body,
            postInitials: widget.post.initials,
            postTags: widget.post.tags,
            quotedPost: _quotedPost,
            metrics: metrics,
            autoFocusComposer: widget.focusComposer,
            comments: _comments,
            onAddComment: _handleAddComment,
          ),
        ),
      ),
    );
  }
}
