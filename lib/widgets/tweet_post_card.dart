import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
// Removed card-style shell for timeline layout
import 'hexagon_avatar.dart';
import '../screens/post_detail_screen.dart';
import '../screens/quote_screen.dart';
// Using a network-style icon for stats; custom icon not required here.

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

  Future<void> _performReinstitute() async {
    final handle = widget.currentUserHandle;
    if (handle.isEmpty) {
      _showToast('Sign in to re-in.');
      return;
    }
    final targetId = widget.post.originalId ?? widget.post.id;
    final toggled = await context.read<DataService>().toggleRepost(
      postId: targetId,
      userHandle: handle,
    );
    if (!mounted) return;
    _showToast(toggled ? 'Re-instituted!' : 'Removed re-institution');
    setState(() {
      if (widget.post.originalId == null) {
        _reposts = toggled
            ? _reposts + 1
            : (_reposts - 1).clamp(0, 1 << 30);
      }
    });
  }

  void _handleReinPressed() {
    _showReinOptions();
  }

  void _incrementReply() {
    setState(() => _replies += 1);
  }

  void _incrementView() {
    setState(() => _views += 1);
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _showReinOptions() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bool isDark = theme.brightness == Brightness.dark;
        final Color surface =
            theme.colorScheme.surface.withValues(alpha: isDark ? 0.92 : 0.96);
        final Color border =
            Colors.white.withValues(alpha: isDark ? 0.12 : 0.25);

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
                            icon: Icons.repeat_rounded,
                            label: 'Re-institute',
                            description: 'Share this post with your network',
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

    // Build metric data
    final reply = TweetMetricData(
      type: TweetMetricType.reply,
      // Rounded, ball-like chat bubble with left-facing tail
      icon: Icons.chat_bubble_outline_rounded,
      count: _replies,
    );
    final rein = TweetMetricData(
      type: TweetMetricType.rein,
      label: 'REPOST',
      count: widget.post.originalId == null ? _reposts : widget.post.reposts,
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
      count: _views,
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
    if (widget.replyContext != null) {
      header.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TagChip('Replying to ${widget.replyContext}'),
        ),
      );
    }
    // Repost banner suppressed; modern reply tag handles context.

    // Build header content (author row) without the avatar.
    final Widget contentHeader = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  widget.post.author,
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
              Text(
                ' · ${widget.post.timeAgo}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _showToast('Post options coming soon'),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.more_horiz,
              size: 18,
              color: controlIconColor,
            ),
          ),
        ),
      ],
    );

    // Build the tweet body column.
    final Widget contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...header,
        contentHeader,
        const SizedBox(height: 2),
        if (widget.post.body.isNotEmpty)
          Text(
            widget.post.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: primaryTextColor,
              fontSize: 14,
              height: 1.45,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
            ),
          ),
        if (widget.post.quoted != null) ...[
          const SizedBox(height: 6),
          QuotePreview(snapshot: widget.post.quoted!),
        ],
        // Hashtags removed from containers by request
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

    // The content sits to the right of the avatar with simple padding — no card.
    Widget shell = const SizedBox.shrink();
    shell = Padding(
      padding: EdgeInsets.zero,
      child: contentColumn,
    );

    // No inner border here — we'll draw the top/bottom line at row level.

    if (widget.onTap != null) {
      shell = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: widget.onTap,
          child: shell,
        ),
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
    //   Left group (auto/equal): COMMENT, REPOST, LIKE, VIEW → share the
    //   remaining width equally. This keeps all actions sized fairly.
    //   Right edge: SHARE pinned at extreme right with a small gap from VIEW.
    final TweetMetricData replyMetric =
        leftMetrics.firstWhere((m) => m.type == TweetMetricType.reply);
    final TweetMetricData reinMetric =
        leftMetrics.firstWhere((m) => m.type == TweetMetricType.rein);
    final TweetMetricData likeMetric =
        leftMetrics.firstWhere((m) => m.type == TweetMetricType.like);
    final TweetMetricData viewMetric =
        leftMetrics.firstWhere((m) => m.type == TweetMetricType.view);
    final List<TweetMetricData> leftGroup = [
      replyMetric,
      reinMetric,
      likeMetric,
      viewMetric,
    ];
    final double tightGap = isCompact ? 8.0 : 10.0; // small gap before Share

    Widget row = SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Left group: four equal cells, each scales down if needed
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < leftGroup.length; i++)
                  Expanded(
                    child: Align(
                      alignment: (i == 1 || i == 2)
                          ? Alignment.centerRight // nudge REPOST and LIKE rightward
                          : Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: (i == 1 || i == 2)
                            ? Alignment.centerRight
                            : Alignment.center,
                        child: _EdgeCell(
                          child: i == 1
                              ? Transform.translate(
                                  offset: const Offset(8, 0),
                                  child: _buildMetricButton(
                                    leftGroup[i],
                                    compact: isCompact,
                                  ),
                                )
                              : _buildMetricButton(
                                  leftGroup[i],
                                  compact: isCompact,
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // View should be close to Share → keep only a tight gap here
          SizedBox(width: tightGap),
          // Share stays pinned at extreme right
          _EdgeCell(child: _buildMetricButton(share, compact: isCompact)),
        ],
      ),
    );

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
        onTap = () {
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
          _showToast('Insights panel coming soon');
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
        final bool ultraTight = maxW.isFinite && maxW < 56; // ~ icon + tiny text
        final bool tight = maxW.isFinite && maxW < 80;
        // Special-case: compress VIEW under very tight width (icon only)
        if (data.type == TweetMetricType.view && ultraTight) {
          final compactView = TweetMetricData(type: data.type, icon: Icons.signal_cellular_alt_rounded);
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: TweetMetric(data: compactView, onTap: onTap, compact: true),
          );
        }
        // Special-case: compress COMMENT pill under very tight width
        if (data.type == TweetMetricType.reply && ultraTight) {
          // Replace long label with a short token (or just the count if present)
          final shortLabel = 'C';
          final shortData = TweetMetricData(type: data.type, label: shortLabel);
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TweetMetric(data: shortData, onTap: onTap, compact: true),
          );
        }
        // For reply/view with limited width but not ultraTight, still allow scaling
        if (data.type == TweetMetricType.reply || data.type == TweetMetricType.view) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: data.type == TweetMetricType.reply
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: TweetMetric(data: data, onTap: onTap, compact: compact),
          );
        }
        // For other metrics (repost/like), scale down under tight width
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
    final payload = PostDetailPayload(
      author: widget.post.author,
      handle: widget.post.handle,
      timeAgo: widget.post.timeAgo,
      body: widget.post.body,
      initials: _initialsFrom(widget.post.author),
      tags: widget.post.tags,
      replies: _replies,
      reposts: _reposts,
      likes: _likes,
      bookmarks: widget.post.bookmarks,
      views: _views,
      quoted: widget.post.quoted != null
          ? PostDetailQuote(
              author: widget.post.quoted!.author,
              handle: widget.post.quoted!.handle,
              timeAgo: widget.post.quoted!.timeAgo,
              body: widget.post.quoted!.body,
            )
          : null,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          post: payload,
          focusComposer: true,
          onReplyPosted: () {
            if (!mounted) return;
            _incrementReply();
          },
        ),
      ),
    );
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
    final double countFontSize = compact ? 12.0 : 13.0;
    final double gap = compact ? 2.0 : 3.0;

    final Color activeColor = isRein
        ? Colors.green
        : (isLike ? Colors.red : accent);
    final baseColor = data.isActive ? activeColor : neutral;
    final Color iconColor = isLike
        ? (data.isActive ? activeColor : neutral)
        : baseColor;
    final Color textColor = isLike ? neutral : baseColor;
    final hasIcon = data.icon != null || data.type == TweetMetricType.view;
    final metricCount = data.count;
    final bool highlightRein = isRein && data.isActive;
    final String? displayLabel = data.label;
    final double reinFontSize = compact ? 13.5 : 14.5;

    Widget content;

    // Special case: Reply button shown as a grey, thin bordered pill
    if (data.type == TweetMetricType.reply) {
      final Color pillText = theme.colorScheme.onSurface.withValues(alpha: 0.45);
      final Color pillBorder = theme.dividerColor.withValues(alpha: 0.9);
      final String? countLabel =
          metricCount != null ? _formatMetric(metricCount) : null;
      final String labelText = data.label ?? 'COMMENT';
      final Widget pill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                fontSize: labelFontSize, // consistent with other labels
              ),
            ),
            if (countLabel != null) ...[
              const SizedBox(width: 4),
              Text(
                countLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: pillText,
                  fontWeight: FontWeight.w600,
                  fontSize: countFontSize,
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
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayLabel ?? 'REPOST',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: highlightColor,
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
              Widget icon = data.type == TweetMetricType.view
                  ? Icon(Icons.signal_cellular_alt_rounded, size: iconSize, color: iconColor)
                  : Icon(data.icon, size: iconSize, color: iconColor);
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
          if (metricCount != null)
            Text(
              _formatMetric(metricCount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: countFontSize,
              ),
            ),
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
