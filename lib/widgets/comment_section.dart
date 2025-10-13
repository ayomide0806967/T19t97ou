import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/tagged_text_input.dart';

class CommentSection extends StatefulWidget {
  const CommentSection({
    super.key,
    required this.postAuthor,
    required this.postBody,
    this.comments = const [],
    this.onAddComment,
  });

  final String postAuthor;
  final String postBody;
  final List<Comment> comments;
  final Function(String content)? onAddComment;

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _commentController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    widget.onAddComment?.call(_commentController.text.trim());
    _commentController.clear();
    setState(() {
      _isExpanded = false;
    });
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
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mode_comment_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comments',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.comments.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Comments list - make it scrollable with fixed height
                Expanded(
                  flex: 1,
                  child: widget.comments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No comments yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Be the first to share your thoughts',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shrinkWrap: true,
                          itemCount: widget.comments.length,
                          itemBuilder: (context, index) {
                            return _CommentTile(
                              comment: widget.comments[index],
                              isLast: index == widget.comments.length - 1,
                            );
                          },
                        ),
                ),

                // Comment input
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.01)
                        : Colors.grey.withValues(alpha: 0.02),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: _CommentInput(
                    controller: _commentController,
                    isExpanded: _isExpanded,
                    onExpand: () => setState(() => _isExpanded = true),
                    onCollapse: () => setState(() => _isExpanded = false),
                    onSubmit: _submitComment,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({required this.comment, required this.isLast});

  final Comment comment;
  final bool isLast;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
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

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(top: 16, bottom: widget.isLast ? 0 : 16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with connector line
                    Stack(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.comment.avatarColors,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: widget.comment.avatarColors.first
                                    .withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.comment.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (!widget.isLast && widget.comment.replies.isNotEmpty)
                          Positioned(
                            top: 36,
                            left: 18,
                            child: Container(
                              width: 2,
                              height: 60,
                              color: theme.dividerColor.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Comment content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Comment header
                          Row(
                            children: [
                              Text(
                                widget.comment.author,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.comment.handle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.comment.timeAgo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Comment body
                          Text(
                            widget.comment.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Comment actions
                          Row(
                            children: [
                              _CommentAction(
                                icon: Icons.reply_rounded,
                                count: widget.comment.replies.length,
                                onTap: () {},
                              ),
                              const SizedBox(width: 20),
                              _CommentAction(
                                icon: widget.comment.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                count: widget.comment.likes,
                                isActive: widget.comment.isLiked,
                                onTap: () {
                                  setState(() {
                                    widget.comment.isLiked =
                                        !widget.comment.isLiked;
                                    widget.comment.likes +=
                                        widget.comment.isLiked ? 1 : -1;
                                  });
                                },
                              ),
                              const SizedBox(width: 20),
                              _CommentAction(
                                icon: Icons.send_rounded,
                                onTap: () {},
                              ),
                            ],
                          ),

                          // Replies
                          if (widget.comment.replies.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ...widget.comment.replies.map((reply) {
                              return _ReplyTile(
                                reply: reply,
                                isLast: reply == widget.comment.replies.last,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReplyTile extends StatefulWidget {
  const _ReplyTile({required this.reply, required this.isLast});

  final Comment reply;
  final bool isLast;

  @override
  State<_ReplyTile> createState() => _ReplyTileState();
}

class _ReplyTileState extends State<_ReplyTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -0.05,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 20, 0),
          child: Container(
            margin: EdgeInsets.only(
              top: 12,
              bottom: widget.isLast ? 0 : 12,
              left: 48,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.reply.avatarColors,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      widget.reply.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.reply.author,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.reply.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.reply.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.9,
                          ),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _CommentAction(
                            icon: widget.reply.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            count: widget.reply.likes,
                            isActive: widget.reply.isLiked,
                            onTap: () {
                              setState(() {
                                widget.reply.isLiked = !widget.reply.isLiked;
                                widget.reply.likes += widget.reply.isLiked
                                    ? 1
                                    : -1;
                              });
                            },
                            size: 'small',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentAction extends StatefulWidget {
  const _CommentAction({
    required this.icon,
    this.count,
    this.isActive = false,
    required this.onTap,
    this.size = 'normal',
  });

  final IconData icon;
  final int? count;
  final bool isActive;
  final VoidCallback onTap;
  final String size;

  @override
  State<_CommentAction> createState() => _CommentActionState();
}

class _CommentActionState extends State<_CommentAction>
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
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = widget.size == 'small';
    final iconSize = isSmall ? 16.0 : 18.0;
    final fontSize = isSmall ? 11.0 : 12.0;

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
                  size: iconSize,
                  color: widget.isActive
                      ? Colors.red
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                if (widget.count != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(widget.count!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.isActive
                          ? Colors.red
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
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

  String _formatCount(int value) {
    if (value >= 1000) {
      final formatted = value / 1000;
      return '${formatted.toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _CommentInput extends StatefulWidget {
  const _CommentInput({
    required this.controller,
    required this.isExpanded,
    required this.onExpand,
    required this.onCollapse,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onSubmit;

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: 48.0,
      end: 80.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_CommentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
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
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),

              // Input field
              Expanded(
                child: widget.isExpanded
                    ? TaggedTextInput(
                        controller: widget.controller,
                        hintText: 'Add a comment...',
                        maxLines: 2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {});
                        },
                        onSubmitted: (_) => widget.onSubmit(),
                      )
                    : GestureDetector(
                        onTap: widget.onExpand,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Add a comment...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),

              // Post button
              AnimatedOpacity(
                opacity:
                    widget.isExpanded &&
                        widget.controller.text.trim().isNotEmpty
                    ? 1.0
                    : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: widget.controller.text.trim().isNotEmpty
                        ? widget.onSubmit
                        : null,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Comment {
  Comment({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    required this.avatarColors,
    this.replies = const [],
    this.likes = 0,
    this.isLiked = false,
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final List<Color> avatarColors;
  final List<Comment> replies;
  int likes;
  bool isLiked;

  String get initials {
    final parts = author.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
