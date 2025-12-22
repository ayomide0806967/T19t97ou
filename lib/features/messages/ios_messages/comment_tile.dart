part of '../ios_messages_screen.dart';

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

abstract class _CommentTileStateBase extends State<_CommentTile> {
  // Track which comment currently shows inline repost actions so only one is open.
  static _CommentTileStateBase? _openRepostTile;

  double _dx = 0;
  double _dragOffset = 0; // visual slide during swipe-to-reply
  bool _reposted = false;
  int _reposts = 0;
  bool _swipeHapticFired = false;
  bool _showRepostActions = false;
  final Map<String, int> _reactions = <String, int>{};
  String? _currentUserReaction;

  @override
  void initState() {
    super.initState();
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
}

class _CommentTileState extends _CommentTileStateBase
    with _CommentTileActions, _CommentTileBuild {}
