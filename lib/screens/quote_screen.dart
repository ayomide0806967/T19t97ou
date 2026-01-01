import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/posts/application/quote_controller.dart';
import '../core/ui/app_toast.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../features/auth/application/session_providers.dart';

class QuoteScreen extends ConsumerStatefulWidget {
  const QuoteScreen({
    super.key,
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    required this.initials,
    this.tags = const <String>[],
    this.onPostQuote,
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final String initials;
  final List<String> tags;
  final Function(String comment)? onPostQuote;

  @override
  ConsumerState<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends ConsumerState<QuoteScreen> {
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quote Post',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _canPost() ? _postQuote : null,
            child: Text(
              'Post',
              style: TextStyle(
                color: _canPost() ? AppTheme.accent : const Color(0xFFCBD5E1),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current user info
                  Row(
                    children: [
                      HexagonAvatar(
                        size: 48,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'your@institution.edu',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quote input field
                  TextField(
                    controller: _controller,
                    maxLines: null,
                    autofocus: true,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      filled: false,
                      isDense: true,
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Original post preview
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quote indicator
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.format_quote,
                                size: 16,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quoting Post',
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Original post author
                              Row(
                                children: [
                                  HexagonAvatar(
                                    size: 32,
                                    child: Center(
                                      child: Text(
                                        widget.initials,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.author,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          '${widget.handle} • ${widget.timeAgo}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF64748B),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Original post content
                              Text(
                                widget.body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF475569),
                                ),
                              ),

                              // Original post tags
                              if (widget.tags.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: widget.tags
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.image_outlined,
                  label: 'Media',
                  onTap: () => AppToast.showSnack(
                    context,
                    'Media picker coming soon',
                    duration: const Duration(milliseconds: 1200),
                  ),
                ),
                const SizedBox(width: 24),
                _ToolbarButton(
                  icon: Icons.tag_outlined,
                  label: 'Tag',
                  onTap: () => AppToast.showSnack(
                    context,
                    'Tag functionality coming soon',
                    duration: const Duration(milliseconds: 1200),
                  ),
                ),
                const SizedBox(width: 24),
                _ToolbarButton(
                  icon: Icons.emoji_emotions_outlined,
                  label: 'Emoji',
                  onTap: () => AppToast.showSnack(
                    context,
                    'Emoji picker coming soon',
                    duration: const Duration(milliseconds: 1200),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_controller.text.length}/280',
                  style: TextStyle(
                    color: _controller.text.length > 280
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canPost() {
    return _controller.text.length <= 280 &&
        !_isPosting; // Allow empty text for quotes
  }

  void _postQuote() async {
    if (!_canPost()) return;

    setState(() {
      _isPosting = true;
    });

    final handle = ref.read(currentUserHandleProvider);
    await ref.read(quoteControllerProvider.notifier).addQuote(
          author: handle.isEmpty ? 'You' : handle,
          handle: handle,
          comment: _controller.text.trim(),
          original: PostSnapshot(
            author: widget.author,
            handle: widget.handle,
            timeAgo: widget.timeAgo,
            body: widget.body,
            tags: widget.tags,
          ),
        );

    if (!mounted) return;
    Navigator.pop(context);
  }

}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF64748B)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
