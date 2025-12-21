import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_repository.dart';
import '../core/feed/post_repository.dart';
import '../core/user/handle.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';

/// Minimal, modern full-page composer (no modals, no quick actions).
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, this.onPostCreated});

  final Function(String content, List<String> tags, List<String> media)? onPostCreated;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

enum ReplyPermission {
  everyone,
  following,
  mentioned,
}

enum _ExitAction { delete, save }

class _ComposeScreenState extends State<ComposeScreen> {
  final TextEditingController _controller =
      _LimitHighlightController(maxChars: 280);
  final FocusNode _textFocusNode = FocusNode();
  bool _isPosting = false;
  final List<XFile> _media = <XFile>[];
  final ImagePicker _picker = ImagePicker();
  ReplyPermission _replyPermission = ReplyPermission.everyone;
  bool _largeText = false;

  @override
  void dispose() {
    _controller.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasUnsavedChanges) {
          Navigator.of(context).pop();
          return;
        }
        await _handleExit();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            onPressed: _handleExit,
          ),
          title: const Text(
            'New Post',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Drafts coming soon'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              },
              child: const Text(
                'Drafts',
                style: TextStyle(
                  color: Color(0xFF128C7E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: _canPost ? _post : null,
              child: Text(
                'Post',
                style: TextStyle(
                  color: _canPost ? AppTheme.accent : const Color(0xFFCBD5E1),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Bring the keyboard back when user taps anywhere while it's hidden.
            if (MediaQuery.of(context).viewInsets.bottom == 0) {
              FocusScope.of(context).requestFocus(_textFocusNode);
            }
          },
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scrollable area: header + text editor
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      HexagonAvatar(
                        size: 44,
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _AudienceChip(
                            label: _replyPermissionLabel,
                            onTap: _onAudienceTap,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _textFocusNode,
                    autofocus: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: "What's happening?",
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: _largeText ? 20 : 16,
                      color: Colors.black,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _RecentMediaStrip(media: _media),
                  const SizedBox(height: 12),
                  const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Actions + character count row, pinned just above keyboard.
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ComposerActionsRow(
                            onPickImages: _pickImages,
                            onToggleTextStyle: _toggleTextSize,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_controller.text.length}/280',
                          style: TextStyle(
                            color: _controller.text.length > 280
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
          ),
        ),
      ),
      ),
    );
  }

  bool get _canPost =>
      (_controller.text.trim().isNotEmpty || _media.isNotEmpty) &&
      _controller.text.length <= 280 &&
      !_isPosting;
  bool get _hasUnsavedChanges => _controller.text.trim().isNotEmpty || _media.isNotEmpty;

  String get _currentUserHandle {
    return deriveHandleFromEmail(
      context.read<AuthRepository>().currentUser?.email,
      fallback: '@yourprofile',
    );
  }

  String get _replyPermissionLabel {
    switch (_replyPermission) {
      case ReplyPermission.everyone:
        return 'Everyone can reply';
      case ReplyPermission.following:
        return 'People you follow';
      case ReplyPermission.mentioned:
        return 'Only people you mention';
    }
  }

  void _toggleTextSize() {
    setState(() {
      _largeText = !_largeText;
    });
  }

  Future<void> _onAudienceTap() async {
    final result = await showModalBottomSheet<ReplyPermission>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who can reply?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _ReplyOptionTile(
                  title: 'Everyone can reply',
                  subtitle: 'Anyone on the platform can respond.',
                  selected: _replyPermission == ReplyPermission.everyone,
                  onTap: () =>
                      Navigator.of(ctx).pop(ReplyPermission.everyone),
                ),
                _ReplyOptionTile(
                  title: 'People you follow',
                  subtitle: 'Only people you follow can reply.',
                  selected: _replyPermission == ReplyPermission.following,
                  onTap: () =>
                      Navigator.of(ctx).pop(ReplyPermission.following),
                ),
                _ReplyOptionTile(
                  title: 'Only people you mention',
                  subtitle: 'Only accounts you mention can reply.',
                  selected: _replyPermission == ReplyPermission.mentioned,
                  onTap: () =>
                      Navigator.of(ctx).pop(ReplyPermission.mentioned),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _replyPermission = result;
      });
    }
  }

  Future<void> _post() async {
    if (!_canPost) return;
    setState(() => _isPosting = true);
    final handle = _currentUserHandle;
    final email = context.read<AuthRepository>().currentUser?.email;
    final author = email?.split('@').first.trim();
    await context.read<PostRepository>().addPost(
          author: author == null || author.isEmpty ? 'You' : author,
          handle: handle,
          body: _controller.text.trim(),
          mediaPaths: _media.map((f) => f.path).toList(),
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _handleExit() async {
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    FocusScope.of(context).unfocus();

    final action = await showDialog<_ExitAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Save post?'),
        content: const Text(
          'You can save this to send later from your Drafts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.delete),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == _ExitAction.delete) {
      Navigator.pop(context);
      return;
    }

    if (action == _ExitAction.save) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to drafts'),
          duration: Duration(milliseconds: 900),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage();
      if (!mounted || files.isEmpty) return;
      setState(() {
        _media
          ..clear()
          ..addAll(files);
      });
    } catch (_) {
      // Silent for now; could surface an error toast.
    }
  }
}

/// Horizontal preview strip for user-selected gallery items.
/// Appears under the compose text field and can be swiped left/right.
class _RecentMediaStrip extends StatelessWidget {
  const _RecentMediaStrip({required this.media});

  final List<XFile> media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.3);
    final Color placeholderBg =
        theme.colorScheme.surface.withValues(alpha: isDark ? 0.6 : 1.0);

    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    final int itemCount = media.length;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                child: Image.file(
                  File(file.path),
                  fit: BoxFit.cover,
                ),
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
    }.toList()
      ..sort();

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
      segmentStyle = segmentStyle.copyWith(decoration: TextDecoration.underline);
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

    Widget tool({
      required Widget icon,
      VoidCallback? onTap,
    }) =>
        IconButton(
          onPressed: onTap ??
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
          tool(
            icon: const Icon(Icons.image_outlined),
            onTap: onPickImages,
          ),
          tool(
            icon: const Icon(Icons.quiz_outlined),
          ),
        ],
      ),
    );
  }
}
