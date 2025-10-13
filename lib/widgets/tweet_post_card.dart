import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/simple_comment_section.dart';
import '../widgets/tweet_shell.dart';

class TweetPostCard extends StatefulWidget {
  const TweetPostCard({
    super.key,
    required this.post,
    required this.currentUserHandle,
  });

  final PostModel post;
  final String currentUserHandle;

  @override
  State<TweetPostCard> createState() => _TweetPostCardState();
}

class _TweetPostCardState extends State<TweetPostCard> {
  static final math.Random _viewRandom = math.Random();

  late int _replies = widget.post.replies;
  late int _reposts = widget.post.reposts;
  late int _likes = widget.post.likes;
  late int _views = widget.post.views > 0 ? widget.post.views : _generateViewCount(0);

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
    if (oldWidget.post.id != widget.post.id || oldWidget.post.replies != widget.post.replies) {
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
  }

  void _incrementReply() {
    setState(() => _replies += 1);
  }

  void _incrementView() {
    setState(() => _views += 1);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
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

    final metrics = [
      TweetMetricData(
        type: TweetMetricType.reply,
        icon: Icons.mode_comment_outlined,
        count: _replies,
      ),
      TweetMetricData(
        type: TweetMetricType.rein,
        label: 'RE-IN',
        count: widget.post.originalId == null ? _reposts : widget.post.reposts,
        isActive: repostedByUser,
      ),
      TweetMetricData(
        type: TweetMetricType.like,
        icon: _liked ? Icons.favorite : Icons.favorite_border,
        count: _likes,
        isActive: _liked,
      ),
      TweetMetricData(
        type: TweetMetricType.view,
        icon: Icons.arrow_upward_rounded,
        count: _views,
      ),
      TweetMetricData(
        type: TweetMetricType.bookmark,
        label: 'Save',
        isActive: _bookmarked,
      ),
      const TweetMetricData(
        type: TweetMetricType.share,
        icon: Icons.send_rounded,
      ),
    ];

    return TweetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (repostBannerHandle != null && repostBannerHandle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.autorenew, size: 18, color: AppTheme.accent.withValues(alpha: 0.8)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HexagonAvatar(
                size: 48,
                child: Center(
                  child: Text(
                    _initialsFrom(widget.post.author),
                    style: theme.textTheme.labelLarge?.copyWith(
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
                icon: const Icon(Icons.more_horiz, color: AppTheme.textTertiary),
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
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweetMetric(
                    data: metrics[0],
                    onTap: () {
                      _incrementReply();
                      _showCommentComposer();
                    },
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweetMetric(
                    data: metrics[1],
                    onTap: _toggleRepost,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweetMetric(
                    data: metrics[2],
                    onTap: _toggleLike,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweetMetric(
                    data: metrics[3],
                    onTap: () {
                      _incrementView();
                      _showToast('Insights panel coming soon');
                    },
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweetMetric(
                    data: metrics[4],
                    onTap: _toggleBookmark,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweetMetric(
                    data: metrics[5],
                    onTap: () => _showToast('Share sheet coming soon'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
          body: 'This is exactly what our campus needs! Looking forward to seeing the impact on student innovation.',
          avatarColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          likes: 12,
          isLiked: false,
        ),
        SimpleComment(
          author: 'Mike Chen',
          timeAgo: '1h',
          body: 'Completely agree! The interdisciplinary approach will be game-changing.',
          avatarColors: [const Color(0xFFF093FB), const Color(0xFFF5576C)],
          likes: 3,
          isLiked: true,
        ),
        SimpleComment(
          author: 'Dr. Emily Watson',
          timeAgo: '45m',
          body: 'As a faculty member, I\'m excited about the collaboration opportunities this will create.',
          avatarColors: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
          likes: 28,
          isLiked: true,
        ),
        SimpleComment(
          author: 'Alex Rivera',
          timeAgo: '30m',
          body: 'The timing is perfect for this initiative. Students have been asking for more collaborative spaces.',
          avatarColors: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
          likes: 8,
          isLiked: false,
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
  const TweetMetric({super.key, required this.data, required this.onTap});

  final TweetMetricData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTheme.accent;
    final neutral = AppTheme.textSecondary;
    final isRein = data.type == TweetMetricType.rein;
    final isShare = data.type == TweetMetricType.share;

    const double iconSize = 24.0;
    const double labelFontSize = 15.0;
    const double countFontSize = 15.0;
    const double gap = 6.0;

    final color = data.isActive ? accent : (isShare ? theme.colorScheme.onSurface : neutral);
    final hasIcon = data.icon != null;
    final metricLabel = data.label ?? (isRein ? 'RE-IN' : null);
    final metricCount = data.count;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasIcon) ...[
          Icon(data.icon, size: iconSize, color: color),
          if (metricLabel != null || metricCount != null) SizedBox(width: gap),
        ],
        if (metricLabel != null) ...[
          Text(
            metricLabel,
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

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        foregroundColor: color,
        shape: const StadiumBorder(),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(color.withValues(alpha: 0.08)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: content,
      ),
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
    final background = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF4B5563);

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

    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _initialsFrom(snapshot.author),
                    style: TextStyle(
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
                    Row(
                      children: [
                        Text(
                          snapshot.author,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          snapshot.handle,
                          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          snapshot.timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            snapshot.body.length > 200 ? '${snapshot.body.substring(0, 200)}...' : snapshot.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
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

String _initialsFrom(String value) {
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return 'IN';
  final count = letters.length >= 2 ? 2 : 1;
  return letters.substring(0, count).toUpperCase();
}

String _formatMetric(int value) {
  if (value >= 1000000) {
    final formatted = value / 1000000;
    return formatted >= 10 ? '${formatted.toStringAsFixed(0)}M' : '${formatted.toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final formatted = value / 1000;
    return formatted >= 10 ? '${formatted.toStringAsFixed(0)}K' : '${formatted.toStringAsFixed(1)}K';
  }
  return value.toString();
}
