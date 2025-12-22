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
    final repo = context.watch<PostRepository>();
    final repostedByUser = _userHasReposted(repo);
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
    final Color controlIconColor = usesLightCardOnDarkTheme
        ? AppTheme.textSecondary
        : AppTheme.textTertiary;

    // Build metric data
    bool isJustNow = widget.post.timeAgo.toLowerCase() == 'just now';
    int repliesCount = _replies;
    int repostsCount = widget.post.originalId == null
        ? _reposts
        : widget.post.reposts;
    int viewsCount = _views;

    if (isJustNow) {
      repliesCount = 200000;
      repostsCount = 500000;
      viewsCount = 600000;
    }

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
    final view = TweetMetricData(
      type: TweetMetricType.view,
      // Icon rendered by TweetMetric using StatsThinIcon
      count: viewsCount,
    );
    const share = TweetMetricData(
      type: TweetMetricType.share,
      icon: Icons.send_rounded,
    );

    // Left group fills remaining width; order: Comment, Repost, Like, View
    final leftMetrics = [reply, rein, like, view];

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
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _openPostMoreSheet,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.more_horiz, size: 18, color: controlIconColor),
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
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _openPostMoreSheet,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.more_horiz, size: 18, color: controlIconColor),
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
                share: share,
                isCompact: isCompact,
                onSurfaceColor: primaryTextColor,
                forceContrast: usesLightCardOnDarkTheme,
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
    required TweetMetricData share,
    required bool isCompact,
    required Color onSurfaceColor,
    required bool forceContrast,
  }) {
    // Layout groups:
    //   Left group (A): reply, REPOST, like, view → spread evenly
    //   Right edge (B): share → compact on the far right
    final List<TweetMetricData> groupA = leftMetrics
        .where(
          (m) =>
              m.type == TweetMetricType.reply ||
              m.type == TweetMetricType.rein ||
              m.type == TweetMetricType.like ||
              m.type == TweetMetricType.view,
        )
        .toList();
    final double gapBetweenGroups = isCompact ? 12.0 : 16.0;

    Widget row = SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Group A: starts at the content's left edge and spreads evenly
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final m in groupA)
                  _EdgeCell(child: _buildMetricButton(m, compact: isCompact)),
              ],
            ),
          ),
          SizedBox(width: gapBetweenGroups),
          // Share stays pinned at extreme right in a tight cluster
          _EdgeCell(child: _buildMetricButton(share, compact: isCompact)),
        ],
      ),
    );

    // Guard tiny rounding overflows on some device widths by adding
    // a subtle right padding that doesn't affect layout.
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

    // Build responsive metric content inside a LayoutBuilder so we can
    // adapt when the available width becomes extremely tight.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final bool ultraTight =
            maxW.isFinite && maxW < 56; // ~ icon + tiny text
        final bool tight = maxW.isFinite && maxW < 80;

        // Special-case: REPOST uses encapsulating arrow button
        if (data.type == TweetMetricType.rein) {
          final int? nonZeroCount = (data.count != null && data.count! > 0)
              ? data.count
              : null;
          return XRetweetButton(
            label: data.label ?? 'REPOST',
            count: nonZeroCount,
            isActive: data.isActive,
            countFontSize: compact ? 12 : 13,
            iconSize: compact ? 21 : 23,
            onTap: onTap,
            onLongPress: _handleReinPressed,
          );
        }

        // Special-case: compress VIEW under very tight width (icon only)
        if (data.type == TweetMetricType.view && ultraTight) {
          final compactView = TweetMetricData(
            type: data.type,
            icon: Icons.signal_cellular_alt_rounded,
          );
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: TweetMetric(data: compactView, onTap: onTap, compact: true),
          );
        }
        // Special-case: COMMENT uses X-style comment icon button
        if (data.type == TweetMetricType.reply) {
          final int? nonZeroCount = (data.count != null && data.count! > 0)
              ? data.count
              : null;
          return XCommentButton(count: nonZeroCount, onTap: onTap);
        }
        // For view with limited width, still allow scaling
        if (data.type == TweetMetricType.view) {
          if (ultraTight) {
            final compactView = TweetMetricData(
              type: data.type,
              icon: Icons.signal_cellular_alt_rounded,
            );
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: TweetMetric(
                data: compactView,
                onTap: onTap,
                compact: true,
              ),
            );
          }
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: TweetMetric(data: data, onTap: onTap, compact: compact),
          );
        }
        // For other metrics (like), scale down under tight width
        if (tight) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: TweetMetric(data: data, onTap: onTap, compact: compact),
          );
        }
        return TweetMetric(data: data, onTap: onTap, compact: compact);
      },
    );
  }
}
