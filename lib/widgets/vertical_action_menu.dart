import 'package:flutter/material.dart';

class VerticalActionMenu extends StatefulWidget {
  const VerticalActionMenu({
    super.key,
    required this.isQuizActive,
    this.onQuizStatusChanged,
    this.onShareQuiz,
    this.onViewAnswers,
    this.onViewResult,
    this.onEditQuiz,
    this.onAddFavourite,
    this.onCollaboration,
    this.onViewQuiz,
    this.onDuplicateQuiz,
    this.onDeleteQuiz,
    this.answerCount,
  });

  final bool isQuizActive;
  final Function(bool)? onQuizStatusChanged;
  final VoidCallback? onShareQuiz;
  final VoidCallback? onViewAnswers;
  final VoidCallback? onViewResult;
  final VoidCallback? onEditQuiz;
  final VoidCallback? onAddFavourite;
  final VoidCallback? onCollaboration;
  final VoidCallback? onViewQuiz;
  final VoidCallback? onDuplicateQuiz;
  final VoidCallback? onDeleteQuiz;
  final int? answerCount;

  @override
  State<VerticalActionMenu> createState() => _VerticalActionMenuState();
}

class _VerticalActionMenuState extends State<VerticalActionMenu> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color surface = isDark ? theme.colorScheme.surface : Colors.white;
    final Color dividerColor = theme.dividerColor.withValues(alpha: isDark ? 0.5 : 0.7);

    return Card(
      elevation: 0,
      color: surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.help_outline,
            label: 'Quiz Status',
            isFirstItem: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isQuizActive ? 'Active' : 'Inactive',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.isQuizActive
                        ? const Color(0xFF075E54)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: widget.isQuizActive,
                  onChanged: widget.onQuizStatusChanged,
                  activeThumbColor: const Color(0xFF075E54),
                  activeTrackColor:
                      const Color(0xFF075E54).withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor:
                      theme.dividerColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _MenuTile(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: widget.onShareQuiz,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _MenuTile(
            icon: Icons.visibility_outlined,
            label: 'View Answers',
            onTap: widget.onViewAnswers,
            trailing: widget.answerCount != null
                ? _AnswerCountBadge(count: widget.answerCount!)
                : null,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _MenuTile(
            icon: Icons.leaderboard_outlined,
            label: 'View Result',
            onTap: widget.onViewResult,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _MenuTile(
            icon: Icons.edit_outlined,
            label: 'Edit Quiz',
            onTap: widget.onEditQuiz,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _MenuTile(
            icon: Icons.favorite_border_outlined,
            label: 'Add Favourite',
            onTap: widget.onAddFavourite,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _MenuTile(
            icon: Icons.group_outlined,
            label: 'Collaboration',
            onTap: widget.onCollaboration,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _MenuTile(
            icon: Icons.remove_red_eye_outlined,
            label: 'View Quiz',
            onTap: widget.onViewQuiz,
            isLastItem: true,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.isFirstItem = false,
    this.isLastItem = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isFirstItem;
  final bool isLastItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.only(
      topLeft: isFirstItem ? const Radius.circular(20) : Radius.zero,
      topRight: isFirstItem ? const Radius.circular(20) : Radius.zero,
      bottomLeft: isLastItem ? const Radius.circular(20) : Radius.zero,
      bottomRight: isLastItem ? const Radius.circular(20) : Radius.zero,
    );

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: radius),
      leading: Icon(
        icon,
        size: 22,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 24,
      horizontalTitleGap: 12,
      dense: true,
    );
  }
}

class _AnswerCountBadge extends StatelessWidget {
  const _AnswerCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    const Color green = Color(0xFF075E54);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
              : green,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
            : green.withValues(alpha: 0.08),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? theme.colorScheme.onSurface : green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
