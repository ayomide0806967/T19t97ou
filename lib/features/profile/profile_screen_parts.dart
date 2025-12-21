part of 'profile_screen.dart';

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = ['Posts', 'Classes', 'Replies'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final inactive = onSurface.withValues(alpha: isDark ? 0.55 : 0.5);
    final selectedBg = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.grey.withValues(alpha: 0.2);
    final borderColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.4 : 0.25,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_tabs.length, (index) {
        final isSelected = index == selectedIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: isSelected,
              onSelected: (_) => onChanged(index),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? onSurface : inactive,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: theme.cardColor,
              selectedColor: selectedBg,
              shape: const StadiumBorder(),
              side: BorderSide(color: isSelected ? selectedBg : borderColor),
            ),
          ),
        );
      }),
    );
  }
}

enum _HeaderAction { pickImage, removeImage }

