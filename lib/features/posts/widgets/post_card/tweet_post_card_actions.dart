part of 'tweet_post_card.dart';

mixin _TweetPostCardActions on _TweetPostCardStateBase {
  bool _isOwnPost() {
    final my = _withAtPrefix(widget.currentUserHandle).toLowerCase();
    final postHandle = _withAtPrefix(widget.post.handle).toLowerCase();
    if (my.isNotEmpty && postHandle.isNotEmpty) {
      return my == postHandle;
    }
    // Fallbacks for local/demo content.
    if (widget.post.author.trim().toLowerCase() == 'you') return true;
    return false;
  }

  void _toggleLike() {
    unawaited(_toggleLikeViaRepository());
  }

  Future<void> _toggleLikeViaRepository() async {
    final repo = ref.read(postRepositoryProvider);
    final targetId = widget.post.originalId ?? widget.post.id;

    final optimisticLiked = !_liked;
    setState(() {
      _liked = optimisticLiked;
      _likes += optimisticLiked ? 1 : -1;
    });

    try {
      final nowLiked = await repo.toggleLike(targetId);
      if (!mounted) return;

      if (nowLiked != _liked) {
        setState(() {
          _liked = nowLiked;
          _likes += nowLiked ? 1 : -1;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = !optimisticLiked;
        _likes += optimisticLiked ? -1 : 1;
      });
      _showToast('Like failed');
    }
  }

  void _toggleBookmark() {
    unawaited(_toggleBookmarkViaRepository(showToast: false));
  }

  void _toggleBookmarkWithToast() {
    unawaited(_toggleBookmarkViaRepository(showToast: true));
  }

  Future<void> _toggleBookmarkViaRepository({required bool showToast}) async {
    final repo = ref.read(postRepositoryProvider);
    final targetId = widget.post.originalId ?? widget.post.id;

    final optimistic = !_bookmarked;
    setState(() => _bookmarked = optimistic);

    try {
      final nowBookmarked = await repo.toggleBookmark(targetId);
      if (!mounted) return;
      setState(() => _bookmarked = nowBookmarked);
      if (showToast) {
        _showToast(nowBookmarked ? 'Bookmark saved' : 'Bookmark removed');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookmarked = !optimistic);
      if (showToast) {
        _showToast('Bookmark failed');
      }
    }
  }

  Future<void> _ensureRepostForReply() async {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) {
      return;
    }
    final targetId = widget.post.originalId ?? widget.post.id;
    await ref
        .read(messageThreadControllerProvider.notifier)
        .ensureRepostForReply(postId: targetId, userHandle: handle);
  }

  Future<void> _performReinstitute() async {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) {
      if (widget.showRepostToast) {
        _showToast('Sign in to repost.');
      }
      return;
    }
    final targetId = widget.post.originalId ?? widget.post.id;
    final toggled = await ref
        .read(messageThreadControllerProvider.notifier)
        .toggleRepost(postId: targetId, userHandle: handle);
    if (!mounted) return;
    if (widget.showRepostToast) {
      _showToast(toggled ? 'Reposted!' : 'Removed repost');
    }
    setState(() {
      if (widget.post.originalId == null) {
        _reposts = toggled ? _reposts + 1 : (_reposts - 1).clamp(0, 1 << 30);
      }
    });
  }

  void _handleReinPressed() {
    unawaited(_showReinOptions());
  }

  void _incrementView() {
    setState(() => _views += 1);
  }

  void _showToast(String message) {
    if (!mounted) return;
    AppToast.showTopOverlay(
      context,
      message,
      duration: widget.toastDuration,
    );
  }

  Future<void> _showReinOptions() async {
    final theme = Theme.of(context);
    final bool repostedByUser = _userHasReposted();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bool isDark = theme.brightness == Brightness.dark;
        final Color surface = theme.colorScheme.surface.withValues(
          alpha: isDark ? 0.92 : 0.96,
        );
        final Color border = Colors.white.withValues(
          alpha: isDark ? 0.12 : 0.25,
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ReinOptionTile(
                            // Use the same X-style repost icon as in the metrics row
                            icon: const XRetweetIcon(size: 20),
                            label: repostedByUser ? 'Undo repost' : 'Repost',
                            description: repostedByUser
                                ? 'Remove your repost'
                                : 'Share this post with your network',
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              await _performReinstitute();
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: theme.dividerColor.withValues(alpha: 0.16),
                          ),
                          _ReinOptionTile(
                            // Use the same X-style comment icon as in the metrics row
                            icon: const XCommentIcon(size: 18),
                            label: 'Quote',
                            description: 'Add a comment before you share',
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _openQuoteComposer();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
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

  Future<void> _copyPostLink() async {
    final link = 'https://academicnightingale.app/post/${widget.post.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    _showToast('Link copied');
  }

  Future<void> _openPostMoreSheet() async {
    if (_isOwnPost()) {
      await _openOwnPostMoreSheet();
      return;
    }

    final String rawHandle = widget.post.handle.isNotEmpty
        ? widget.post.handle
        : widget.post.author;
    final String handleLabel = _withAtPrefix(rawHandle);
    final String displayLabel = handleLabel.isEmpty ? 'account' : handleLabel;
    await AppActionSheet.show(
      context,
      sections: [
        AppActionSheetSection([
          AppActionSheetItem(
            title: 'Copy link',
            trailingIcon: Icons.link_rounded,
            onTap: _copyPostLink,
          ),
        ]),
        AppActionSheetSection([
          AppActionSheetItem(
            title: _bookmarked ? 'Remove bookmark' : 'Save',
            trailingIcon: _bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            onTap: _toggleBookmarkWithToast,
          ),
          AppActionSheetItem(
            title: 'Hide',
            trailingIcon: Icons.visibility_off_outlined,
            onTap: () => _showToast('Hide post (coming soon)'),
          ),
        ]),
        AppActionSheetSection([
          AppActionSheetItem(
            title: 'Mute $displayLabel',
            trailingIcon: Icons.volume_off_outlined,
            onTap: () => _showToast('Muted $displayLabel (coming soon)'),
          ),
          AppActionSheetItem(
            title: 'Restrict $displayLabel',
            trailingIcon: Icons.lock_person_outlined,
            onTap: () => _showToast('Restricted $displayLabel (coming soon)'),
          ),
          AppActionSheetItem(
            title: 'Block $displayLabel',
            trailingIcon: Icons.block_rounded,
            destructive: true,
            onTap: () => _showToast('Blocked $displayLabel (coming soon)'),
          ),
          AppActionSheetItem(
            title: 'Report',
            trailingIcon: Icons.report_gmailerrorred_outlined,
            destructive: true,
            onTap: () => _showToast('Report coming soon'),
          ),
        ]),
      ],
    );
  }

  Future<void> _openOwnPostMoreSheet() async {
    await AppActionSheet.show(
      context,
      sections: [
        AppActionSheetSection([
          AppActionSheetItem(
            title: 'Save',
            trailingIcon: _bookmarked ? Icons.bookmark : Icons.bookmark_border,
            onTap: _toggleBookmarkWithToast,
          ),
          AppActionSheetItem(
            title: 'Pin to profile',
            trailingIcon: Icons.push_pin_outlined,
            onTap: () => _showToast('Pin to profile coming soon'),
          ),
          AppActionSheetItem(
            title: 'Archive',
            trailingIcon: Icons.history_toggle_off_rounded,
            onTap: () => _showToast('Archive coming soon'),
          ),
          AppActionSheetItem(
            title: 'Hide like and share counts',
            trailingIcon: Icons.heart_broken_outlined,
            onTap: () => _showToast('Hide counts coming soon'),
          ),
          AppActionSheetItem(
            title: 'Who can reply & quote',
            trailingIcon: Icons.chevron_right_rounded,
            onTap: () => _showToast('Coming soon'),
          ),
        ]),
        AppActionSheetSection([
          AppActionSheetItem(
            title: 'Delete',
            trailingIcon: Icons.delete_outline,
            destructive: true,
            onTap: _confirmAndDeletePost,
          ),
        ]),
      ],
    );
  }

  Future<void> _openQuoteComposer() async {
    final post = widget.post;
    final initials = _initialsFrom(post.author);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuoteScreen(
          author: post.author,
          handle: post.handle,
          timeAgo: post.timeAgo,
          body: post.body,
          initials: initials,
          tags: post.tags,
        ),
      ),
    );
  }

  Future<void> _confirmAndDeletePost() async {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color onSurface = theme.colorScheme.onSurface;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete post?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          content: Text(
            'This can’t be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(postRepositoryProvider).deletePost(postId: widget.post.id);
      if (!mounted) return;
      _showToast('Post deleted');
    } catch (e) {
      if (!mounted) return;
      _showToast('Could not delete post');
    }
  }

  bool _userHasReposted() {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) return false;
    final targetId = widget.post.originalId ?? widget.post.id;
    return ref
        .read(messageThreadControllerProvider.notifier)
        .hasUserReposted(postId: targetId, userHandle: handle);
  }

  Future<void> _openReplyComposer() async {
    await Navigator.of(context).push(
      messageRepliesRouteFromPost(
        post: widget.post,
        currentUserHandle: widget.currentUserHandle,
      ),
    );
  }
}
