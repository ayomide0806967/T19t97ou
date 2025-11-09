import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/simple_auth_service.dart';
import '../services/data_service.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/tweet_post_card.dart';
import 'screens/thread_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  int _headerThemeIndex = 0;
  Uint8List? _headerImage;
  final ImagePicker _picker = ImagePicker();
  SimpleAuthService get _authService => SimpleAuthService();

  static const List<List<Color>> _headerThemes = [
    [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
    [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
    [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
    [Color(0xFFF6D365), Color(0xFFFDA085)],
  ];

  String get _currentUserHandle {
    final email = _authService.currentUserEmail;
    if (email == null || email.isEmpty) {
      return '@yourprofile';
    }
    final normalized = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
    if (normalized.isEmpty) {
      return '@yourprofile';
    }
    return '@$normalized';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();
    final currentUserHandle = _currentUserHandle;
    final posts = dataService.postsForHandle(currentUserHandle);
    final replies = dataService.repliesForHandle(currentUserHandle);
    final bookmarks = posts.where((post) => post.bookmarks > 0).toList();

    final List<PostModel> visiblePosts;
    switch (_selectedTab) {
      case 1:
        visiblePosts = replies;
        break;
      case 2:
        visiblePosts = bookmarks;
        break;
      default:
        visiblePosts = posts;
    }

    final emptyMessage = () {
      if (_selectedTab == 0) return "You haven't posted yet.";
      if (_selectedTab == 1) return 'No replies yet.';
      return 'No bookmarks yet.';
    }();

    void showToast(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
                  style: localTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
      final sanitizedHandle = _currentUserHandle.startsWith('@')
          ? _currentUserHandle.substring(1)
          : _currentUserHandle;
      Clipboard.setData(
        ClipboardData(
          text: 'https://academicnightingale.app/$sanitizedHandle',
        ),
      );
      showToast('Profile link copied to clipboard');
    }

    Future<void> handleChangeHeader() async {
      final action = await showModalBottomSheet<_HeaderAction>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update cover image',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Choose from gallery'),
                      onTap: () => Navigator.of(context).pop(_HeaderAction.pickImage),
                    ),
                    ListTile(
                      leading: const Icon(Icons.brush_outlined),
                      title: const Text('Use gradient theme'),
                      onTap: () => Navigator.of(context).pop(_HeaderAction.pickGradient),
                    ),
                    if (_headerImage != null)
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Remove photo'),
                        onTap: () => Navigator.of(context).pop(_HeaderAction.removeImage),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ),
          );
        },
      );

      switch (action) {
        case _HeaderAction.pickImage:
          final XFile? file = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1600,
          );
          if (file == null) return;
          final bytes = await file.readAsBytes();
          setState(() {
            _headerImage = bytes;
          });
          showToast('Cover photo updated');
          break;
        case _HeaderAction.pickGradient:
          if (!context.mounted) return;
          final themeChoice = await showModalBottomSheet<int>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose gradient',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_headerThemes.length, (index) {
                        final colors = _headerThemes[index];
                        final gradient = LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        );
                        return ListTile(
                          leading: Container(
                            width: 56,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: gradient,
                            ),
                          ),
                          title: Text('Gradient ${index + 1}'),
                          trailing: _headerThemeIndex == index
                              ? const Icon(Icons.check, color: Colors.teal)
                              : null,
                          onTap: () => Navigator.of(context).pop(index),
                        );
                      }),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          if (themeChoice != null) {
            setState(() {
              _headerThemeIndex = themeChoice;
              _headerImage = null;
            });
            showToast('Gradient cover applied');
          }
          break;
        case _HeaderAction.removeImage:
          setState(() => _headerImage = null);
          showToast('Cover photo removed');
          break;
        case null:
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alex Rivera',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
                  _ProfileHeader(
                    headerColors: _headerThemes[_headerThemeIndex],
                    headerImage: _headerImage,
                    onChangeCover: handleChangeHeader,
                    onEditProfile: handleEditProfile,
                    onShareProfile: handleShareProfile,
                  ),
                  const SizedBox(height: 28),
                  _ProfileTabs(
                    selectedIndex: _selectedTab,
                    onChanged: (index) {
                      setState(() => _selectedTab = index);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (visiblePosts.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Text(
                          emptyMessage,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ] else ...[
                    ...visiblePosts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: TweetPostCard(
                          post: post,
                          currentUserHandle: currentUserHandle,
                          onTap: () {
                            final thread =
                                dataService.buildThreadForPost(post.id);
                            Navigator.of(context).push(
                              ThreadScreen.route(
                                entry: thread,
                                currentUserHandle: currentUserHandle,
                              ),
                            );
                          },
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

}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.headerColors,
    required this.headerImage,
    required this.onChangeCover,
    required this.onEditProfile,
    required this.onShareProfile,
  });

  final List<Color> headerColors;
  final Uint8List? headerImage;
  final VoidCallback onChangeCover;
  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = SimpleAuthService();
    final email = auth.currentUserEmail ?? 'user@institution.edu';
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.58);
    final containerColor = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: isDark ? 0.18 : 0.16);
    final borderColor = theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.28);
    final gradient = LinearGradient(
      colors: headerColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  height: 120,
                  decoration: headerImage != null
                      ? BoxDecoration(
                          image: DecorationImage(
                            image: MemoryImage(headerImage!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : BoxDecoration(gradient: gradient),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: TextButton.icon(
                    onPressed: onChangeCover,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black.withValues(alpha: 0.28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.wallpaper_outlined, size: 18),
                    label: const Text('Change cover'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HexagonAvatar(
                size: 72,
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
                      '@productlead',
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: subtle)),
      ],
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = ['Moments', 'Replies', 'Bookmarks'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final inactive = onSurface.withValues(alpha: isDark ? 0.55 : 0.5);
    final selectedBg = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.grey.withValues(alpha: 0.2);
    final borderColor = theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.25);
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
              side: BorderSide(
                color: isSelected ? selectedBg : borderColor,
              ),
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
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF4B5563);

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
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


enum _HeaderAction { pickImage, pickGradient, removeImage }
