import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'quiz_palette.dart';

class QuizLabeledField extends StatelessWidget {
  const QuizLabeledField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
    this.textInputAction,
    this.backgroundColor,
    this.autoExpand = true,
    this.trailing,
    this.suffixIcon,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;
  final TextInputAction? textInputAction;
  final Color? backgroundColor;
  final bool autoExpand;
  final Widget? trailing;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color fieldBackground = backgroundColor ?? theme.colorScheme.surface;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color outlineBase = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.35 : 0.25,
    );
    final Color focusColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty || trailing != null) ...[
          Row(
            children: [
              if (label.isNotEmpty)
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: autoExpand ? null : maxLines,
          minLines: autoExpand ? maxLines : null,
          textInputAction: textInputAction,
          inputFormatters: maxLines == 1
              ? [FilteringTextInputFormatter.singleLineFormatter]
              : null,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: isDark ? Colors.white : Colors.black,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: fieldBackground,
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBase, width: 1.3),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBase, width: 1.3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
