import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/simple_auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/brand_mark.dart';
import '../widgets/tweet_post_card.dart';
import 'post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  SimpleAuthService get _authService => SimpleAuthService();

  String get _currentUserHandle {
    final email = _authService.currentUserEmail;
    if (email == null || email.isEmpty) {
      return '@yourprofile';
    }
    final normalized = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').toLowerCase();
    if (normalized.isEmpty) {
      return '@yourprofile';
    }
    return '@$normalized';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();
    final posts = dataService.posts.where((p) => p.author == 'You' || p.handle == '@yourprofile').toList();
    final currentUserHandle = _currentUserHandle;

    void showToast(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      );
    }

    void handleEditProfile() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          final localTheme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: localTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  initialValue: 'Alex Rivera',
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '@productlead',
                  decoration: const InputDecoration(labelText: 'Handle'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue:
                      'Guiding nursing and midwifery teams through safe practice, exam preparation, and compassionate leadership.',
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showToast('Profile changes saved (coming soon)');
                    },
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    void handleShareProfile() {
      Clipboard.setData(const ClipboardData(text: 'https://academicnightingale.app/yourprofile'));
      showToast('Profile link copied to clipboard');
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 24),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(onEditProfile: handleEditProfile, onShareProfile: handleShareProfile),
                  const SizedBox(height: 32),
                  _ProfileTabs(
                    selectedIndex: _selectedTab,
                    onChanged: (index) {
                      setState(() => _selectedTab = index);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (posts.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Text(
                          "You haven't posted yet.",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ] else ...[
                    ...posts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TweetPostCard(
                              post: post,
                              currentUserHandle: currentUserHandle,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _openPostDetail(post),
                                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                label: const Text('View details'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPostDetail(PostModel post) {
    final payload = PostDetailPayload(
      author: post.author,
      handle: post.handle,
      timeAgo: post.timeAgo,
      body: post.body,
      initials: _initialsFrom(post.author),
      tags: post.tags,
      replies: post.replies,
      reposts: post.reposts,
      likes: post.likes,
      bookmarks: post.bookmarks,
      views: post.views,
      quoted: post.quoted != null
          ? PostDetailQuote(
              author: post.quoted!.author,
              handle: post.quoted!.handle,
              timeAgo: post.quoted!.timeAgo,
              body: post.quoted!.body,
            )
          : null,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: payload),
      ),
    );
  }

}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onEditProfile, required this.onShareProfile});

  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = SimpleAuthService();
    final email = auth.currentUserEmail ?? 'user@institution.edu';
    final accent = AppTheme.accent;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.58);
    final containerColor = isDark ? accent.withValues(alpha: 0.18) : accent.withValues(alpha: 0.1);
    final borderColor = accent.withValues(alpha: isDark ? 0.45 : 0.35);

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HexagonAvatar(
                size: 84,
                child: Center(
                  child: Text(
                    _initialsFrom(email),
                    style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex Rivera',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: onSurface,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '@productlead • ${email.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Guiding nursing and midwifery teams through safe practice, exam preparation, and compassionate leadership across our teaching hospital.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onSurface,
              height: 1.45,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: const [
                _PillTag('Clinical Education'),
                SizedBox(width: 8),
                _PillTag('Quality Improvement'),
                SizedBox(width: 8),
                _PillTag('Mentorship'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _ProfileStat(value: '18.4K', label: 'Followers'),
              SizedBox(width: 24),
              _ProfileStat(value: '1.2K', label: 'Following'),
              SizedBox(width: 24),
              _ProfileStat(value: '342', label: 'Clinical Moments'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onEditProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: onSurface,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onShareProfile,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: borderColor),
                    foregroundColor: onSurface,
                  ),
                  child: const Text('Share Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.6 : 0.55,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 18,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: subtle),
        ),
      ],
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = ['Moments', 'Highlights', 'Bookmarks'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final inactive = onSurface.withValues(alpha: isDark ? 0.55 : 0.5);
    final selectedBg = AppTheme.accent.withValues(alpha: isDark ? 0.24 : 0.12);
    final borderColor = theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.2);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_tabs.length, (index) {
        final isSelected = index == selectedIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: isSelected,
              onSelected: (_) => onChanged(index),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? onSurface : inactive,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: theme.cardColor,
              selectedColor: selectedBg,
              shape: const StadiumBorder(),
              side: BorderSide(color: isSelected ? AppTheme.accent : borderColor),
            ),
          ),
        );
      }),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF4B5563);

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme
          .bodyMedium
          ?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 11),
      backgroundColor: background,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}

String _initialsFrom(String value) {
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return 'IN';
  final count = letters.length >= 2 ? 2 : 1;
  return letters.substring(0, count).toUpperCase();
}
