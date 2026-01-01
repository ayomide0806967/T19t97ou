import 'package:flutter/material.dart';

/// A text field with label and underline styling for profile editing.
class LinedField extends StatefulWidget {
  const LinedField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.minLines,
    this.autoExpand = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final int? minLines;
  final bool autoExpand;
  final ValueChanged<String>? onChanged;

  @override
  State<LinedField> createState() => _LinedFieldState();
}

class _LinedFieldState extends State<LinedField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _hasFocus = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: 0.45);

    final int? effectiveMinLines =
        widget.minLines ?? (widget.autoExpand ? 1 : widget.maxLines);
    final int? effectiveMaxLines = widget.autoExpand ? null : widget.maxLines;

    final Color dividerColor = _hasFocus
        ? const Color(0xFF00838F)
        : theme.dividerColor.withValues(alpha: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(color: subtle),
        ),
        Theme(
          data: theme.copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.only(top: 6, bottom: 10),
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            minLines: effectiveMinLines,
            maxLines: effectiveMaxLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              counterText: widget.maxLength != null ? '' : null,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onSurface,
              fontSize: 16,
            ),
          ),
        ),
        Divider(
          color: dividerColor,
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }
}

/// A tappable row with label and value for profile editing.
class LinedTapRow extends StatelessWidget {
  const LinedTapRow({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: valueColor,
                fontSize: 16,
              ),
            ),
          ),
          Divider(
            color: theme.dividerColor.withValues(alpha: 0.9),
            thickness: 1,
            height: 1,
          ),
        ],
      ),
    );
  }
}

/// A toggle row with label for profile editing.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: 0.45);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(valueLabel, style: theme.textTheme.bodySmall?.copyWith(color: subtle)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: const Color(0xFFF3F4F6),
      ),
      onTap: () => onChanged(!value),
    );
  }
}
