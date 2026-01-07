part of '../ios_messages_screen.dart';

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.isDark,
    required this.currentUserHandle,
    this.onSwipeReply,
    this.onMore,
    this.selected = false,
    this.onLongPress,
    this.onTap,
  });
  final _ThreadComment comment;
  final bool isDark;
  final String currentUserHandle;
  final VoidCallback? onSwipeReply;
  final VoidCallback? onMore;
  final bool selected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

abstract class _CommentTileStateBase extends State<_CommentTile> {
  double _dx = 0;
  double _dragOffset = 0; // visual slide during swipe-to-reply
  bool _swipeHapticFired = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _CommentTileState extends _CommentTileStateBase
    with _CommentTileBuild {}
