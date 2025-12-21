import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/tagged_text_input.dart';
import '../../widgets/icons/x_retweet_icon.dart';

class XCommentSection extends StatefulWidget {
  const XCommentSection({
    super.key,
    required this.postAuthor,
    required this.postHandle,
    required this.postTimeAgo,
    required this.postBody,
    this.postInitials,
    this.postTags = const [],
    this.quotedPost,
    this.metrics,
    this.autoFocusComposer = false,
    this.comments = const [],
    this.onAddComment,
  });

  final String postAuthor;
  final String postHandle;
  final String postTimeAgo;
  final String postBody;
  final String? postInitials;
  final List<String> postTags;
  final XQuotedPost? quotedPost;
  final XPostMetrics? metrics;
  final bool autoFocusComposer;
  final List<XComment> comments;
  final Function(String content)? onAddComment;

  @override
  State<XCommentSection> createState() => _XCommentSectionState();
}

class _XCommentSectionState extends State<XCommentSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TaggedTextEditingController _commentController =
      TaggedTextEditingController();
  final ScrollController _scrollController = ScrollController();
  late FocusNode _inputFocusNode;
  bool _isReplying = false;
  String? _replyingTo;

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

  Widget _buildPostActionRow(ThemeData theme) {
    final metrics = widget.metrics;

    Widget action(
      IconData icon, {
      String? label,
      Widget? customIcon,
    }) {
      return _XActionButton(
        icon: icon,
        customIcon: customIcon,
        label: label,
        onTap: () {},
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: _XActionButton(
                icon: Icons.chat_outlined,
                label: 'View replies',
                onTap: () {},
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(4, 0),
                    child: action(
                      Icons.repeat_rounded,
                      customIcon: const XRetweetIconMinimal(size: 20),
                      label: metrics != null
                          ? _formatCount(metrics.reposts)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _XActionButton(
                    icon: Icons.favorite_border_rounded,
                    label: metrics != null
                        ? _formatCount(metrics.likes)
                        : null,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: action(Icons.bookmark_border_rounded),
            ),
          ),
          Expanded(
            child: Center(
              child: action(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _inputFocusNode = FocusNode();
    _commentController.addListener(_handleComposerTextChanged);

    if (widget.autoFocusComposer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _inputFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant XCommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.autoFocusComposer && widget.autoFocusComposer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _inputFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.removeListener(_handleComposerTextChanged);
    _commentController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
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

    // Scroll to bottom after adding comment and keep focus on the composer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      _inputFocusNode.requestFocus();
    });
  }

  void _handleComposerTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _startReply(String commentId, String author) {
    setState(() {
      _isReplying = true;
      _replyingTo = author;
    });
    _commentController.text = '@$author ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  void _cancelReply() {
    setState(() {
      _isReplying = false;
      _replyingTo = null;
    });
    _commentController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  Widget _buildPrimaryPost(ThemeData theme, bool isDark, String replyHandle) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      (widget.postInitials != null &&
                          widget.postInitials!.isNotEmpty)
                      ? Text(
                          widget.postInitials!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        )
                      : const Icon(Icons.person, size: 16, color: Colors.white),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          replyHandle,
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
                          widget.postTimeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Replying to $replyHandle',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.postBody.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.postBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
          if (widget.quotedPost != null) ...[
            const SizedBox(height: 16),
            _XQuotedPostCard(quoted: widget.quotedPost!),
          ],
          if (widget.postTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.postTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      backgroundColor: AppTheme.accent.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (widget.metrics != null) ...[
            const SizedBox(height: 16),
            Text(
              '${widget.postTimeAgo} · ${_formatCount(widget.metrics!.views)} Views',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 0.6,
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            _XMetricsRow(metrics: widget.metrics!),
            const SizedBox(height: 14),
            _buildPostActionRow(theme),
          ],
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildMostRelevantHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              'Most relevant replies',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  SliverFillRemaining _buildEmptyRepliesState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final replyHandle = widget.postHandle.startsWith('@')
        ? widget.postHandle
        : '@${widget.postHandle.toLowerCase().replaceAll(' ', '')}';

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Header - X style
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
              // Scrollable content (post + replies)
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildPrimaryPost(theme, isDark, replyHandle),
                    ),
                    if (widget.comments.isNotEmpty)
                      _buildMostRelevantHeader(theme),
                    if (widget.comments.isEmpty)
                      _buildEmptyRepliesState(theme)
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: _XCommentTile(
                              comment: widget.comments[index],
                              onReply: () => _startReply(
                                widget.comments[index].id,
                                widget.comments[index].author,
                              ),
                              onLike: () {
                                setState(() {
                                  widget.comments[index].isLiked =
                                      !widget.comments[index].isLiked;
                                  widget.comments[index].likes +=
                                      widget.comments[index].isLiked ? 1 : -1;
                                });
                              },
                            ),
                          ),
                          childCount: widget.comments.length,
                        ),
                      ),
                    SliverPadding(padding: const EdgeInsets.only(bottom: 24)),
                  ],
                ),
              ),

              // Reply composer - WhatsApp-inspired UI
              Container(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111B21)
                      : const Color(0xFFF0F2F5),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isReplying && _replyingTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 220),
                              child: Text(
                                'Replying to ${_replyingTo!.startsWith('@') ? _replyingTo! : '@$_replyingTo'}',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_isReplying)
                              GestureDetector(
                                onTap: _cancelReply,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emoji_emotions_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    focusNode: _inputFocusNode,
                                    minLines: 1,
                                    maxLines: 3,
                                    textInputAction:
                                        TextInputAction.newline,
                                    keyboardType: TextInputType.multiline,
                                    onSubmitted: (_) => _submitComment(),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.25,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Write a reply...',
                                      hintStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _commentController.text
                                  .trim()
                                  .isNotEmpty
                              ? _submitComment
                              : null,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                _commentController.text.trim().isNotEmpty
                                    ? AppTheme.accent
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
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
    final bool isDark = theme.brightness == Brightness.dark;
    final Color textColor = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : Colors.black.withValues(alpha: 0.9);
    final Color metaTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    const double avatarSize = 36;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Card + reply text, shifted right so the avatar cuts into the left edge.
              Container(
                margin: const EdgeInsets.only(left: avatarSize / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 1,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: isDark ? 0.28 : 0.12,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 10, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.comment.author,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        textColor.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.comment.body,
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.comment.timeAgo,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontSize: 10,
                                        color: metaTextColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: widget.onLike,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.comment.isLiked
                                                ? Icons.favorite_rounded
                                                : Icons
                                                    .favorite_border_rounded,
                                            size: 14,
                                            color: widget.comment.isLiked
                                                ? Colors.red
                                                : metaTextColor,
                                          ),
                                          if (widget.comment.likes > 0) ...[
                                            const SizedBox(width: 3),
                                            Text(
                                              _formatCount(
                                                  widget.comment.likes),
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 10,
                                                color: metaTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: isDark ? 0.28 : 0.12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: widget.onReply,
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Picture-frame avatar overlapping the card's left edge.
              Positioned(
                left: 0,
                top: 8,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.comment.avatarColors,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.comment.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

class _XActionButton extends StatefulWidget {
  const _XActionButton({
    required this.icon,
    this.customIcon,
    this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final Widget? customIcon;
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
    final baseColor = widget.isActive
        ? Colors.redAccent
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);

    // Responsive scaling based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    // Scale icon size based on device type
    final iconSize = isMobile ? 24.0 : (isTablet ? 26.0 : 28.0);
    final horizontalPadding = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
    final verticalPadding = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);
    final minTapTarget = isMobile ? 48.0 : (isTablet ? 52.0 : 56.0);

    final Widget iconWidget = widget.customIcon ??
        Icon(
          widget.icon,
          size: iconSize,
          color: baseColor,
        );

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
            child: Container(
              constraints: BoxConstraints(
                minWidth: minTapTarget,
                minHeight: minTapTarget,
              ),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
	              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
	                  iconWidget,
                  if (widget.label != null) ...[
                    SizedBox(width: isMobile ? 6.0 : 8.0),
                    Text(
                      widget.label!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: baseColor,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13.0 : 14.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class XPostMetrics {
  const XPostMetrics({
    required this.replyCount,
    required this.reposts,
    required this.likes,
    required this.bookmarks,
    required this.views,
  });

  final int replyCount;
  final int reposts;
  final int likes;
  final int bookmarks;
  final int views;
}

class _XMetricsRow extends StatelessWidget {
  const _XMetricsRow({required this.metrics});

  final XPostMetrics metrics;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
    );
    final isDark = theme.brightness == Brightness.dark;
    // Use neutral greys for the Views chip instead of accent/cyan.
    final Color chipBackground = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final Color chipContent = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.85 : 0.7,
    );
    final chipTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: chipContent,
      fontWeight: FontWeight.w600,
    );

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${_formatCount(metrics.reposts)} Reposts', style: labelStyle),
        Text('${_formatCount(metrics.replyCount)} Replies', style: labelStyle),
        Text('${_formatCount(metrics.likes)} Likes', style: labelStyle),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 16, color: chipContent),
              const SizedBox(width: 6),
              Text(
                '${_formatCount(metrics.views)} views',
                style: chipTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class XQuotedPost {
  const XQuotedPost({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
}

class _XQuotedPostCard extends StatelessWidget {
  const _XQuotedPostCard({required this.quoted});

  final XQuotedPost quoted;

  String get _normalizedHandle => quoted.handle.startsWith('@')
      ? quoted.handle
      : '@${quoted.handle.replaceAll(' ', '').toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.accent.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quoted.author,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _normalizedHandle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '·',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                quoted.timeAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quoted.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
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
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
