import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'simple_comment_section.dart';
import 'tweet_shell.dart';
import 'hexagon_avatar.dart';

class TweetPostCard extends StatefulWidget {
  const TweetPostCard({
    super.key,
    required this.post,
    required this.currentUserHandle,
    this.replyContext,
    this.backgroundColor,
    this.cornerAccentColor,
    this.showCornerAccent = true,
    this.onTap,
    this.showRepostBanner = false,
  });

  final PostModel post;
  final String currentUserHandle;
  final String? replyContext;
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

  Future<void> _toggleRepost() async {
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
    setState(() {});
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
    final repostBannerHandle = widget.post.repostedBy;

    // Build metric data
    final reply = TweetMetricData(
      type: TweetMetricType.reply,
      icon: Icons.mode_comment_outlined,
      count: _replies,
    );
    final rein = TweetMetricData(
      type: TweetMetricType.rein,
      label: 'RE-IN',
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
      icon: Icons.arrow_upward_rounded,
      count: _views,
    );
    final save = TweetMetricData(
      type: TweetMetricType.bookmark,
      label: 'Save',
      isActive: _bookmarked,
    );
    const share = TweetMetricData(
      type: TweetMetricType.share,
      icon: Icons.send_rounded,
    );

    // Left group fills remaining width; Share hugs the right edge.
    final leftMetrics = [reply, rein, like, view, save];

    // Auto-compact based on screen width and total items (6)
    final screenW = MediaQuery.of(context).size.width;
    final isCompact = (screenW / 6) < 80;

    final List<Widget> header = [];
    if (widget.replyContext != null) {
      header.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replying to ${widget.replyContext}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }
    if (widget.showRepostBanner &&
        repostBannerHandle != null &&
        repostBannerHandle.isNotEmpty) {
      header.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.import_export,
                size: 18,
                color: AppTheme.accent.withAlpha(200),
              ),
              const SizedBox(width: 6),
              Text(
                '$repostBannerHandle re-in',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget shell = TweetShell(
      backgroundColor: widget.backgroundColor,
      cornerAccentColor: widget.cornerAccentColor,
      showCornerAccent: widget.showCornerAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...header,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HexagonAvatar(
                size: 48,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                borderColor: const Color(0xFFB48A6B),
                borderWidth: 1.5,
                child: Center(
                  child: Text(
                    _initialsFrom(widget.post.author),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
                      widget.post.author,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.post.handle} • ${widget.post.timeAgo}',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showToast('Post options coming soon'),
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.post.body.isNotEmpty)
            Text(
              widget.post.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          if (widget.post.quoted != null) ...[
            const SizedBox(height: 12),
            QuotePreview(snapshot: widget.post.quoted!),
          ],
          if (widget.post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: widget.post.tags
                    .map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TagChip(tag),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                ...leftMetrics.map(
                  (m) => Expanded(
                    child: _EdgeCell(
                      child: _buildMetricButton(m, compact: isCompact),
                    ),
                  ),
                ),
                _EdgeCell(child: _buildMetricButton(share, compact: isCompact)),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.onTap != null) {
      shell = Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          onTap: widget.onTap,
          child: shell,
        ),
      );
    }

    return shell;
  }

  Widget _buildMetricButton(TweetMetricData data, {required bool compact}) {
    VoidCallback onTap;

    switch (data.type) {
      case TweetMetricType.reply:
        onTap = () {
          _incrementReply();
          _showCommentComposer();
        };
        break;
      case TweetMetricType.rein:
        onTap = _toggleRepost;
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

    return TweetMetric(data: data, onTap: onTap, compact: compact);
  }

  void _showCommentComposer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SimpleCommentSection(
                  postAuthor: widget.post.author,
                  postBody: widget.post.body,
                  postTime: widget.post.timeAgo,
                  comments: _demoComments(),
                  onAddComment: (content) {
                    Navigator.pop(context);
                    _showToast('Reply posted successfully!');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SimpleComment> _demoComments() => [
    SimpleComment(
      author: 'Sarah Johnson',
      timeAgo: '2h',
      body:
          'This is exactly what our campus needs! Looking forward to seeing the impact on student innovation.',
      avatarColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      likes: 12,
      isLiked: false,
    ),
    SimpleComment(
      author: 'Mike Chen',
      timeAgo: '1h',
      body:
          'Completely agree! The interdisciplinary approach will be game-changing.',
      avatarColors: [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      likes: 3,
      isLiked: true,
    ),
  ];
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
    final isShare = data.type == TweetMetricType.share;

    final double iconSize = compact
        ? (isShare ? 12.0 : 16.0)
        : (isShare ? 14.0 : 18.0);
    final double labelFontSize = compact ? 11.0 : 12.0;
    final double countFontSize = compact ? 11.0 : 12.0;
    final double gap = compact ? 2.0 : 3.0;

    final color = data.isActive
        ? accent
        : (isShare ? theme.colorScheme.onSurface : neutral);
    final hasIcon = data.icon != null;
    final metricCount = data.count;
    final bool highlightRein = isRein && data.isActive;
    final String? displayLabel = highlightRein
        ? 'IN'
        : (data.label ?? (isRein ? 'RE-IN' : null));

    Widget content;

    if (highlightRein) {
      final highlightColor = accent;

      // JUST "IN" — no arrows, no box
      final Widget badge = Text(
        displayLabel ?? 'IN',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          fontSize: compact ? 12.0 : 13.0,
        ),
      );

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          if (metricCount != null) ...[
            SizedBox(width: gap + 2),
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
            Icon(data.icon, size: iconSize, color: color),
            if (displayLabel != null || metricCount != null)
              SizedBox(width: gap),
          ],
          if (displayLabel != null) ...[
            Text(
              displayLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: labelFontSize,
              ),
            ),
            if (metricCount != null) SizedBox(width: gap),
          ],
          if (metricCount != null)
            Text(
              _formatMetric(metricCount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
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
            foregroundColor: color,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ), // edge-to-edge feel
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              color.withValues(alpha: 0.08),
            ),
          ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: content,
      ),
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
        ? Colors.white.withAlpha(20)
        : const Color(0xFFF1F5F9);
    final textColor = isDark
        ? Colors.white.withAlpha(180)
        : const Color(0xFF4B5563);

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      backgroundColor: background,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      margin: const EdgeInsets.only(left: 16),
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
