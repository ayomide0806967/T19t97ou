import 'package:flutter/material.dart';

class AppActionSheetItem {
  const AppActionSheetItem({
    required this.title,
    this.trailingIcon,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final IconData? trailingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
}

class AppActionSheetSection {
  const AppActionSheetSection(this.items);
  final List<AppActionSheetItem> items;
}

class AppActionSheet {
  AppActionSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<AppActionSheetSection> sections,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? iconColor,
  }) async {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color sheetBg = backgroundColor ??
        (isDark ? theme.colorScheme.surface : const Color(0xFFF2F2F2));
    final Color sheetSurface =
        surfaceColor ?? (isDark ? theme.colorScheme.surface : Colors.white);
    final Color onSurface = theme.colorScheme.onSurface;
    final Color resolvedIconColor =
        iconColor ?? (isDark ? Colors.white : Colors.black);
    final Border boxBorder = Border.all(
      color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.18),
      width: 1,
    );

    Divider divider() => Divider(
          height: 1,
          thickness: 1.2,
          indent: 18,
          endIndent: 18,
          color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.32),
        );

    Widget tile(
      BuildContext sheetContext,
      AppActionSheetItem item,
    ) {
      final Color titleColor = item.destructive ? Colors.red : onSurface;
      final Color itemIconColor =
          item.destructive ? Colors.red : resolvedIconColor;
      return ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        title: Text(
          item.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        trailing: item.trailing ??
            (item.trailingIcon == null
                ? null
                : Icon(item.trailingIcon, color: itemIconColor)),
        onTap: item.onTap == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                item.onTap?.call();
              },
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                for (int s = 0; s < sections.length; s++) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, s == 0 ? 8 : 0, 16, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: boxBorder,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < sections[s].items.length; i++) ...[
                            tile(sheetContext, sections[s].items[i]),
                            if (i != sections[s].items.length - 1) divider(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

