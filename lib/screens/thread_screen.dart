import 'package:flutter/material.dart';

import '../models/thread_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/tweet_post_card.dart';

class ThreadScreen extends StatelessWidget {
  const ThreadScreen({
    super.key,
    required this.entry,
    required this.currentUserHandle,
  });

  final ThreadEntry entry;
  final String currentUserHandle;

  static Route<void> route({
    required ThreadEntry entry,
    required String currentUserHandle,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) =>
          ThreadScreen(entry: entry, currentUserHandle: currentUserHandle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replies = entry.replies;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thread'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          TweetPostCard(
            post: entry.post,
            currentUserHandle: currentUserHandle,
            replyContext: entry.replyToHandle,
            onTap: null,
          ),
          const SizedBox(height: 24),
          if (replies.isEmpty)
            _EmptyThreadState(handle: entry.post.handle)
          else
            ..._buildReplies(context, replies, 0),
        ],
      ),
    );
  }

  List<Widget> _buildReplies(
    BuildContext context,
    List<ThreadEntry> replies,
    int depth,
  ) {
    final List<Widget> widgets = <Widget>[];
    for (final ThreadEntry reply in replies) {
      widgets.add(
        ThreadReplyTile(
          entry: reply,
          depth: depth,
          currentUserHandle: currentUserHandle,
        ),
      );
      if (reply.replies.isNotEmpty) {
        widgets.addAll(_buildReplies(context, reply.replies, depth + 1));
      }
    }
    return widgets;
  }
}

class ThreadReplyTile extends StatelessWidget {
  const ThreadReplyTile({
    super.key,
    required this.entry,
    required this.depth,
    required this.currentUserHandle,
  });

  final ThreadEntry entry;
  final int depth;
  final String currentUserHandle;

  Color get _replyBackground => const Color(0xFFF6EDE4);
  Color get _replyCorner => const Color(0xFFE0CDBC);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String replyTo = entry.replyToHandle ?? entry.post.handle;
    final double indent = depth == 0 ? 0 : depth * 20.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.only(top: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TweetPostCard(
                  post: entry.post,
                  currentUserHandle: currentUserHandle,
                  replyContext: replyTo,
                  backgroundColor: _replyBackground,
                  cornerAccentColor: _replyCorner,
                  showCornerAccent: false,
                  showRepostBanner: true,
                  onTap: () {
                    Navigator.of(context).push(
                      ThreadScreen.route(
                        entry: entry,
                        currentUserHandle: currentUserHandle,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EmptyThreadState extends StatelessWidget {
  const _EmptyThreadState({required this.handle});

  final String handle;

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
            'Start a conversation with $handle.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
