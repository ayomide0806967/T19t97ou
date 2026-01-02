part of 'tweet_post_card.dart';

mixin _TweetPostCardBuild on _TweetPostCardStateBase, _TweetPostCardActions {
  Widget _buildRepostBanner({
    required ThemeData theme,
    required Color textColor,
  }) {
    final repostedBy = widget.post.repostedBy;
    if (repostedBy == null || repostedBy.isEmpty) {
      return const SizedBox.shrink();
    }

    final normalizedBy = _withAtPrefix(repostedBy);
    final normalizedCurrent = _withAtPrefix(widget.currentUserHandle);
    final label =
        (normalizedCurrent.isNotEmpty && normalizedBy == normalizedCurrent)
        ? 'You reposted'
        : '$normalizedBy reposted';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const XRetweetIconMinimal(size: 14, color: Color(0xFF00BA7C)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repostedByUser = _userHasReposted();
    // Repost highlighting is currently disabled; no special casing needed.
    final Color? cardBackground = widget.backgroundColor;
    final bool usesLightCardOnDarkTheme =
        theme.brightness == Brightness.dark &&
        cardBackground != null &&
        cardBackground == cardBackground.withValues(alpha: 1.0) &&
        ThemeData.estimateBrightnessForColor(cardBackground) ==
            Brightness.light;
    final Color primaryTextColor = usesLightCardOnDarkTheme
        ? AppTheme.textPrimary
        : theme.colorScheme.onSurface;
    final Color secondaryTextColor = usesLightCardOnDarkTheme
        ? AppTheme.textSecondary
        : (theme.textTheme.bodyMedium?.color ??
              theme.colorScheme.onSurface.withValues(alpha: 0.7));
    // Use the same blue-gray as metrics for the action button
    const Color controlIconColor = Color(0xFF4B6A88);

    // Build metric data (no fake counts for new posts)
    int repliesCount = _replies;
    int repostsCount =
        widget.post.originalId == null ? _reposts : widget.post.reposts;
    int viewsCount = _views;

    final reply = TweetMetricData(
      type: TweetMetricType.reply,
      // Rounded, ball-like chat bubble with left-facing tail
      icon: Icons.chat_bubble_outline_rounded,
      count: repliesCount,
    );
    final rein = TweetMetricData(
      type: TweetMetricType.rein,
      icon: Icons.repeat_rounded, // visual handled by XRetweetButton
      label: 'new retweet',
      count: repostsCount,
      isActive: repostedByUser,
    );
    final like = TweetMetricData(
      type: TweetMetricType.like,
      icon: _liked ? Icons.favorite : Icons.favorite_border,
      count: _likes,
      isActive: _liked,
    );
    final bookmark = TweetMetricData(
      type: TweetMetricType.bookmark,
      icon: _bookmarked ? Icons.bookmark : Icons.bookmark_border,
      isActive: _bookmarked,
    );
    const share = TweetMetricData(
      type: TweetMetricType.share,
      icon: Icons.near_me_outlined,
    );

    // Left group fills remaining width; order: Comment, Repost (middle), Like
    // Bookmark moves to right edge with share
    final leftMetrics = [reply, rein, like];

    // Auto-compact based on screen width and total items (6)
    final screenW = MediaQuery.of(context).size.width;
    final items = leftMetrics.length + 1; // +1 for share
    final isCompact = (screenW / items) < 80;

    final List<Widget> header = [];
    if (widget.showRepostBanner && widget.post.repostedBy != null) {
      header.add(
        _buildRepostBanner(theme: theme, textColor: secondaryTextColor),
      );
    }
    if (widget.replyContext != null) {
      header.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TagChip('Replying to ${widget.replyContext}'),
        ),
      );
    }
    // Repost banner is optional (enabled per screen).

    // Build header content (author row) without the avatar.
    final Widget contentHeader;
    if (widget.fullWidthHeader) {
      // Replies page / detail: name on first line, optional time beneath.
      contentHeader = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        widget.post.author,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.showTimeInHeader) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.post.timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    } else {
      // Main timeline: name + time on a single horizontal line (handle hidden).
      contentHeader = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    widget.post.author,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                    ),
                  ),
                ),
                if (widget.showTimeInHeader) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· ${widget.post.timeAgo}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Final timeline row layout: avatar on left, content card on right.
    final double avatarGap = 6; // slightly tighter gap
    final String handleForProfile = () {
      if (widget.post.handle.isNotEmpty) return widget.post.handle;
      if (widget.post.repostedBy != null &&
          widget.post.repostedBy!.isNotEmpty) {
        return widget.post.repostedBy!;
      }
      return widget.currentUserHandle;
    }();

    final Widget avatar = InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        final String normalizedHandle = handleForProfile.startsWith('@')
            ? handleForProfile
            : '@$handleForProfile';
        Navigator.of(context).push(AppNav.userProfile(normalizedHandle));
      },
      child: HexagonAvatar(
        size: 48,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        borderColor: theme.colorScheme.primary.withValues(alpha: 0.35),
        borderWidth: 1.5,
        child: Center(
          child: Text(
            _initialsFrom(widget.post.author),
            style: theme.textTheme.labelLarge?.copyWith(
              color: primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    // Simple flag to enable demo media carousel for certain posts.
    final bool hasDemoMedia = widget.post.tags.any(
      (t) => t.toLowerCase() == 'gallery',
    );
    final bool hasMedia = widget.post.mediaPaths.isNotEmpty;

    // Build the tweet body column for the standard (timeline) layout.
    final Widget tappableContentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...header,
        contentHeader,
        const SizedBox(height: 2),
        if (widget.post.body.isNotEmpty)
          Text(
            widget.post.body,
            style: AppTheme.tweetBody(primaryTextColor),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
            ),
          ),
        if (hasMedia) ...[
          const SizedBox(height: 10),
          _PostMediaGrid(paths: widget.post.mediaPaths),
        ],
        if (hasDemoMedia) ...[
          const SizedBox(height: 10),
          _TweetMediaCarousel(),
        ],
        if (widget.post.quoted != null) ...[
          const SizedBox(height: 6),
          QuotePreview(snapshot: widget.post.quoted!),
        ],
      ],
    );

    final Widget metricsSection = !widget.showActions
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _buildMetricsRow(
                theme: theme,
                leftMetrics: leftMetrics,
                bookmark: bookmark,
                share: share,
                isCompact: isCompact,
                onSurfaceColor: primaryTextColor,
                forceContrast: usesLightCardOnDarkTheme,
                actionIconColor: controlIconColor,
              ),
            ],
          );

    // Special full-width header layout used on the thread/comments page:
    // avatar + name row on top, tweet body running full width beneath.
    if (widget.fullWidthHeader) {
      Widget fullWidthHeaderContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              SizedBox(width: avatarGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [...header, contentHeader],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.post.body.isNotEmpty)
            Text(
              widget.post.body,
              style: AppTheme.tweetBody(primaryTextColor),
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
              ),
            ),
          if (hasMedia) ...[
            const SizedBox(height: 10),
            _PostMediaGrid(paths: widget.post.mediaPaths),
          ],
          if (hasDemoMedia) ...[
            const SizedBox(height: 10),
            _TweetMediaCarousel(),
          ],
          if (widget.post.quoted != null) ...[
            const SizedBox(height: 6),
            QuotePreview(snapshot: widget.post.quoted!),
          ],
        ],
      );

      Widget fullWidth = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onTap != null)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.zero,
              child: InkWell(
                borderRadius: BorderRadius.zero,
                onTap: widget.onTap,
                child: fullWidthHeaderContent,
              ),
            )
          else
            fullWidthHeaderContent,
          metricsSection,
        ],
      );

      return fullWidth;
    }

    // The content sits to the right of the avatar with simple padding — no card.
    Widget shellContent = tappableContentColumn;

    if (widget.onTap != null) {
      shellContent = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: widget.onTap,
          child: shellContent,
        ),
      );
    }

    Widget shell = Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [shellContent, metricsSection],
      ),
    );

    // No inner border here — we'll draw the top/bottom line at row level.

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        SizedBox(width: avatarGap),
        Expanded(child: shell),
      ],
    );
    return row;
  }

  Widget _buildMetricsRow({
    required ThemeData theme,
    required List<TweetMetricData> leftMetrics,
    required TweetMetricData bookmark,
    required TweetMetricData share,
    required bool isCompact,
    required Color onSurfaceColor,
    required bool forceContrast,
    required Color actionIconColor,
  }) {
    // Layout: all metrics spread evenly on the left,
    // with the overflow "more" action button pinned at the far right.
    final List<TweetMetricData> allMetrics = [
      ...leftMetrics,
      bookmark,
      share,
    ];
    // Small gap between metrics group and action button.
    final double gapBetweenGroups = isCompact ? 2.0 : 4.0;
    final Map<TweetMetricType, Offset> visualOffsets = {
      if (!isCompact) TweetMetricType.like: const Offset(10, 0),
      if (!isCompact) TweetMetricType.bookmark: const Offset(24, 0),
      // Move share slightly further left so it sits a bit closer in
      if (!isCompact) TweetMetricType.share: const Offset(6, 0),
    };

    Widget withVisualOffset(TweetMetricType type, Widget child) {
      final offset = visualOffsets[type] ?? Offset.zero;
      if (offset == Offset.zero) return child;
      return Transform.translate(offset: offset, child: child);
    }

    Widget row = SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Metrics group: take equal-width slots.
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < allMetrics.length; i++)
                  Expanded(
                    child: Align(
                      alignment:
                          i == 0 ? Alignment.centerLeft : Alignment.center,
                      child: withVisualOffset(
                        allMetrics[i].type,
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment:
                              i == 0 ? Alignment.centerLeft : Alignment.center,
                          child: _EdgeCell(
                            child: _buildMetricButton(
                              allMetrics[i],
                              compact: isCompact,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: gapBetweenGroups),
          // Overflow "more" action button pinned at extreme right
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _openPostMoreSheet,
            child: Transform.translate(
              offset: const Offset(-4, 0),
              child: Icon(
                Icons.more_horiz,
                size: 22,
                color: actionIconColor,
              ),
            ),
          ),
        ],
      ),
    );

    // Guard tiny rounding overflows on some device widths by adding
    // a small right padding that doesn't affect layout.
    row = Padding(padding: const EdgeInsets.only(right: 1), child: row);

    if (!forceContrast) {
      return row;
    }

    final ThemeData overrideTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(onSurface: onSurfaceColor),
    );

    return Theme(data: overrideTheme, child: row);
  }

  Widget _buildMetricButton(TweetMetricData data, {required bool compact}) {
    VoidCallback onTap;

    switch (data.type) {
      case TweetMetricType.reply:
        onTap = () async {
          await _ensureRepostForReply();
          final handler = widget.onReply;
          if (handler != null) {
            handler(widget.post);
            return;
          }
          _openReplyComposer();
        };
        break;
      case TweetMetricType.rein:
        onTap = _handleReinPressed;
        break;
      case TweetMetricType.like:
        onTap = _toggleLike;
        break;
      case TweetMetricType.view:
        onTap = () {
          _incrementView();
          Navigator.of(
            context,
          ).push(PostActivityScreen.route(post: widget.post));
        };
        break;
      case TweetMetricType.bookmark:
        onTap = _toggleBookmark;
        break;
      case TweetMetricType.share:
        onTap = () => _showToast('Share sheet coming soon');
        break;
    }

    // Special-case: REPOST uses encapsulating arrow button
    if (data.type == TweetMetricType.rein) {
      final int? nonZeroCount = (data.count != null && data.count! > 0)
          ? data.count
          : null;
      return XRetweetButton(
        label: data.label ?? 'REPOST',
        count: nonZeroCount,
        isActive: data.isActive,
        countFontSize: _TweetMetricSizing.countFontSize(compact),
        iconSize: _TweetMetricSizing.repostIconSize(compact),
        onTap: onTap,
        onLongPress: _handleReinPressed,
      );
    }

    // Special-case: COMMENT uses X-style comment icon button
    if (data.type == TweetMetricType.reply) {
      final int? nonZeroCount = (data.count != null && data.count! > 0)
          ? data.count
          : null;
      return XCommentButton(
        count: nonZeroCount,
        iconSize: _TweetMetricSizing.defaultIconSize(compact) - 4.0,
        countFontSize: _TweetMetricSizing.countFontSize(compact),
        onTap: onTap,
      );
    }

    return TweetMetric(data: data, onTap: onTap, compact: compact);
  }
}
