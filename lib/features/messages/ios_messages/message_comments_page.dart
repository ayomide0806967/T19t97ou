part of '../ios_messages_screen.dart';

// Repost now rendered as text label "repost"

class _MessageCommentsPage extends ConsumerStatefulWidget {
  const _MessageCommentsPage({
    required this.message,
    required this.currentUserHandle,
  });

  final _ClassMessage message;
  final String currentUserHandle;

  @override
  ConsumerState<_MessageCommentsPage> createState() =>
      _MessageCommentsPageState();
}

class _MessageCommentsPageState extends ConsumerState<_MessageCommentsPage> {
  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  String? _replyTargetCommentId;
  List<Comment> _comments = const <Comment>[];
  StreamSubscription<List<Comment>>? _commentsSub;
  Object? _commentsError;
  bool _commentsLoading = true;
  bool _composerVisible = true; // Keep composer open by default on comments
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _subscribeToComments();
  }

  @override
  void dispose() {
    _composer.dispose();
    _composerFocusNode.dispose();
    _commentsSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MessageCommentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _subscribeToComments();
    }
  }

  void _subscribeToComments() {
    _commentsSub?.cancel();
    setState(() {
      _commentsLoading = true;
      _commentsError = null;
      _comments = const <Comment>[];
      _replyTargetCommentId = null;
      _selected.clear();
    });

    _commentsSub = ref
        .read(commentRepositoryProvider)
        .watchComments(widget.message.id)
        .listen(
          (comments) {
            if (!mounted) return;
            setState(() {
              _comments = comments;
              _commentsLoading = false;
              _commentsError = null;
            });
          },
          onError: (e) {
            if (!mounted) return;
            setState(() {
              _commentsError = e;
              _commentsLoading = false;
            });
          },
        );
  }

  static String _withAt(String handle) {
    final h = handle.trim();
    if (h.isEmpty) return '';
    return h.startsWith('@') ? h : '@$h';
  }

  List<_ThreadNode> _buildThreadNodes(List<Comment> comments) {
    final Map<String, _ThreadNode> byId = <String, _ThreadNode>{};

    for (final c in comments) {
      byId[c.id] = _ThreadNode(
        comment: _ThreadComment(
          id: c.id,
          authorName: c.authorName,
          authorHandle: _withAt(c.authorHandle),
          body: c.body,
          createdAt: c.createdAt,
          likes: c.likes,
          isLiked: c.isLiked,
          parentCommentId: c.parentCommentId,
        ),
      );
    }

    final List<_ThreadNode> roots = <_ThreadNode>[];
    for (final node in byId.values) {
      final parentId = node.comment.parentCommentId;
      if (parentId != null && byId.containsKey(parentId)) {
        byId[parentId]!.children.add(node);
      } else {
        roots.add(node);
      }
    }

    void sortNode(_ThreadNode n) {
      n.children.sort(
        (a, b) => a.comment.createdAt.compareTo(b.comment.createdAt),
      );
      for (final c in n.children) {
        sortNode(c);
      }
    }

    roots.sort((a, b) => a.comment.createdAt.compareTo(b.comment.createdAt));
    for (final r in roots) {
      sortNode(r);
    }
    return roots;
  }

  _ThreadNode? _findNodeById(List<_ThreadNode> nodes, String id) {
    for (final n in nodes) {
      if (n.comment.id == id) return n;
      final found = _findNodeById(n.children, id);
      if (found != null) return found;
    }
    return null;
  }

  Iterable<_ThreadNode> _flatten(List<_ThreadNode> nodes) sync* {
    for (final n in nodes) {
      yield n;
      yield* _flatten(n.children);
    }
  }

  Future<void> _ensureRepostForReply() async {
    final handle = widget.currentUserHandle.trim();
    if (handle.isEmpty) return;

    await ref
        .read(messageThreadControllerProvider.notifier)
        .ensureRepostForReply(
          postId: widget.message.id,
          userHandle: handle,
        );
  }

  void _setReplyTarget(_ThreadNode node) {
    setState(() {
      _replyTargetCommentId = node.comment.id;
      _composerVisible = true;
    });
    // Bring up keyboard for quick reply
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _composerFocusNode.requestFocus();
      }
    });
  }

  Future<void> _sendReply() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;

    // Ensure replying also surfaces the post on the global feed as a repost.
    _ensureRepostForReply();

    final parentId = _replyTargetCommentId;
    setState(() {
      _replyTargetCommentId = null;
      _composer.clear();
    });

    try {
      await ref.read(commentRepositoryProvider).addComment(
            postId: widget.message.id,
            body: text,
            parentCommentId: parentId,
          );
      if (!mounted) return;
      AppToast.showTopOverlay(
        context,
        'Comment sent',
        duration: ToastDurations.standard,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showTopOverlay(
        context,
        'Failed to send comment',
        duration: ToastDurations.standard,
      );
    }
  }

  void _openCommentMoreSheet(_ThreadNode node) {
    final String currentHandle = widget.currentUserHandle.trim();
    String handleKey(String h) =>
        h.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    final bool isMine = currentHandle.isNotEmpty &&
        handleKey(node.comment.authorHandle) == handleKey(currentHandle);

    Future<void> copyText() async {
      await Clipboard.setData(ClipboardData(text: node.comment.body));
      if (!mounted) return;
      AppToast.showTopOverlay(
        context,
        'Copied',
        duration: ToastDurations.standard,
      );
    }

    Future<void> deleteComment() async {
      try {
        await ref
            .read(commentRepositoryProvider)
            .deleteComment(node.comment.id);
        if (!mounted) return;
        setState(() {
          _selected.remove(node.comment.id);
          if (_replyTargetCommentId == node.comment.id) {
            _replyTargetCommentId = null;
          }
        });
        AppToast.showTopOverlay(
          context,
          'Comment deleted',
          duration: ToastDurations.standard,
        );
      } catch (e) {
        if (!mounted) return;
        AppToast.showTopOverlay(
          context,
          'Failed to delete comment',
          duration: ToastDurations.standard,
        );
      }
    }

    AppActionSheet.show(
      context,
      sections: [
        AppActionSheetSection([
          AppActionSheetItem(
            title: 'Copy',
            trailingIcon: Icons.copy_rounded,
            onTap: copyText,
          ),
          AppActionSheetItem(
            title: 'Reply',
            trailingIcon: Icons.reply_rounded,
            onTap: () => _setReplyTarget(node),
          ),
          if (isMine)
            AppActionSheetItem(
              title: 'Delete',
              trailingIcon: Icons.delete_outline,
              destructive: true,
              onTap: deleteComment,
            ),
        ]),
      ],
    );
  }

  void _toggleSelection(String commentId) {
    setState(() {
      if (_selected.contains(commentId)) {
        _selected.remove(commentId);
      } else {
        _selected.add(commentId);
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
    final String targetId = _selected.first;
    final nodes = _buildThreadNodes(_comments);
    final target = _findNodeById(nodes, targetId);
    if (target != null) {
      _setReplyTarget(target);
    }
  }

  void _showInfoForSelected() {
    if (_selected.isEmpty) return;
    final theme = Theme.of(context);
    final int count = _selected.length;
    final nodes = _buildThreadNodes(_comments);
    final Map<String, _ThreadNode> map = <String, _ThreadNode>{};
    for (final n in _flatten(nodes)) {
      map[n.comment.id] = n;
    }
    final preview = _selected
        .take(3)
        .map((id) {
          final n = map[id];
          if (n == null) return '• (deleted)';
          final author = n.comment.authorName.isNotEmpty
              ? n.comment.authorName
              : n.comment.authorHandle;
          return '• $author: ${n.comment.body}';
        })
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
              final ids = _selected.toList(growable: false);
              setState(() => _selected.clear());
              for (final id in ids) {
                ref.read(commentRepositoryProvider).deleteComment(id);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _forwardSelected() async {
    if (_selected.isEmpty) return;
    final nodes = _buildThreadNodes(_comments);
    final Map<String, _ThreadNode> map = <String, _ThreadNode>{};
    for (final n in _flatten(nodes)) {
      map[n.comment.id] = n;
    }
    final text = _selected
        .map((id) => map[id])
        .whereType<_ThreadNode>()
        .map((n) {
          final author = n.comment.authorName.isNotEmpty
              ? n.comment.authorName
              : n.comment.authorHandle;
          return '$author: ${n.comment.body}';
        })
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
                final nodes = _buildThreadNodes(_comments);
                setState(() {
                  _selected
                    ..clear()
                    ..addAll(_flatten(nodes).map((n) => n.comment.id));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool selectionMode = _selected.isNotEmpty;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double bottomSafeInset = MediaQuery.paddingOf(context).bottom;
    final bool showBottomBar =
        _replyTargetCommentId != null || _composerVisible;
    final double bottomBarSpacer = showBottomBar
        ? (_replyTargetCommentId != null ? 210 : 100) + bottomSafeInset
        : bottomSafeInset;
    final List<_ThreadNode> nodes = _buildThreadNodes(_comments);
    final _ThreadNode? replyTarget = _replyTargetCommentId != null
        ? _findNodeById(nodes, _replyTargetCommentId!)
        : null;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: theme.colorScheme.surface,
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomBarSpacer),
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
              final Color divider = theme.colorScheme.onSurface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.28 : 0.12,
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Top',
                              style: theme.textTheme.titleMedium?.copyWith(
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
                              reposts: 0,
                              likes: widget.message.likes,
                              views: 0,
                              bookmarks: 0,
                            );
                            Navigator.of(context).push(
                              PostActivityScreen.route(post: post),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View activity',
                                style: theme.textTheme.bodyMedium?.copyWith(
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
          if (_commentsLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_commentsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  'Failed to load replies',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
          _ThreadCommentsView(
            nodes: nodes,
            currentUserHandle: widget.currentUserHandle,
            onReply: _setReplyTarget,
            onMore: _openCommentMoreSheet,
            selectionMode: selectionMode,
            selected: _selected,
            onToggleSelect: _toggleSelection,
          ),
        ],
      ),
      bottomNavigationBar: showBottomBar
          ? Padding(
              padding: EdgeInsets.only(bottom: keyboardInset),
	              child: SafeArea(
	                top: false,
	                minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyTarget != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  10,
                                  6,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onSurface
                                              .withValues(
                                            alpha: theme.brightness ==
                                                    Brightness.dark
                                                ? 0.14
                                                : 0.06,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          10,
                                          8,
                                          10,
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Container(
                                                width: 3,
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      (replyTarget.comment
                                                                  .authorName
                                                                  .isNotEmpty
                                                              ? replyTarget
                                                                  .comment
                                                                  .authorName
                                                              : replyTarget
                                                                  .comment
                                                                  .authorHandle)
                                                          .replaceFirst(
                                                        RegExp(r'^\\s*@'),
                                                        '',
                                                      ),
                                                      style: theme.textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      replyTarget.comment.body,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme
                                                          .textTheme.bodyLarge
                                                          ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.75,
                                                            ),
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 32,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close),
                                                  iconSize: 18,
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 32,
                                                    minHeight: 32,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _replyTargetCommentId =
                                                          null;
                                                      _composerVisible = true;
                                                    });
                                                    _composer
                                                      ..clear()
                                                      ..clearComposing();
                                                    _composerFocusNode.unfocus();
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 56),
                          ],
                        ),
                      ),
                    _ClassComposer(
                      controller: _composer,
                      focusNode: _composerFocusNode,
                      hintText: 'Write a reply…',
	                      onSend: _sendReply,
	                    ),
	                  ],
	                ),
	              ),
            )
          : null,
    );
  }
}
