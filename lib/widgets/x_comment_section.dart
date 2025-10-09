import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/tagged_text_input.dart';
import '../widgets/tweet_shell.dart';

class XCommentSection extends StatefulWidget {
  const XCommentSection({
    super.key,
    required this.postAuthor,
    required this.postBody,
    this.comments = const [],
    this.onAddComment,
  });

  final String postAuthor;
  final String postBody;
  final List<XComment> comments;
  final Function(String content)? onAddComment;

  @override
  State<XCommentSection> createState() => _XCommentSectionState();
}

class _XCommentSectionState extends State<XCommentSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isReplying = false;
  String? _replyingTo;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    widget.onAddComment?.call(_commentController.text.trim());
    _commentController.clear();
    setState(() {
      _isReplying = false;
      _replyingTo = null;
    });

    // Scroll to bottom after adding comment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startReply(String commentId, String author) {
    setState(() {
      _isReplying = true;
      _replyingTo = author;
    });
    _commentController.text = '@$author ';
  }

  void _cancelReply() {
    setState(() {
      _isReplying = false;
      _replyingTo = null;
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Header - X style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

              // Original post preview
              Container(
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
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: AppTheme.accent,
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
                              Text(
                                'Replying to @${widget.postAuthor.toLowerCase().replaceAll(' ', '')}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.postBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Comments list - X style
              Expanded(
                child: widget.comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: widget.comments.length,
                        itemBuilder: (context, index) {
                          return _XCommentTile(
                            comment: widget.comments[index],
                            onReply: () => _startReply(
                              widget.comments[index].id,
                              widget.comments[index].author,
                            ),
                            onLike: () {
                              setState(() {
                                widget.comments[index].isLiked = !widget.comments[index].isLiked;
                                widget.comments[index].likes += widget.comments[index].isLiked ? 1 : -1;
                              });
                            },
                          );
                        },
                      ),
              ),

              // Reply indicator
              if (_isReplying && _replyingTo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Text(
                        'Replying to $_replyingTo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.accent,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _cancelReply,
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

              // Comment input - X style
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 32),
                        child: TaggedTextInput(
                          controller: _commentController,
                          hintText: 'Post your reply',
                          maxLines: 3,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          onChanged: (text) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _commentController.text.trim().isNotEmpty
                            ? AppTheme.accent
                            : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _commentController.text.trim().isNotEmpty
                              ? _submitComment
                              : null,
                          child: Icon(
                            Icons.send_rounded,
                            size: 14,
                            color: _commentController.text.trim().isNotEmpty
                                ? Colors.white
                                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
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

class _XCommentTile extends StatefulWidget {
  const _XCommentTile({
    required this.comment,
    required this.onReply,
    required this.onLike,
  });

  final XComment comment;
  final VoidCallback onReply;
  final VoidCallback onLike;

  @override
  State<_XCommentTile> createState() => _XCommentTileState();
}

class _XCommentTileState extends State<_XCommentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  String _formatCount(int value) {
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: TweetShell(
            child: Padding(
              padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.comment.avatarColors,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.comment.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Text(
                                widget.comment.author,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.comment.handle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.comment.timeAgo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Body
                          Text(
                            widget.comment.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Actions - X style
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _XActionButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Reply',
                                onTap: widget.onReply,
                              ),
                              _XActionButton(
                                icon: widget.comment.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                label: _formatCount(widget.comment.likes),
                                isActive: widget.comment.isLiked,
                                onTap: widget.onLike,
                              ),
                              _XActionButton(
                                icon: Icons.repeat_rounded,
                                label: 'Repost',
                                onTap: () {},
                              ),
                              _XActionButton(
                                icon: Icons.share_rounded,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _XActionButton extends StatefulWidget {
  const _XActionButton({
    required this.icon,
    this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  State<_XActionButton> createState() => _XActionButtonState();
}

class _XActionButtonState extends State<_XActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isActive
                      ? Colors.red
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    widget.label!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.isActive
                          ? Colors.red
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class XComment {
  XComment({
    required this.id,
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    required this.avatarColors,
    this.likes = 0,
    this.isLiked = false,
  });

  final String id;
  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final List<Color> avatarColors;
  int likes;
  bool isLiked;

  String get initials {
    final parts = author.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}