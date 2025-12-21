import 'package:flutter/material.dart';

import '../models/thread_entry.dart';
import '../models/post.dart';
import '../core/ui/app_toast.dart';
import '../theme/app_theme.dart';
import '../widgets/tweet_post_card.dart';
import '../widgets/tweet_composer_card.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    required this.entry,
    required this.currentUserHandle,
    this.initialReplyPostId,
  });

  final ThreadEntry entry;
  final String currentUserHandle;
  final String? initialReplyPostId;

  static Route<void> route({
    required ThreadEntry entry,
    required String currentUserHandle,
    String? initialReplyPostId,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 110),
      reverseTransitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (_, __, ___) => ThreadScreen(
        entry: entry,
        currentUserHandle: currentUserHandle,
        initialReplyPostId: initialReplyPostId,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuad,
          reverseCurve: Curves.easeInOutQuad,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  late ThreadEntry _thread;
  ThreadEntry? _replyTarget;

  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _thread = widget.entry;
    final initialTargetId = widget.initialReplyPostId;
    if (initialTargetId != null) {
      _replyTarget = _findEntryById(_thread, initialTargetId) ?? _thread;
      _scheduleFocus();
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ThreadEntry get _activeTarget => _replyTarget ?? _thread;

  String get _composerPlaceholder {
    final handle = _activeTarget.post.handle;
    final normalized = _normalizeHandle(handle);
    return 'Reply to ${normalized}_';
  }

  void _handleReplyTap(ThreadEntry entry) {
    setState(() => _replyTarget = entry);
    _scheduleFocus();
  }

  void _handleSubmit() {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    final ThreadEntry target = _activeTarget;
    final bool replyingToRoot = target.post.id == _thread.post.id;
    final String targetId = target.post.id;
    final ThreadEntry newReply = ThreadEntry(
      post: PostModel(
        id: '${targetId}_local_${DateTime.now().microsecondsSinceEpoch}',
        author: 'You',
        handle: _currentUserHandle(),
        timeAgo: 'just now',
        body: text,
        tags: const <String>[],
        replies: 0,
        reposts: 0,
        likes: 0,
        views: 0,
        bookmarks: 0,
      ),
      replyToHandle: target.post.handle,
    );

    final ThreadEntry updated = _appendReply(_thread, targetId, newReply);

    setState(() {
      _thread = updated;
      _replyTarget = replyingToRoot ? null : _findEntryById(updated, targetId);
      _composerController
        ..clear()
        ..clearComposing();
    });

    _scheduleFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    AppToast.showSnack(
      context,
      'Reply added',
      duration: const Duration(milliseconds: 1200),
    );
  }

  ThreadEntry _appendReply(
    ThreadEntry node,
    String targetId,
    ThreadEntry reply,
  ) {
    if (node.post.id == targetId) {
      final List<ThreadEntry> updatedReplies = List<ThreadEntry>.from(node.replies)
        ..add(reply);
      return node.copyWith(
        post: node.post.copyWith(replies: node.post.replies + 1),
        replies: updatedReplies,
      );
    }

    bool modified = false;
    final List<ThreadEntry> children = <ThreadEntry>[];
    for (final ThreadEntry child in node.replies) {
      final ThreadEntry updatedChild = _appendReply(child, targetId, reply);
      if (!identical(child, updatedChild)) {
        modified = true;
      }
      children.add(updatedChild);
    }

    if (!modified) return node;

    return node.copyWith(replies: children);
  }

  ThreadEntry? _findEntryById(ThreadEntry node, String id) {
    if (node.post.id == id) return node;
    for (final ThreadEntry child in node.replies) {
      final ThreadEntry? result = _findEntryById(child, id);
      if (result != null) return result;
    }
    return null;
  }

  String _currentUserHandle() {
    final handle = widget.currentUserHandle.trim();
    if (handle.isEmpty) return '@you';
    return handle.startsWith('@') ? handle : '@$handle';
  }

  String _normalizeHandle(String handle) {
    if (handle.isEmpty) {
      final String fallback = _thread.post.handle;
      if (fallback.isEmpty) return 'thread';
      return fallback.startsWith('@') ? fallback.substring(1) : fallback;
    }
    return handle.startsWith('@') ? handle.substring(1) : handle;
  }

  void _scheduleFocus() {
    Future<void>.microtask(() {
      if (!mounted) return;
      _composerFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ThreadEntry thread = _thread;

    const double composerReservePadding = 220;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thread'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                composerReservePadding,
              ),
              children: [
                TweetPostCard(
                  post: thread.post,
                  currentUserHandle: widget.currentUserHandle,
                  replyContext: thread.replyToHandle,
                  onTap: null,
                  onReply: (_) => _handleReplyTap(thread),
                  fullWidthHeader: true,
                ),
                const SizedBox(height: 24),
                if (thread.replies.isEmpty)
                  _EmptyThreadState(handle: thread.post.handle)
                else
                  ..._buildReplies(thread.replies, 0),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildComposer(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReplies(List<ThreadEntry> replies, int depth) {
    final List<Widget> widgets = <Widget>[];
    for (final ThreadEntry reply in replies) {
      widgets.add(
        ThreadReplyTile(
          entry: reply,
          depth: depth,
          currentUserHandle: widget.currentUserHandle,
          onReplyTap: _handleReplyTap,
        ),
      );
      if (reply.replies.isNotEmpty) {
        widgets.addAll(_buildReplies(reply.replies, depth + 1));
      }
    }
    return widgets;
  }

  Widget _buildComposer(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color containerColor =
        isDark ? const Color(0xFFF4F1EC) : Colors.white;
    final String? replyHandle = _replyTarget == null
        ? null
        : _normalizeHandle(_replyTarget!.post.handle);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: TweetComposerCard(
            controller: _composerController,
            focusNode: _composerFocusNode,
            replyingTo: replyHandle,
            hintText: _composerPlaceholder,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            backgroundColor: containerColor,
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
            onSubmit: (_) => _handleSubmit(),
            onImageTap: () => AppToast.showSnack(
              context,
              'Attach image coming soon',
              duration: const Duration(milliseconds: 1200),
            ),
            onGifTap: () => AppToast.showSnack(
              context,
              'GIF library coming soon',
              duration: const Duration(milliseconds: 1200),
            ),
            textInputAction: TextInputAction.send,
          ),
        ),
      ),
    );
  }
}

class ThreadReplyTile extends StatelessWidget {
  const ThreadReplyTile({
    super.key,
    required this.entry,
    required this.depth,
    required this.currentUserHandle,
    required this.onReplyTap,
  });

  final ThreadEntry entry;
  final int depth;
  final String currentUserHandle;
  final ValueChanged<ThreadEntry> onReplyTap;

  Color _replyBackground(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.08);
    }
    return const Color(0xFFF6EDE4);
  }

  Color _replyCorner(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.12);
    }
    return const Color(0xFFE0CDBC);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String replyTo = entry.replyToHandle ?? entry.post.handle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TweetPostCard(
                post: entry.post,
                currentUserHandle: currentUserHandle,
                replyContext: replyTo,
                backgroundColor: _replyBackground(theme),
                cornerAccentColor: _replyCorner(theme),
                showCornerAccent: false,
                showRepostBanner: true,
                onReply: (_) => onReplyTap(entry),
                onTap: () {
                  Navigator.of(context).push(
                    ThreadScreen.route(
                      entry: entry,
                      currentUserHandle: currentUserHandle,
                      initialReplyPostId: entry.post.id,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _EmptyThreadState extends StatelessWidget {
  const _EmptyThreadState({required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Be the first to reply',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with $handle.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
