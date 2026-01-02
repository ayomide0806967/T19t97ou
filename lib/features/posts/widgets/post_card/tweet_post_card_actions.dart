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

    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color sheetBg = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFF2F2F2);
    final Color sheetSurface = isDark
        ? theme.colorScheme.surface
        : Colors.white;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color iconColor = isDark ? Colors.white : Colors.black;
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

  Future<void> _openOwnPostMoreSheet() async {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color sheetBg = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFF2F2F2);
    final Color sheetSurface = isDark
        ? theme.colorScheme.surface
        : Colors.white;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color iconColor = isDark ? Colors.white : Colors.black;

    Widget tile({
      required BuildContext context,
      required String title,
      required Widget trailing,
      Color? titleColor,
      VoidCallback? onTap,
    }) {
      return ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: titleColor ?? onSurface,
          ),
        ),
        trailing: IconTheme(
          data: IconThemeData(color: iconColor),
          child: trailing,
        ),
        onTap: onTap == null
            ? null
            : () {
                Navigator.of(context).pop();
                onTap();
              },
      );
    }

    Divider divider() => Divider(
          height: 1,
          thickness: 1.1,
          indent: 18,
          endIndent: 18,
          color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.32),
        );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: sheetSurface,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          tile(
                            context: sheetContext,
                            title: 'Save',
                            trailing: Icon(
                              _bookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: iconColor,
                            ),
                            onTap: _toggleBookmarkWithToast,
                          ),
                          divider(),
                          tile(
                            context: sheetContext,
                            title: 'Pin to profile',
                            trailing: Icon(Icons.push_pin_outlined, color: iconColor),
                            onTap: () => _showToast('Pin to profile coming soon'),
                          ),
                          divider(),
                          tile(
                            context: sheetContext,
                            title: 'Archive',
                            trailing: Icon(Icons.history_toggle_off_rounded, color: iconColor),
                            onTap: () => _showToast('Archive coming soon'),
                          ),
                          divider(),
                          tile(
                            context: sheetContext,
                            title: 'Hide like and share counts',
                            trailing: Icon(Icons.heart_broken_outlined, color: iconColor),
                            onTap: () => _showToast('Hide counts coming soon'),
                          ),
                          divider(),
                          tile(
                            context: sheetContext,
                            title: 'Who can reply & quote',
                            trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
                            onTap: () => _showToast('Coming soon'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: sheetSurface,
                      child: tile(
                        context: sheetContext,
                        title: 'Delete',
                        titleColor: Colors.red,
                        trailing: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onTap: () => _showToast('Delete coming soon'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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

  bool _userHasReposted() {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) return false;
    final targetId = widget.post.originalId ?? widget.post.id;
    return ref
        .read(messageThreadControllerProvider.notifier)
        .hasUserReposted(postId: targetId, userHandle: handle);
  }

  Future<void> _openReplyComposer() async {
    // Open the same thread view used in profile, focusing the composer
    await Navigator.of(context).push(
      ThreadScreen.route(
        postId: widget.post.id,
        currentUserHandle: widget.currentUserHandle,
        initialReplyPostId: widget.post.id,
      ),
    );
    // After returning, refresh reply count from service to reflect potential changes
    if (!mounted) return;
    final updated = ref
        .read(messageThreadControllerProvider.notifier)
        .buildThread(widget.post.id)
        .post
        .replies;
    setState(() => _replies = updated);
  }
}
