import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/tagged_text_input.dart';
import '../../widgets/icons/x_retweet_icon.dart';

part 'x_comment_section_parts.dart';

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
