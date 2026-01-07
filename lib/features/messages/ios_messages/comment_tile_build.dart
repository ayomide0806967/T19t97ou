part of '../ios_messages_screen.dart';

mixin _CommentTileBuild on _CommentTileStateBase {
  static String _handleKey(String handle) =>
      handle.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();

  static String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final _ThreadComment comment = widget.comment;
    final bool isMine = _handleKey(comment.authorHandle) ==
        _handleKey(widget.currentUserHandle);
    // Light: own replies white, others white.
    final Color lightMine = Colors.white;
    final Color lightOther = Colors.white;
    final Color baseLight = isMine
        ? lightMine
        : lightOther; // used only in light mode
    final Color bubble = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : baseLight;

    // Meta text color uses default onSurface alpha in light theme
    final Color meta = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final bool isDark = widget.isDark;
    // Soft material-style card shadow for each reply (matches app card style).
    final List<BoxShadow> popShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
        offset: const Offset(0, 6),
        blurRadius: 18,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
        offset: const Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
    const double bubbleRadius = 18;
    const double avatarSize = 48;

    final Color selectedHover = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE5E7EB);
    // Avatar used inside the card for other users.
    final String displayAuthor = comment.author
        .replaceFirst(RegExp(r'^\s*@'), '')
        .trim();
    final String initial = displayAuthor.isNotEmpty
        ? displayAuthor.substring(0, 1).toUpperCase()
        : 'U';
    final Widget avatarWidget = isMine
        ? const SizedBox.shrink()
        : Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1EC),
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child: Text(
                initial,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
    // Padding inside the reply card.
    final EdgeInsets bubblePadding = const EdgeInsets.fromLTRB(12, 8, 12, 8);

    final Widget bubbleCore = Container(
      padding: bubblePadding,
      decoration: BoxDecoration(
        color: widget.selected ? selectedHover : bubble,
        borderRadius: BorderRadius.circular(bubbleRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: popShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isMine) avatarWidget,
          if (!isMine) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          (comment.authorName.isNotEmpty
                                  ? comment.authorName
                                  : comment.authorHandle)
                              .replaceFirst(RegExp(r'^\s*@'), ''),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(comment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(color: meta),
                      ),
                      if (widget.onMore != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: widget.onMore,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.more_horiz,
                              size: 20,
                              color: meta,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: AppTheme.tweetBody(
                    widget.isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                  ),
                ),
                if (comment.quotedBody != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withValues(
                                alpha: widget.isDark ? 0.4 : 0.3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 3,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (comment.quotedFrom ?? 'Reply')
                                          .replaceFirst(
                                        RegExp(r'^\s*@'),
                                        '',
                                      ),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.quotedBody!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(
                                          alpha:
                                              widget.isDark ? 0.9 : 0.85,
                                        ),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Pop effect on selection
    final Widget poppedCard = AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      scale: widget.selected ? 1.06 : 1.02,
      child: bubbleCore,
    );

    // Swipe progress (0..1) for extra effects
    final double swipeT = (_dragOffset / 80.0).clamp(0.0, 1.0);
    final Widget swipeBackground = IgnorePointer(
      child: Opacity(
        opacity: swipeT,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(
                alpha: widget.isDark ? 0.18 : 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.reply_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onHorizontalDragUpdate: (details) {
        _dx += details.delta.dx;
        // visual slide to the right only
        final double next = (_dragOffset + details.delta.dx).clamp(0, 56);
        setState(() {
          _dragOffset = next;
        });
        if (!_swipeHapticFired && _dragOffset > 42) {
          HapticFeedback.mediumImpact();
          _swipeHapticFired = true;
        }
        if (_dx > 42) {
          _dx = 0;
          widget.onSwipeReply?.call();
        }
      },
      onHorizontalDragEnd: (details) {
        final bool trigger =
            (details.primaryVelocity != null &&
                details.primaryVelocity! > 250) ||
            _dragOffset >= 42;
        if (trigger) {
          widget.onSwipeReply?.call();
        }
        setState(() {
          _dragOffset = 0; // animate back to rest
        });
        _swipeHapticFired = false;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity(),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Reply bubble + swipe background
            Padding(
              padding: const EdgeInsets.only(left: 0, bottom: 0),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned.fill(child: swipeBackground),
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Transform.rotate(
                      angle: -0.03 * swipeT,
                      child: Transform.scale(
                        scale: 1.0 + (0.02 * swipeT),
                        child: poppedCard,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
