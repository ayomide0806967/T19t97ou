import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
// Removed card-style shell for timeline layout
import 'hexagon_avatar.dart';
// import '../screens/post_detail_screen.dart'; // no longer used for replies
import '../screens/thread_screen.dart';
import '../screens/quote_screen.dart';
import 'icons/x_retweet_icon.dart';
import 'icons/x_comment_icon.dart';
import '../screens/post_activity_screen.dart';

class TweetPostCard extends StatefulWidget {
  const TweetPostCard({
    super.key,
    required this.post,
    required this.currentUserHandle,
    this.replyContext,
    this.onReply,
    this.backgroundColor,
    this.cornerAccentColor,
    this.showCornerAccent = true,
    this.onTap,
    this.showRepostBanner = false,
    this.showActions = true,
    this.fullWidthHeader = false,
    this.showTimeInHeader = true,
  });

  final PostModel post;
  final String currentUserHandle;
  final String? replyContext;
  final ValueChanged<PostModel>? onReply;
  final Color? backgroundColor;
  final Color? cornerAccentColor;
  final bool showCornerAccent;
  final VoidCallback? onTap;
  final bool showRepostBanner;
  final bool showActions;
  // When true (e.g. on the thread/comments page), render the avatar + name
  // above the tweet so the body can run full width.
  final bool fullWidthHeader;
  // Controls whether the header meta row shows the time (e.g. "· 14h").
  final bool showTimeInHeader;

  @override
  State<TweetPostCard> createState() => _TweetPostCardState();
}

class _TweetPostCardState extends State<TweetPostCard> {
  static final math.Random _viewRandom = math.Random();

  late int _replies = widget.post.replies;
  late int _reposts = widget.post.reposts;
  late int _likes = widget.post.likes;
  late int _views = widget.post.views > 0
      ? widget.post.views
      : _generateViewCount(0);

  bool _liked = false;
  bool _bookmarked = false;
  OverlayEntry? _toastEntry;

  int _generateViewCount(int base) {
    final safeBase = base < 0 ? 0 : base;
    final randomAddition = (_viewRandom.nextInt(900) + 100) * 100;
    return safeBase + randomAddition;
  }

  @override
  void didUpdateWidget(covariant TweetPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.replies != widget.post.replies) {
      _replies = widget.post.replies;
      _reposts = widget.post.reposts;
      _likes = widget.post.likes;
      _views = widget.post.views;
    }
  }

  @override
  void dispose() {
    _toastEntry?.remove();
    _toastEntry = null;
    super.dispose();
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

  String _withAtPrefix(String handle) {
    final trimmed = handle.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

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

  Future<void> _ensureRepostForReply() async {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) {
      return;
    }

    final dataService = context.read<DataService>();
    final targetId = widget.post.originalId ?? widget.post.id;

    final alreadyReposted = dataService.hasUserRetweeted(targetId, handle);
    if (alreadyReposted) {
      return;
    }

    final toggled = await dataService.toggleRepost(
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
      _showToast('Sign in to repost.');
      return;
    }
    final targetId = widget.post.originalId ?? widget.post.id;
    final toggled = await context.read<DataService>().toggleRepost(
      postId: targetId,
      userHandle: handle,
    );
    if (!mounted) return;
    _showToast(toggled ? 'Reposted!' : 'Removed repost');
    setState(() {
      if (widget.post.originalId == null) {
        _reposts = toggled ? _reposts + 1 : (_reposts - 1).clamp(0, 1 << 30);
      }
    });
  }

  void _handleReinPressed() {
    unawaited(_showReinOptions());
  }

  // Replies are updated from thread screen on return

  void _incrementView() {
    setState(() => _views += 1);
  }

  void _showToast(String message) {
    if (!mounted) return;
    _toastEntry?.remove();
    _toastEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final theme = Theme.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              color: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 320),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _toastEntry = entry;
    overlay.insert(entry);

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_toastEntry == entry) {
        entry.remove();
        _toastEntry = null;
      }
    });
  }

  Future<void> _showReinOptions() async {
    final theme = Theme.of(context);
    final bool repostedByUser = _userHasReposted(context.read<DataService>());
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

  bool _userHasReposted(DataService service) {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) return false;
    final targetId = widget.post.originalId ?? widget.post.id;
    return service.hasUserRetweeted(targetId, handle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();
    final repostedByUser = _userHasReposted(dataService);
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
    final String displayHandle = widget.post.handle.isNotEmpty
        ? (widget.post.handle.startsWith('@')
              ? widget.post.handle
              : '@${widget.post.handle}')
        : '';

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
      // Replies page / detail: name on first line, handle (and optional time)
      // on second line.
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (displayHandle.isNotEmpty)
                      Text(
                        displayHandle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                    if (widget.showTimeInHeader) ...[
                      if (displayHandle.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '·',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: secondaryTextColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
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
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _showToast('Post options coming soon'),
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.more_horiz, size: 18, color: controlIconColor),
            ),
          ),
        ],
      );
    } else {
      // Main timeline: name + handle + time on a single horizontal line.
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
                if (displayHandle.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    displayHandle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
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
            onTap: () => _showToast('Post options coming soon'),
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
    final Widget avatar = HexagonAvatar(
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
        children: [
          shellContent,
          metricsSection,
        ],
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

  Future<void> _openReplyComposer() async {
    // Open the same thread view used in profile, focusing the composer
    final data = context.read<DataService>();
    final thread = data.buildThreadForPost(widget.post.id);
    await Navigator.of(context).push(
      ThreadScreen.route(
        entry: thread,
        currentUserHandle: widget.currentUserHandle,
        initialReplyPostId: widget.post.id,
      ),
    );
    // After returning, refresh reply count from service to reflect potential changes
    if (!mounted) return;
    final updated = data.buildThreadForPost(widget.post.id).post.replies;
    setState(() => _replies = updated);
  }
}

class _ReinOptionTile extends StatelessWidget {
  const _ReinOptionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconBackground = theme.colorScheme.primary.withValues(
      alpha: isDark ? 0.18 : 0.12,
    );
    final Color iconColor = theme.colorScheme.primary;
    final TextStyle? titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: titleStyle),
                  const SizedBox(height: 4),
                  Text(description, style: bodyStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TweetMetricData {
  const TweetMetricData({
    required this.type,
    this.icon,
    this.count,
    this.label,
    this.isActive = false,
  });

  final TweetMetricType type;
  final IconData? icon;
  final int? count;
  final String? label;
  final bool isActive;
}

enum TweetMetricType { reply, rein, like, view, bookmark, share }

class TweetMetric extends StatelessWidget {
  const TweetMetric({
    super.key,
    required this.data,
    required this.onTap,
    required this.compact,
  });

  final TweetMetricData data;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTheme.accent;
    final neutral = AppTheme.textSecondary;
    final isRein = data.type == TweetMetricType.rein;
    final isLike = data.type == TweetMetricType.like;
    final isShare = data.type == TweetMetricType.share;
    final isBookmark = data.type == TweetMetricType.bookmark;

    // Slightly larger typography for better readability
    // Bump bookmark/share icons a bit bigger than others.
    double iconSize = compact ? 16.0 : 18.0;
    if (isShare || isBookmark) iconSize += 2.0;
    final double labelFontSize = compact ? 12.0 : 13.0;
    // Slightly smaller font for metric counts to de‑emphasize numbers.
    final double countFontSize = compact ? 10.0 : 11.0;
    // Keep counts visually close to icons in the main feed metrics row.
    final double gap = compact ? 1.0 : 2.0;

    final Color activeColor = isRein
        ? Colors.green
        : (isLike ? Colors.red : accent);
    final baseColor = data.isActive ? activeColor : neutral;
    final Color iconColor = isLike
        ? (data.isActive ? activeColor : neutral)
        : baseColor;
    final Color textColor = isLike ? neutral : baseColor;
    final hasIcon = data.icon != null || data.type == TweetMetricType.view;
    // Treat 0 as "no count" so we don't render a visible "0".
    final int? metricCount = (data.count != null && data.count! > 0)
        ? data.count
        : null;
    final bool highlightRein = isRein && data.isActive;
    final String? displayLabel = data.label;
    final double reinFontSize = compact ? 13.5 : 14.5;

    Widget content;

    // Special case: Reply button shown as a grey, thin bordered pill
    if (data.type == TweetMetricType.reply) {
      final Color pillText = theme.colorScheme.onSurface.withValues(
        alpha: 0.45,
      );
      final Color pillBorder = theme.dividerColor.withValues(alpha: 0.9);
      final String? countLabel = metricCount != null
          ? _formatMetric(metricCount)
          : null;
      final String labelText = data.label ?? 'COMMENT';
      final Widget pill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: pillBorder, width: 1),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: pillText,
                fontWeight: FontWeight.w600, // match non-highlight action label
                fontSize: compact ? 11.0 : 12.0, // slightly smaller for pill
              ),
            ),
            if (countLabel != null) ...[
              const SizedBox(width: 4),
              Text(
                countLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: pillText,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11.0 : 12.0,
                ),
              ),
            ],
          ],
        ),
      );
      // Entire content is the pill itself so the number sits inside the rounded box
      content = pill;
    } else if (highlightRein) {
      final highlightColor = Colors.green;
      // When reposted: keep the REPOST label in the neutral action color,
      // but show the count in green alongside the green icon.
      final Color labelColor = neutral;
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          XRetweetIcon(size: iconSize, color: highlightColor),
          SizedBox(width: gap),
          Text(
            displayLabel ?? 'REPOST',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w800,
              fontSize: labelFontSize,
              letterSpacing: 0.35,
            ),
          ),
          if (metricCount != null) ...[
            SizedBox(width: gap),
            Text(
              _formatMetric(metricCount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: highlightColor,
                fontWeight: FontWeight.w600,
                fontSize: countFontSize,
              ),
            ),
          ],
        ],
      );
    } else {
      // Standard layout for all other buttons
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasIcon) ...[
            (() {
              Widget icon;
              if (data.type == TweetMetricType.view) {
                icon = Icon(
                  Icons.signal_cellular_alt_rounded,
                  size: iconSize,
                  color: iconColor,
                );
              } else if (data.type == TweetMetricType.rein) {
                icon = XRetweetIcon(size: iconSize, color: iconColor);
              } else {
                icon = Icon(data.icon, size: iconSize, color: iconColor);
              }
              if (isLike) {
                icon = AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutBack,
                  scale: data.isActive ? 1.18 : 1.0,
                  child: icon,
                );
              }
              return icon;
            })(),
            if (displayLabel != null || metricCount != null)
              SizedBox(width: gap),
          ],
          if (displayLabel != null) ...[
            Text(
              displayLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isRein ? FontWeight.w700 : FontWeight.w600,
                fontSize: isRein ? reinFontSize : labelFontSize,
                letterSpacing: isRein ? 0.3 : null,
              ),
            ),
            if (metricCount != null) SizedBox(width: gap),
          ],
          if (metricCount != null) ...[
            (() {
              final text = Text(
                _formatMetric(metricCount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: countFontSize,
                  height: 1.1,
                ),
              );
              // For like and view, ensure the count is vertically centered
              // relative to the icon by giving it the same height box.
              if (isLike || data.type == TweetMetricType.view) {
                return SizedBox(
                  height: iconSize,
                  child: Center(child: text),
                );
              }
              return text;
            })(),
          ],
        ],
      );
    }

    return TextButton(
      onPressed: onTap,
      style:
          TextButton.styleFrom(
            padding: EdgeInsets.zero, // no inner horizontal padding
            minimumSize: const Size(0, 44), // good tap target
            alignment: Alignment.center,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: textColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ), // edge-to-edge feel
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              iconColor.withValues(alpha: 0.08),
            ),
          ),
      child: content,
    );
  }
}

// Expands cell vertically, keeps it edge-to-edge horizontally in its slot.
class _EdgeCell extends StatelessWidget {
  const _EdgeCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: child,
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.white.withAlpha(14)
        : const Color(0xFFF6F7F9);
    final textColor = isDark
        ? Colors.white.withAlpha(170)
        : const Color(0xFF4B5563);

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w500,
        fontSize: 10,
        letterSpacing: 0.1,
      ),
      backgroundColor: background,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Simple demo media carousel that allows horizontal swiping between
/// multiple images, inspired by Instagram's multi-photo posts.
class _TweetMediaCarousel extends StatefulWidget {
  @override
  State<_TweetMediaCarousel> createState() => _TweetMediaCarouselState();
}

class _TweetMediaCarouselState extends State<_TweetMediaCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.4 : 0.24,
    );

    const int itemCount = 3; // demo three-image carousel

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _controller,
            itemCount: itemCount,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: border),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/in_logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            itemCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _index == i ? 8 : 6,
              height: _index == i ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _index == i
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QuotePreview extends StatelessWidget {
  const QuotePreview({super.key, required this.snapshot});

  final PostSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      // Make the quoted capsule align with the main text/author column.
      // No extra left inset so it starts where the content starts.
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _initialsFrom(snapshot.author),
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.author,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${snapshot.handle} • ${snapshot.timeAgo}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            snapshot.body.length > 200
                ? '${snapshot.body.substring(0, 200)}...'
                : snapshot.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(220),
              height: 1.5,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PostMediaGrid extends StatelessWidget {
  const _PostMediaGrid({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = Border.all(
      color: theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.2),
      width: 0.8,
    );

    final cleaned = paths.where((p) => p.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();

    Widget tile(String path, int index) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder<void>(
              barrierColor: Colors.black,
              opaque: true,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, __, ___) => _FullScreenMediaViewer(
                paths: cleaned,
                initialIndex: index,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(border: border),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (cleaned.length == 1) {
      // Single image: tall portrait-style card similar to Instagram.
      return AspectRatio(
        aspectRatio: 3 / 4,
        child: tile(cleaned.first, 0),
      );
    }

    // Multiple images: horizontal carousel with the next image peeking in,
    // similar to Instagram's multi-photo posts.
    final PageController controller = PageController(viewportFraction: 0.75);

    return SizedBox(
      width: double.infinity,
      height: 230,
      child: PageView.builder(
        itemCount: cleaned.length,
        controller: controller,
        padEnds: false,
        itemBuilder: (context, index) {
          final path = cleaned[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == cleaned.length - 1 ? 0 : 8,
            ),
            child: tile(path, index),
          );
        },
      ),
    );
  }
}

class _FullScreenMediaViewer extends StatelessWidget {
  const _FullScreenMediaViewer({
    required this.paths,
    required this.initialIndex,
  });

  final List<String> paths;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final path = paths[index];
                return Center(
                  child: InteractiveViewer(
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper Functions ---

String _initialsFrom(String value) {
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return 'IN';
  final count = letters.length >= 2 ? 2 : 1;
  return letters.substring(0, count).toUpperCase();
}

String _formatMetric(int value) {
  if (value >= 1000000) {
    final formatted = value / 1000000;
    return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final formatted = value / 1000;
    return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)}K';
  }
  return value.toString();
}
