part of 'tweet_post_card.dart';

mixin _TweetPostCardActions on _TweetPostCardStateBase {
  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  void _toggleBookmark() {
    setState(() {
      _bookmarked = !_bookmarked;
    });
  }

  void _toggleBookmarkWithToast() {
    setState(() {
      _bookmarked = !_bookmarked;
    });
    _showToast(_bookmarked ? 'Saved' : 'Removed from saved');
  }

  Future<void> _ensureRepostForReply() async {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) {
      return;
    }

    final repo = context.read<PostRepository>();
    final targetId = widget.post.originalId ?? widget.post.id;

    final alreadyReposted = repo.hasUserReposted(targetId, handle);
    if (alreadyReposted) {
      return;
    }

    final toggled = await repo.toggleRepost(
      postId: targetId,
      userHandle: handle,
    );

    if (!mounted || !toggled) return;

    if (widget.post.originalId == null) {
      setState(() {
        _reposts = _reposts + 1;
      });
    }
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
    final toggled = await context.read<PostRepository>().toggleRepost(
      postId: targetId,
      userHandle: handle,
    );
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
    final entry = _toastEntry;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
    _toastEntry = AppToast.showTopOverlay(
      context,
      message,
      duration: widget.toastDuration,
    );
  }

  Future<void> _showReinOptions() async {
    final theme = Theme.of(context);
    final bool repostedByUser = _userHasReposted(
      context.read<PostRepository>(),
    );
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
                            icon: Icons
                                .repeat_rounded, // legacy icon, superseded by XRetweetButton in the metrics row
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
                            icon: Icons.mode_comment_outlined,
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color sheetBg = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFF2F2F2);
    final Color sheetSurface = isDark
        ? theme.colorScheme.surface
        : Colors.white;
    final Color onSurface = theme.colorScheme.onSurface;
    final Border boxBorder = Border.all(
      color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.18),
      width: 1,
    );
    final String rawHandle = widget.post.handle.isNotEmpty
        ? widget.post.handle
        : widget.post.author;
    final String handleLabel = _withAtPrefix(rawHandle);
    final String displayLabel = handleLabel.isEmpty ? 'account' : handleLabel;

    Widget handleRow({
      required BuildContext context,
      required String title,
      required IconData icon,
      Color? textColor,
      Color? iconColor,
      VoidCallback? onTap,
    }) {
      return ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor ?? onSurface,
          ),
        ),
        trailing: Icon(icon, color: iconColor ?? onSurface),
        onTap: onTap == null
            ? null
            : () {
                Navigator.of(context).pop();
                onTap();
              },
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final divider = Divider(
          height: 1,
          thickness: 1.2,
          indent: 18,
          endIndent: 18,
          color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.32),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: boxBorder,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        handleRow(
                          context: sheetContext,
                          title: 'Copy link',
                          icon: Icons.link_rounded,
                          onTap: _copyPostLink,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: boxBorder,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        handleRow(
                          context: sheetContext,
                          title: _bookmarked ? 'Remove bookmark' : 'Save',
                          icon: _bookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          onTap: _toggleBookmarkWithToast,
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Hide',
                          icon: Icons.visibility_off_outlined,
                          onTap: () => _showToast('Hide post (coming soon)'),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: boxBorder,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        handleRow(
                          context: sheetContext,
                          title: 'Mute $displayLabel',
                          icon: Icons.volume_off_outlined,
                          onTap: () =>
                              _showToast('Muted $displayLabel (coming soon)'),
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Restrict $displayLabel',
                          icon: Icons.lock_person_outlined,
                          onTap: () => _showToast(
                            'Restricted $displayLabel (coming soon)',
                          ),
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Block $displayLabel',
                          icon: Icons.block_rounded,
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () =>
                              _showToast('Blocked $displayLabel (coming soon)'),
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Report',
                          icon: Icons.report_gmailerrorred_outlined,
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () => _showToast('Report coming soon'),
                        ),
                      ],
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

  bool _userHasReposted(PostRepository service) {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) return false;
    final targetId = widget.post.originalId ?? widget.post.id;
    return service.hasUserReposted(targetId, handle);
  }

  Future<void> _openReplyComposer() async {
    // Open the same thread view used in profile, focusing the composer
    final repo = context.read<PostRepository>();
    final thread = repo.buildThreadForPost(widget.post.id);
    await Navigator.of(context).push(
      ThreadScreen.route(
        entry: thread,
        currentUserHandle: widget.currentUserHandle,
        initialReplyPostId: widget.post.id,
      ),
    );
    // After returning, refresh reply count from service to reflect potential changes
    if (!mounted) return;
    final updated = repo.buildThreadForPost(widget.post.id).post.replies;
    setState(() => _replies = updated);
  }
}
