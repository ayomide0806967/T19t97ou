import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../constants/toast_durations.dart';
import '../../../../core/feed/post_repository.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/ui/app_toast.dart';
import '../../../../core/ui/initials.dart';
import '../../../../models/post.dart';
import '../../../../screens/post_activity_screen.dart';
import '../../../../screens/quote_screen.dart';
import '../../../../screens/thread_screen.dart';
import '../../../../theme/app_theme.dart';
// Removed card-style shell for timeline layout
import '../../../../widgets/hexagon_avatar.dart';
// import '../screens/post_detail_screen.dart'; // no longer used for replies
import '../../../../widgets/icons/x_comment_icon.dart';
import '../../../../widgets/icons/x_retweet_icon.dart';

part 'tweet_post_card_media.dart';
part 'tweet_post_card_metrics.dart';
part 'tweet_post_card_quote.dart';
part 'tweet_post_card_utils.dart';

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
    this.toastDuration = ToastDurations.standard,
    this.showRepostToast = true,
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
  final Duration toastDuration;
  final bool showRepostToast;

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
    final entry = _toastEntry;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
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

  void _toggleBookmarkWithToast() {
    setState(() {
      _bookmarked = !_bookmarked;
    });
    _showToast(_bookmarked ? 'Saved' : 'Removed from saved');
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

  // Replies are updated from thread screen on return

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
    final bool repostedByUser = _userHasReposted(context.read<PostRepository>());
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
    final Color sheetBg =
        isDark ? theme.colorScheme.surface : const Color(0xFFF2F2F2);
    final Color sheetSurface = isDark ? theme.colorScheme.surface : Colors.white;
    final Color onSurface = theme.colorScheme.onSurface;
    final Border boxBorder = Border.all(
      color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.18),
      width: 1,
    );
    final String rawHandle =
        widget.post.handle.isNotEmpty ? widget.post.handle : widget.post.author;
    final String handleLabel = _withAtPrefix(rawHandle);
    final String displayLabel =
        handleLabel.isEmpty ? 'account' : handleLabel;

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
                          onTap: () =>
                              _showToast('Restricted $displayLabel (coming soon)'),
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
            : '@${handleForProfile}';
        Navigator.of(context).push(
          AppNav.userProfile(normalizedHandle),
        );
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
