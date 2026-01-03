import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/application/session_providers.dart';
import '../../core/di/app_providers.dart';
import '../../core/ui/app_toast.dart';
import '../../constants/toast_durations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hexagon_avatar.dart';
import 'application/compose_controller.dart';

part 'compose_screen_actions.dart';
part 'compose_screen_build.dart';

/// Minimal, modern full-page composer (no modals, no quick actions).
class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key, this.onPostCreated});

  final Function(String content, List<String> tags, List<String> media)?
  onPostCreated;

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

enum ReplyPermission { everyone, following, mentioned }

enum _ExitAction { delete, save }

/// Horizontal preview strip for user-selected gallery items.
/// Appears under the compose text field and can be swiped left/right.
class _RecentMediaStrip extends StatelessWidget {
  const _RecentMediaStrip({required this.media});

  final List<XFile> media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.4 : 0.3,
    );
    final Color placeholderBg = theme.colorScheme.surface.withValues(
      alpha: isDark ? 0.6 : 1.0,
    );

    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    final int itemCount = media.length;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final XFile file = media[index];

          return AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: placeholderBg,
                  border: Border.all(color: borderColor),
                ),
                child: Image.file(File(file.path), fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReplyOptionTile extends StatelessWidget {
  const _ReplyOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color subtle = onSurface.withValues(alpha: 0.65);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? primary : subtle,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: selected ? primary : onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: subtle),
      ),
    );
  }
}

/// TextEditingController that renders characters beyond [maxChars] in red.
class _LimitHighlightController extends TextEditingController {
  _LimitHighlightController({required this.maxChars});

  final int maxChars;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final fullText = text;
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    if (fullText.length <= maxChars) {
      if (!withComposing || !value.composing.isValid) {
        return TextSpan(text: fullText, style: baseStyle);
      }
      // Still handle composing so styling remains stable during IME input.
      final composing = value.composing;
      final before = fullText.substring(0, composing.start);
      final inComp = fullText.substring(composing.start, composing.end);
      final after = fullText.substring(composing.end);
      return TextSpan(
        style: baseStyle,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          if (inComp.isNotEmpty)
            TextSpan(
              text: inComp,
              style: baseStyle.copyWith(decoration: TextDecoration.underline),
            ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      );
    }

    final composing = withComposing && value.composing.isValid
        ? value.composing
        : TextRange.empty;

    final breakpoints = <int>{
      0,
      fullText.length,
      maxChars.clamp(0, fullText.length),
      if (composing.isValid) composing.start.clamp(0, fullText.length),
      if (composing.isValid) composing.end.clamp(0, fullText.length),
    }.toList()..sort();

    return TextSpan(
      style: baseStyle,
      children: [
        for (int i = 0; i < breakpoints.length - 1; i++)
          _segmentSpan(
            fullText,
            start: breakpoints[i],
            end: breakpoints[i + 1],
            baseStyle: baseStyle,
            overflowFrom: maxChars,
            composing: composing,
          ),
      ].whereType<TextSpan>().toList(),
    );
  }

  TextSpan? _segmentSpan(
    String fullText, {
    required int start,
    required int end,
    required TextStyle baseStyle,
    required int overflowFrom,
    required TextRange composing,
  }) {
    if (end <= start) return null;
    final segment = fullText.substring(start, end);
    if (segment.isEmpty) return null;

    final bool isOverflow = start >= overflowFrom;
    final bool isComposing =
        composing.isValid && start >= composing.start && end <= composing.end;

    TextStyle segmentStyle = baseStyle;
    if (isOverflow) {
      segmentStyle = segmentStyle.copyWith(
        color: Colors.red,
        backgroundColor: Colors.red.withValues(alpha: 0.08),
      );
    }
    if (isComposing) {
      segmentStyle = segmentStyle.copyWith(
        decoration: TextDecoration.underline,
      );
    }

    return TextSpan(text: segment, style: segmentStyle);
  }
}

/// Audience chip ("Everyone") shown under the profile row.
class _AudienceChip extends StatelessWidget {
  const _AudienceChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.6 : 0.35,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.public_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row showing "Everyone can reply" with an icon, similar to X.
/// Bottom row of composer tools: text, GIF, poll, location, etc.
class _ComposerActionsRow extends StatelessWidget {
  const _ComposerActionsRow({
    required this.onPickImages,
    required this.onToggleTextStyle,
  });

  final VoidCallback onPickImages;
  final VoidCallback onToggleTextStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    Widget tool({required Widget icon, VoidCallback? onTap}) => IconButton(
      onPressed:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Composer tools coming soon'),
                duration: Duration(milliseconds: 900),
              ),
            );
          },
      icon: icon,
      color: subtle,
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Row(
        children: [
          tool(
            icon: const Text(
              'Aa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            onTap: onToggleTextStyle,
          ),
          tool(icon: const Icon(Icons.image_outlined), onTap: onPickImages),
          tool(icon: const Icon(Icons.quiz_outlined)),
        ],
      ),
    );
  }
}
