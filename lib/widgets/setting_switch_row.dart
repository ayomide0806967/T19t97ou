import 'package:flutter/material.dart';

class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.monochrome = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                final bool selected = states.contains(WidgetState.selected);
                if (monochrome) {
                  return selected ? Colors.white : Colors.black;
                }
                return selected ? const Color(0xFF075E54) : Colors.black;
              },
            ),
            trackColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                final bool selected = states.contains(WidgetState.selected);
                if (monochrome) {
                  return selected ? Colors.black : Colors.white;
                }
                return selected
                    ? const Color(0xFF075E54).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.08);
              },
            ),
          ),
        ],
      ),
    );
  }
}
