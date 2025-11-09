import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../widgets/hexagon_avatar.dart';
import '../widgets/tagged_text_input.dart';
import '../widgets/tweet_composer_card.dart';
import '../services/data_service.dart';
import 'quiz_hub_screen.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, this.onPostCreated});

  final Function(String content, List<String> tags, List<String> media)?
  onPostCreated;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final TaggedTextEditingController _controller =
      TaggedTextEditingController();
  bool _isPosting = false;
  final List<String> _selectedMedia = [];
  final List<String> _selectedTags = [];

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
          onPressed: () => _showCancelDialog(),
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
            onPressed: _canPost() ? _postContent : null,
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
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TweetComposerCard(
                      controller: _controller,
                      onSubmit: (_) => _postContent(),
                      hintText: 'What\'s happening on the wards today?',
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      backgroundColor: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 1,
                        ),
                      ],
                      onImageTap: _addMedia,
                      onGifTap: () => _showToast('GIF library coming soon'),
                      onQuizTap: _openQuizHub,
                      textInputAction: TextInputAction.send,
                      isSubmitting: _isPosting,
                      onChanged: (_) => setState(() {}),
                      footer: _ComposerFooter(
                        selectedMedia: _selectedMedia,
                        selectedTags: _selectedTags,
                        onRemoveMedia: (index) {
                          setState(() {
                            _selectedMedia.removeAt(index);
                          });
                        },
                        onRemoveTag: (tag) {
                          setState(() {
                            _selectedTags.remove(tag);
                          });
                        },
                        onAddTag: _addTag,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.image_outlined,
                  label: 'Media',
                  onTap: _addMedia,
                ),
                const SizedBox(width: 24),
                _ToolbarButton(
                  icon: Icons.poll_outlined,
                  label: 'Poll',
                  onTap: () => _showToast('Poll creator coming soon'),
                ),
                const SizedBox(width: 24),
                _ToolbarButton(
                  icon: Icons.quiz_outlined,
                  label: 'Quiz',
                  onTap: _openQuizHub,
                ),
                const SizedBox(width: 24),
                _ToolbarButton(
                  icon: Icons.emoji_emotions_outlined,
                  label: 'Emoji',
                  onTap: () => _showToast('Emoji picker coming soon'),
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
    return _controller.text.trim().isNotEmpty &&
        _controller.text.length <= 280 &&
        !_isPosting;
  }

  void _addMedia() {
    setState(() {
      _selectedMedia.add('media_${DateTime.now().millisecondsSinceEpoch}');
    });
    _showToast('Media picker coming soon - placeholder added');
  }

  void _addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
      });
    }
  }

  Future<void> _openQuizHub() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizHubScreen()),
    );
  }

  void _showCancelDialog() {
    if (_controller.text.trim().isNotEmpty ||
        _selectedMedia.isNotEmpty ||
        _selectedTags.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard post?'),
          content: const Text('Any content you\'ve added will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _postContent() async {
    if (!_canPost()) return;

    setState(() {
      _isPosting = true;
    });

    // Simulate posting delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    await context.read<DataService>().addPost(
      author: 'You',
      handle: '@yourprofile',
      body: _controller.text.trim(),
      tags: List.of(_selectedTags),
    );

    if (!mounted) return;
    Navigator.pop(context);
    _showToast('Post published successfully!');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(milliseconds: 1200),
      ),
    );
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
      child: Padding(
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

class _ComposerFooter extends StatelessWidget {
  const _ComposerFooter({
    required this.selectedMedia,
    required this.selectedTags,
    required this.onRemoveMedia,
    required this.onRemoveTag,
    required this.onAddTag,
  });

  final List<String> selectedMedia;
  final List<String> selectedTags;
  final ValueChanged<int> onRemoveMedia;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onAddTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedMedia.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedMedia.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => onRemoveMedia(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (selectedTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedTags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => onRemoveTag(tag),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Quick Actions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickActionChip(
                label: 'Clinical Update',
                icon: Icons.campaign_outlined,
                onTap: () => onAddTag('Clinical Update'),
              ),
              _QuickActionChip(
                label: 'Study Tip',
                icon: Icons.event_outlined,
                onTap: () => onAddTag('Study Tip'),
              ),
              _QuickActionChip(
                label: 'Case Review',
                icon: Icons.help_outline,
                onTap: () => onAddTag('Case Review'),
              ),
              _QuickActionChip(
                label: 'Policy Alert',
                icon: Icons.update_outlined,
                onTap: () => onAddTag('Policy Alert'),
              ),
              _QuickActionChip(
                label: 'Competency Check',
                icon: Icons.emoji_events_outlined,
                onTap: () => onAddTag('Competency Check'),
              ),
              _QuickActionChip(
                label: 'Wellness',
                icon: Icons.forum_outlined,
                onTap: () => onAddTag('Wellness'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
