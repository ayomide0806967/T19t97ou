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
                  const _RecentMediaStrip(),
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
}

/// Horizontal preview strip for user-selected gallery items (using image_picker).
/// Appears under the compose text field and can be swiped left/right.
class _RecentMediaStrip extends StatefulWidget {
  const _RecentMediaStrip();

  @override
  State<_RecentMediaStrip> createState() => _RecentMediaStripState();
}

class _RecentMediaStripState extends State<_RecentMediaStrip> {
  final List<XFile> _selected = <XFile>[];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage();
      if (!mounted || files.isEmpty) return;
      setState(() {
        _selected
          ..clear()
          ..addAll(files);
      });
    } catch (_) {
      // Swallow errors for now; could show a SnackBar if needed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.3);
    final Color placeholderBg =
        theme.colorScheme.surface.withValues(alpha: isDark ? 0.6 : 1.0);

    final int itemCount = 1 + _selected.length;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _pickImages,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: placeholderBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 26,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final XFile file = _selected[index - 1];

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
