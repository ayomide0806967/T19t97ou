import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/post.dart';
import '../widgets/tweet_post_card.dart';
import '../widgets/tweet_composer_card.dart';
import '../models/comment.dart';

class TweetDetailView extends StatefulWidget {
  const TweetDetailView({
    super.key,
    required this.post,
    required this.comments,
    required this.onAddComment,
    this.autoFocusComposer = false,
  });

  final PostModel post;
  final List<CommentModel> comments;
  final bool autoFocusComposer;
  final ValueChanged<String> onAddComment;

  @override
  State<TweetDetailView> createState() => _TweetDetailViewState();
}

class _TweetDetailViewState extends State<TweetDetailView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.autoFocusComposer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAddComment(text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double composerReservePadding = 200;

    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, composerReservePadding),
            children: [
              // Main tweet card with full action bar, matching timeline styling
              TweetPostCard(
                post: widget.post,
                currentUserHandle: '@you',
                onReply: (_) {
                  _focusNode.requestFocus();
                },
              ),
              const SizedBox(height: 16),
              if (widget.comments.isEmpty)
                _EmptyReplies()
              else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Most relevant',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                for (int i = 0; i < widget.comments.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _TweetReplyTile(
                      comment: widget.comments[i],
                      onToggleLike: () {
                        setState(() {
                          final c = widget.comments[i];
                          c.isLiked = !c.isLiked;
                          c.likes += c.isLiked ? 1 : -1;
                        });
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
        // Composer pinned to bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: TweetComposerCard(
                controller: _controller,
                focusNode: _focusNode,
                hintText: 'Post your reply',
                backgroundColor: theme.brightness == Brightness.dark
                    ? const Color(0xFFF4F1EC)
                    : Colors.white,
                boxShadow: const [],
                textInputAction: TextInputAction.send,
                onSubmit: (_) => _submit(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TweetReplyTile extends StatelessWidget {
  const _TweetReplyTile({required this.comment, required this.onToggleLike});

  final CommentModel comment;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    const double avatarSize = 40;
    const double avatarSpacing = 12;
    const double avatarInset = avatarSize / 2 + avatarSpacing;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Reply container with border and rounded corners
        Container(
          margin: const EdgeInsets.only(left: avatarSize / 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.accent.withValues(alpha: 0.25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leave space so content aligns after the overlapping avatar.
                const SizedBox(width: avatarInset),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.author,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            comment.handle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '·',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            comment.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        comment.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Simple actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Action(
                              icon: Icons.chat_bubble_outline_rounded,
                              onTap: () {}),
                          _Action(
                              icon: Icons.repeat_rounded, onTap: () {}),
                          _Action(
                            icon: comment.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color:
                                comment.isLiked ? Colors.red : null,
                            label: _formatCount(comment.likes),
                            onTap: onToggleLike,
                          ),
                          _Action(
                              icon: Icons.send_rounded, onTap: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Overlapping avatar that "cuts into" the left edge.
        Positioned(
          left: 0,
          top: 16,
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: comment.avatarColors,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                comment.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      final formatted = value / 1000000;
      return formatted >= 10
          ? '${formatted.toStringAsFixed(0)}M'
          : '${formatted.toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final formatted = value / 1000;
      return formatted >= 10
          ? '${formatted.toStringAsFixed(0)}K'
          : '${formatted.toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.onTap,
    this.label,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color ?? textStyle?.color),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!, style: textStyle),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyReplies extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Be the first to reply',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
