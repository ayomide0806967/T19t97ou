import 'package:flutter/material.dart';

import '../services/data_service.dart';

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
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.65 : 0.6);

    // Treat the post as the "full note" and show a compact,
    // step-rail–inspired preview (not the social/tweet layout).
    final String title = post.body.split('\n').first.trim().isEmpty
        ? 'Lecture note'
        : post.body.split('\n').first.trim();
    final String snippet = post.body.length > title.length
        ? post.body.substring(title.length).trim()
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini vertical rail + numbered dot to echo the note stepper
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    Container(
                      width: 2,
                      height: 14,
                      color: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: onSurface.withValues(alpha: 0.04),
                        border: Border.all(
                          color: onSurface.withValues(alpha: 0.3),
                          width: 1.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '1',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 24,
                      color: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (snippet.isNotEmpty)
                      Text(
                        snippet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: subtle,
                          height: 1.35,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${post.author} · ${post.timeAgo}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                      ),
                    ),
                  ],
                ),
              ),
              if (onReply != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, size: 18),
                  color: subtle,
                  splashRadius: 20,
                  onPressed: () => onReply!(post),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
