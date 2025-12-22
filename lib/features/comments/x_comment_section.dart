import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/tagged_text_input.dart';
import '../../widgets/icons/x_retweet_icon.dart';

part 'x_comment_section_actions.dart';
part 'x_comment_section_build.dart';
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

abstract class _XCommentSectionStateBase extends State<XCommentSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TaggedTextEditingController _commentController =
      TaggedTextEditingController();
  final ScrollController _scrollController = ScrollController();
  late FocusNode _inputFocusNode;
  bool _isReplying = false;
  String? _replyingTo;
  void _handleComposerTextChanged();

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
}

class _XCommentSectionState extends _XCommentSectionStateBase
    with _XCommentSectionActions, _XCommentSectionBuild {}
