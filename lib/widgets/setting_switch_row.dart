import 'package:flutter/material.dart';

class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.monochrome = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: monochrome ? Colors.white : null,
            activeTrackColor: monochrome ? Colors.black : null,
            inactiveThumbColor: monochrome ? Colors.black : null,
            inactiveTrackColor: monochrome ? Colors.white : null,
          ),
        ],
      ),
    );
  }
}

