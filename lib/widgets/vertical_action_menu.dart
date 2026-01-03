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
    final Color dividerColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.5 : 0.7);

    Widget buildSection(List<Widget> children) {
      return Card(
        elevation: 0,
        color: surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.dividerColor.withValues(
              alpha: isDark ? 0.35 : 0.55,
            ),
          ),
        ),
        child: Column(children: children),
      );
    }

    final headerActionsCard = buildSection([
      _MenuTile(
        icon: Icons.help_outline,
        label: 'Quiz Status',
        isFirstItem: true,
        showIcon: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isQuizActive ? 'Active' : 'Inactive',
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.isQuizActive
                    ? const Color(0xFF111827)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: widget.isQuizActive,
              onChanged: widget.onQuizStatusChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF25D366).withValues(
                alpha: 0.35,
              ),
              inactiveThumbColor: Colors.black,
              inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.6),
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
        label: 'View result',
        isLastItem: true,
        onTap: widget.onViewAnswers,
        trailing: null,
      ),
    ]);

    final List<Widget> secondaryItems = [
      _MenuTile(
        icon: Icons.wifi_tethering_rounded,
        label: 'Monitor live quiz',
        isFirstItem: true,
        onTap: widget.onViewResult,
        iconColor: null,
        textColor: null,
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
    ];

    // Mark last regular item as bottom-rounded (delete is now its own card).
    secondaryItems[secondaryItems.length - 1] = _MenuTile(
      icon: Icons.group_outlined,
      label: 'Collaboration',
      onTap: widget.onCollaboration,
      isLastItem: true,
    );

    final secondaryActionsCard = buildSection(secondaryItems);
    final deleteCard = widget.onDeleteQuiz == null
        ? null
        : buildSection([
            _MenuTile(
              icon: Icons.delete_outline,
              label: 'Delete quiz',
              onTap: widget.onDeleteQuiz,
              iconColor: Colors.red,
              textColor: Colors.red,
              isFirstItem: true,
              isLastItem: true,
            ),
          ]);

    return Column(
      children: [
        headerActionsCard,
        const SizedBox(height: 12),
        secondaryActionsCard,
        if (deleteCard != null) ...[
          const SizedBox(height: 12),
          deleteCard,
        ],
      ],
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
    this.showIcon = true,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isFirstItem;
  final bool isLastItem;
  final bool showIcon;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.only(
      topLeft: isFirstItem ? const Radius.circular(20) : Radius.zero,
      topRight: isFirstItem ? const Radius.circular(20) : Radius.zero,
      bottomLeft: isLastItem ? const Radius.circular(20) : Radius.zero,
      bottomRight: isLastItem ? const Radius.circular(20) : Radius.zero,
    );

    final Widget? iconWidget = showIcon
        ? Icon(
            icon,
            size: 22,
            color:
                iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.75),
          )
        : null;

    final Widget? trailingWidget = iconWidget == null
        ? trailing
        : (trailing == null
              ? iconWidget
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    trailing!,
                    const SizedBox(width: 12),
                    iconWidget,
                  ],
                ));

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: radius),
      tileColor: backgroundColor?.withValues(alpha: 0.18),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor ?? theme.colorScheme.onSurface,
        ),
      ),
      trailing: trailingWidget,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    const Color accent = Color(0xFF25D366);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
              : accent,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
            : accent.withValues(alpha: 0.14),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? theme.colorScheme.onSurface : accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
