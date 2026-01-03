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

    // Keep the timeline chronological (append at end) even when replying.
    _threads.add(newNode);

    setState(() {
      _replyTarget = null;
      _composer.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String handle = _currentUserHandle;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double bottomSafeInset = MediaQuery.paddingOf(context).bottom;
    final double bottomBarSpacer =
        (_replyTarget != null ? 210 : 100) + bottomSafeInset;

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.colorScheme.surface,
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
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomBarSpacer),
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
        ],
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyTarget != null)
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
                              color: theme.dividerColor.withValues(alpha: 0.22),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface.withValues(
                                      alpha: theme.brightness == Brightness.dark
                                          ? 0.14
                                          : 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 10, 8, 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 3,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _replyTarget!.comment.author
                                                  .replaceFirst(
                                                RegExp(r'^\\s*@'),
                                                '',
                                              ),
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _replyTarget!.comment.body,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme
                                                  .textTheme.bodyLarge
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withValues(alpha: 0.75),
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
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
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
                                      ),
                                    ],
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
                hintText: _replyTarget == null
                    ? 'Ask a question or share a thought…'
                    : 'Write a reply…',
                onSend: _sendReply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
