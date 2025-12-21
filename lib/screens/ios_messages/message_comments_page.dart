part of '../ios_messages_screen.dart';

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

    final data = context.read<PostRepository>();
    final String targetId = widget.message.id;

    final bool alreadyReposted = data.hasUserReposted(targetId, handle);
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
