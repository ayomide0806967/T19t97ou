part of '../ios_messages_screen.dart';

/// Shared "chat-style" discussion thread UI used by the class note stepper.
class ClassDiscussionThreadPage extends ConsumerStatefulWidget {
  const ClassDiscussionThreadPage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  ConsumerState<ClassDiscussionThreadPage> createState() =>
      _ClassDiscussionThreadPageState();
}

class _ClassDiscussionThreadPageState
    extends ConsumerState<ClassDiscussionThreadPage> {
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
    return ref.read(currentUserHandleProvider);
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
                              RegExp(r'^\\s*@'),
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
                  : 'Replying to ${_replyTarget!.comment.author.replaceFirst(RegExp(r'^\\s*@'), '')}',
              onSend: _sendReply,
            ),
          ),
        ],
      ),
    );
  }
}
