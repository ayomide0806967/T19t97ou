part of 'x_comment_section.dart';

mixin _XCommentSectionActions on _XCommentSectionStateBase {
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

  @override
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
}
