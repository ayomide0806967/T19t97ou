part of 'x_comment_section.dart';

mixin _XCommentSectionBuild
    on _XCommentSectionStateBase, _XCommentSectionActions {
  Widget _buildPostActionRow(ThemeData theme) {
    final metrics = widget.metrics;

    Widget action(IconData icon, {String? label, Widget? customIcon}) {
      return _XActionButton(
        icon: icon,
        customIcon: customIcon,
        label: label,
        onTap: () {},
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: _XActionButton(
                icon: Icons.chat_outlined,
                label: 'View replies',
                onTap: () {},
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(4, 0),
                    child: action(
                      Icons.repeat_rounded,
                      customIcon: const XRetweetIconMinimal(size: 20),
                      label: metrics != null
                          ? _formatCount(metrics.reposts)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _XActionButton(
                    icon: Icons.favorite_border_rounded,
                    label: metrics != null ? _formatCount(metrics.likes) : null,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Center(child: action(Icons.bookmark_border_rounded))),
          Expanded(child: Center(child: action(Icons.send_rounded))),
        ],
      ),
    );
  }

  Widget _buildPrimaryPost(ThemeData theme, bool isDark, String replyHandle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      (widget.postInitials != null &&
                          widget.postInitials!.isNotEmpty)
                      ? Text(
                          widget.postInitials!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        )
                      : const Icon(Icons.person, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.postAuthor,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          replyHandle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '·',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.postTimeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Replying to $replyHandle',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.postBody.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.postBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
          if (widget.quotedPost != null) ...[
            const SizedBox(height: 16),
            _XQuotedPostCard(quoted: widget.quotedPost!),
          ],
          if (widget.postTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.postTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      backgroundColor: AppTheme.accent.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (widget.metrics != null) ...[
            const SizedBox(height: 16),
            Text(
              '${widget.postTimeAgo} · ${_formatCount(widget.metrics!.views)} Views',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 0.6,
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            _XMetricsRow(metrics: widget.metrics!),
            const SizedBox(height: 14),
            _buildPostActionRow(theme),
          ],
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildMostRelevantHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              'Most relevant replies',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  SliverFillRemaining _buildEmptyRepliesState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to reply',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final replyHandle = widget.postHandle.startsWith('@')
        ? widget.postHandle
        : '@${widget.postHandle.toLowerCase().replaceAll(' ', '')}';

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Header - X style
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Post',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content (post + replies)
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildPrimaryPost(theme, isDark, replyHandle),
                    ),
                    if (widget.comments.isNotEmpty)
                      _buildMostRelevantHeader(theme),
                    if (widget.comments.isEmpty)
                      _buildEmptyRepliesState(theme)
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: _XCommentTile(
                              comment: widget.comments[index],
                              onReply: () => _startReply(
                                widget.comments[index].id,
                                widget.comments[index].author,
                              ),
                              onLike: () {
                                setState(() {
                                  widget.comments[index].isLiked =
                                      !widget.comments[index].isLiked;
                                  widget.comments[index].likes +=
                                      widget.comments[index].isLiked ? 1 : -1;
                                });
                              },
                            ),
                          ),
                          childCount: widget.comments.length,
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                  ],
                ),
              ),

              // Reply composer - WhatsApp-inspired UI
              Container(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111B21)
                      : const Color(0xFFF0F2F5),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isReplying && _replyingTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        // Outer stays white like the composer background
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 3,
                              height: 24,
                              decoration: const BoxDecoration(
                                // Rounded black line, similar to WhatsApp
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                // Inner grey pill, WhatsApp-style
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: isDark ? 0.22 : 0.07,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 220),
                                    child: Text(
                                      'Replying to ${_replyingTo!.startsWith('@') ? _replyingTo! : '@$_replyingTo'}',
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(
                                          alpha: isDark ? 0.9 : 0.8,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (_isReplying)
                                    GestureDetector(
                                      onTap: _cancelReply,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: theme.colorScheme.onSurface
                                              .withValues(
                                            alpha: isDark ? 0.9 : 0.75,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emoji_emotions_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    focusNode: _inputFocusNode,
                                    minLines: 1,
                                    maxLines: 3,
                                    textInputAction: TextInputAction.newline,
                                    keyboardType: TextInputType.multiline,
                                    onSubmitted: (_) => _submitComment(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.25,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Write a reply...',
                                      hintStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.4),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _commentController.text.trim().isNotEmpty
                              ? _submitComment
                              : null,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                _commentController.text.trim().isNotEmpty
                                ? AppTheme.accent
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
