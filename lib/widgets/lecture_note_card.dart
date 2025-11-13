import 'package:flutter/material.dart';

import '../services/data_service.dart';
import 'tweet_post_card.dart';

class LectureNoteCard extends StatelessWidget {
  const LectureNoteCard({
    super.key,
    required this.post,
    required this.currentUserHandle,
    this.onTap,
    this.onReply,
  });

  final PostModel post;
  final String currentUserHandle;
  final VoidCallback? onTap;
  final ValueChanged<PostModel>? onReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.25 : 0.18);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: TweetPostCard(
        post: post,
        currentUserHandle: currentUserHandle,
        onReply: onReply,
        onTap: onTap,
      ),
    );
  }
}

