import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';

/// Minimal, modern full-page composer (no modals, no quick actions).
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, this.onPostCreated});

  final Function(String content, List<String> tags, List<String> media)? onPostCreated;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;
  final List<XFile> _media = <XFile>[];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
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
                color: Color(0xFF38BDF8),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable area: header + text editor
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HexagonAvatar(
                        size: 44,
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('your@institution.edu', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _AudienceChip(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: "What's happening?",
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _RecentMediaStrip(media: _media),
                  const SizedBox(height: 12),
                  const _ReplyPermissionsRow(),
                  const SizedBox(height: 8),
                  _ComposerActionsRow(onPickImages: _pickImages),
                ],
              ),
            ),

            // Character count, pinned to bottom; let Scaffold handle
            // keyboard insets to avoid overflow.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_controller.text.length}/280',
                  style: TextStyle(
                    color: _controller.text.length > 280
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canPost => _controller.text.trim().isNotEmpty && _controller.text.length <= 280 && !_isPosting;

  Future<void> _post() async {
    if (!_canPost) return;
    setState(() => _isPosting = true);
    await context.read<DataService>().addPost(
          author: 'You',
          handle: '@yourprofile',
          body: _controller.text.trim(),
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post published'), duration: Duration(milliseconds: 900)),
    );
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

/// Audience chip ("Everyone") shown under the profile row.
class _AudienceChip extends StatelessWidget {
  const _AudienceChip();

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
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audience controls coming soon'),
              duration: Duration(milliseconds: 900),
            ),
          );
        },
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
                'Everyone',
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
class _ReplyPermissionsRow extends StatelessWidget {
  const _ReplyPermissionsRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color subtle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final Color border =
        theme.dividerColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.45 : 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: border, width: 0.6),
          bottom: BorderSide(color: border, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.public_rounded, size: 18, color: subtle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Everyone can reply',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reply controls coming soon'),
                  duration: Duration(milliseconds: 900),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom row of composer tools: text, GIF, poll, location, etc.
class _ComposerActionsRow extends StatelessWidget {
  const _ComposerActionsRow({required this.onPickImages});

  final VoidCallback onPickImages;

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
          ),
          tool(
            icon: const Icon(Icons.image_outlined),
            onTap: onPickImages,
          ),
          tool(
            icon: const Text(
              'GIF',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          tool(icon: const Icon(Icons.bar_chart_rounded)),
          tool(icon: const Icon(Icons.location_on_outlined)),
          tool(icon: const Icon(Icons.add_circle_outline_rounded)),
        ],
      ),
    );
  }
}
