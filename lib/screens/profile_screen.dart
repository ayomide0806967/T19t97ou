import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/simple_auth_service.dart';
import '../services/data_service.dart';
import '../widgets/tweet_post_card.dart';
import 'ios_messages_screen.dart' show messageRepliesRouteFromPost;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  Uint8List? _headerImage;
  Uint8List? _profileImage;
  final ImagePicker _picker = ImagePicker();
  SimpleAuthService get _authService => SimpleAuthService();

  void _showToast(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _handlePickProfileImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _profileImage = bytes);
    _showToast('Profile photo updated');
  }

  Future<void> _showProfilePhotoViewer() async {
    final bool hasImage = _profileImage != null;
    final String initials = _initialsFrom(
      (_authService.currentUserEmail ?? 'user@institution.edu'),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      image: hasImage
                          ? DecorationImage(
                              image: MemoryImage(_profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: hasImage
                        ? null
                        : Text(
                            initials,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                if (hasImage)
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _openFullImage(
                        image: MemoryImage(_profileImage!),
                        title: 'Profile photo',
                      );
                    },
                    child: const Text('View full picture'),
                  ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _handlePickProfileImage();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Change photo'),
                ),
                if (hasImage) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      setState(() => _profileImage = null);
                      _showToast('Profile photo removed');
                    },
                    child: const Text('Remove current photo'),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHeaderImageViewer() async {
    final theme = Theme.of(context);
    final hasImage = _headerImage != null;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 32,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasImage
                        ? Image.memory(_headerImage!, fit: BoxFit.cover)
                        : Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.wallpaper_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                if (hasImage)
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _openFullImage(
                        image: MemoryImage(_headerImage!),
                        title: 'Cover photo',
                      );
                    },
                    child: const Text('View full picture'),
                  ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _handleChangeHeader();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Change cover photo'),
                ),
                if (hasImage) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      setState(() => _headerImage = null);
                      _showToast('Cover photo removed');
                    },
                    child: const Text('Remove current photo'),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFullImage({
    required ImageProvider image,
    String? title,
  }) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: title != null ? Text(title) : null,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image(image: image, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleChangeHeader() async {
    final theme = Theme.of(context);
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
                  onTap: () =>
                      Navigator.of(context).pop(_HeaderAction.pickImage),
                ),
                if (_headerImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remove photo'),
                    onTap: () =>
                        Navigator.of(context).pop(_HeaderAction.removeImage),
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
        _showToast('Cover photo updated');
        break;
      case _HeaderAction.removeImage:
        setState(() => _headerImage = null);
        _showToast('Cover photo removed');
        break;
      case null:
        break;
    }
  }

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
    final email = _authService.currentUserEmail ?? 'user@institution.edu';
    final initials = _initialsFrom(email);
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
                      _showToast('Profile changes saved (coming soon)');
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
        ClipboardData(text: 'https://academicnightingale.app/$sanitizedHandle'),
      );
      _showToast('Profile link copied to clipboard');
    }

    // Removed legacy local handleChangeHeader (replaced with _handleChangeHeader)

    return Scaffold(
      appBar: null,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                headerImage: _headerImage,
                profileImage: _profileImage,
                initials: initials,
                onProfileImageTap: _showProfilePhotoViewer,
                onHeaderTap: _showHeaderImageViewer,
                onChangeCover: _handleChangeHeader,
                onEditProfile: handleEditProfile,
                onShareProfile: handleShareProfile,
                activityLevelLabel: 'Novice',
                activityProgress: 0.5,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              sliver: SliverToBoxAdapter(
                child: _ProfileTabs(
                  selectedIndex: _selectedTab,
                  onChanged: (index) {
                    setState(() => _selectedTab = index);
                  },
                ),
              ),
            ),
            if (visiblePosts.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 48,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      emptyMessage,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = visiblePosts[index];
                      final theme = Theme.of(context);
                      final bool isDark =
                          theme.brightness == Brightness.dark;
                      final Color line = theme.colorScheme.onSurface
                          .withValues(alpha: isDark ? 0.12 : 0.06);

                      final Border border = Border(
                        top: index == 0
                            ? BorderSide(color: line, width: 0.6)
                            : BorderSide.none,
                        bottom: BorderSide(color: line, width: 0.6),
                      );

                      return Container(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 8 : 14,
                          bottom: 14,
                        ),
                        decoration: BoxDecoration(border: border),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 720),
                              child: TweetPostCard(
                                key: ValueKey(post.id),
                                post: post,
                                currentUserHandle: currentUserHandle,
                                onReply: (_) {
                                  Navigator.of(context).push(
                                    messageRepliesRouteFromPost(
                                      post: post,
                                      currentUserHandle:
                                          currentUserHandle,
                                    ),
                                  );
                                },
                                onTap: () {
                                  Navigator.of(context).push(
                                    messageRepliesRouteFromPost(
                                      post: post,
                                      currentUserHandle:
                                          currentUserHandle,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: visiblePosts.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.headerImage,
    required this.profileImage,
    required this.initials,
    required this.onProfileImageTap,
    required this.onHeaderTap,
    required this.onChangeCover,
    required this.onEditProfile,
    required this.onShareProfile,
    required this.activityLevelLabel,
    required this.activityProgress,
  });

  final Uint8List? headerImage;
  final Uint8List? profileImage;
  final String initials;
  final VoidCallback onProfileImageTap;
  final VoidCallback onHeaderTap;
  final VoidCallback onChangeCover;
  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;
  final String activityLevelLabel;
  final double activityProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.58);
    final outlineColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.4 : 0.28,
    );
    final coverPlaceholderColor = theme.colorScheme.surfaceContainerHigh
        .withValues(alpha: isDark ? 0.32 : 0.6);

    final double screenWidth = MediaQuery.of(context).size.width;
    const double coverHeight = 200;
    const double avatarSize = 96;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width cover image with extended hit area for overlapping avatar
        SizedBox(
          width: screenWidth,
          height: coverHeight + avatarSize / 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover image layer
              GestureDetector(
                onTap: onHeaderTap,
                child: SizedBox(
                  width: double.infinity,
                  height: coverHeight,
                  child: headerImage != null
                      ? Image.memory(headerImage!, fit: BoxFit.cover)
                      : Container(color: coverPlaceholderColor),
                ),
              ),
              // Back button overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.28),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              // Change cover button
              Positioned(
                top: 12 + MediaQuery.of(context).padding.top,
                right: 12,
                child: IconButton(
                  onPressed: onChangeCover,
                  tooltip: 'Change cover photo',
                  icon: const Icon(Icons.wallpaper_outlined),
                  iconSize: 22,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black.withValues(alpha: 0.28),
                    padding: const EdgeInsets.all(10),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              // Rectangular avatar overlapping the cover by half (fully hittestable)
              Positioned(
                left: 24,
                bottom: 0,
                child: GestureDetector(
                  onTap: onProfileImageTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.12)
                            : Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: profileImage != null
                            ? DecorationImage(
                                image: MemoryImage(profileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: profileImage == null
                          ? Text(
                              initials,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                color: onSurface,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alex Rivera',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: onSurface,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '@productlead',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtle,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              // Followers and counts directly under name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProfileStat(value: '18.4K', label: 'Followers'),
                  const SizedBox(width: 24),
                  const _ProfileStat(value: '1.2K', label: 'Following'),
                  const SizedBox(width: 24),
                  const _ProfileStat(value: '5.8K', label: 'Likes'),
                  const SizedBox(width: 24),
                  _ProfileLevelStat(
                    label: activityLevelLabel,
                    progress: activityProgress,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Guiding nursing and midwifery teams through safe practice, exam preparation, and compassionate leadership across our teaching hospital.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: onSurface,
                  height: 1.45,
                  fontSize: 13.5,
                ),
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
                        side: BorderSide(color: outlineColor),
                        foregroundColor: onSurface,
                      ),
                      child: const Text('Share Profile'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

class _ProfileLevelStat extends StatelessWidget {
  const _ProfileLevelStat({required this.label, required this.progress});

  final String label;
  final double progress; // 0..1

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final barBg = onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.25 : 0.15,
    );
    final clamped = progress.clamp(0.0, 1.0);
    // Color-coded indicator fills the grey track as progress grows
    final Color barFg = _progressColor(theme, clamped);
    return InkWell(
      onTap: () => _openLevelDetails(context),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row matches the numeric "value" style of other stats
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 18,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 6),
          // Bottom row: progress bar track to align with labels row
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: 88,
              height: 8,
              child: Stack(
                children: [
                  Container(color: barBg),
                  FractionallySizedBox(
                    widthFactor: clamped,
                    child: Container(color: barFg),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressColor(ThemeData theme, double value) {
    final p = value.clamp(0.0, 1.0);
    if (p <= 0.30) {
      return Colors.red;
    }
    if (p <= 0.60) {
      // Dark cyan for mid-range progress
      return const Color(0xFF00838F);
    }
    return Colors.green;
  }

  void _openLevelDetails(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = progress.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    final levels = <Map<String, String>>[
      {
        'title': 'Novice',
        'desc': 'complete beginner; little to no experience.',
      },
      {
        'title': 'Beginner',
        'desc': 'has some exposure; starting to learn basics.',
      },
      {
        'title': 'Amateur',
        'desc':
            'learning actively but still inconsistent; not yet professional.',
      },
      {
        'title': 'Apprentice',
        'desc': 'under training or mentorship; gaining practical skill.',
      },
      {
        'title': 'Intermediate',
        'desc': 'understands fundamentals and can perform tasks with guidance.',
      },
      {
        'title': 'Competent',
        'desc': 'able to work independently with good understanding.',
      },
      {
        'title': 'Proficient',
        'desc':
            'skilled and efficient; sees patterns and solves problems effectively.',
      },
      {
        'title': 'Advanced',
        'desc': 'deep understanding; handles complex or unusual tasks.',
      },
      {
        'title': 'Expert',
        'desc': 'recognized authority; consistently performs at high level.',
      },
      {
        'title': 'Master',
        'desc': 'exceptional, creative, and innovative command of the field.',
      },
      {
        'title': 'Professional',
        'desc': 'performs for pay; adheres to standards and ethics.',
      },
    ];

    // Group levels into three stages, each with its own step rail section.
    final categories = [
      {
        'title': 'Foundations',
        'range': 'Novice – Apprentice',
        'indices': [0, 1, 2, 3],
      },
      {
        'title': 'Developing practice',
        'range': 'Intermediate – Advanced',
        'indices': [4, 5, 6, 7],
      },
      {
        'title': 'Expertise',
        'range': 'Expert – Professional',
        'indices': [8, 9, 10],
      },
    ];

    // Prefer mapping the current level from the label (e.g. "Novice")
    // so the highlighted row always matches what the user sees,
    // and fall back to the numeric progress if no label match is found.
    int currentLevelIndex = levels.indexWhere(
      (m) =>
          (m['title'] as String).toLowerCase() ==
          label.toLowerCase(),
    );
    if (currentLevelIndex < 0) {
      currentLevelIndex =
          (clamped * (levels.length - 1)).round().clamp(0, levels.length - 1);
    }

    int activeCategoryIndex;
    if (currentLevelIndex <= 3) {
      activeCategoryIndex = 0;
    } else if (currentLevelIndex <= 7) {
      activeCategoryIndex = 1;
    } else {
      activeCategoryIndex = 2;
    }

    int expandedCategoryIndex = 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final onSurface = theme.colorScheme.onSurface;
        final subtle = onSurface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.6 : 0.6,
        );
        final highlight = _progressColor(theme, clamped);

        const stageIcons = <IconData>[
          Icons.layers_rounded, // Foundations
          Icons.auto_graph_rounded, // Developing practice
          Icons.emoji_events_rounded, // Expertise
        ];

        return StatefulBuilder(
          builder: (innerCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom:
                      MediaQuery.of(innerCtx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Progress details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$percent% complete',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: subtle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 140,
                              height: 8,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Stack(
                                  children: [
                                    Container(
                                      color: onSurface.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: clamped,
                                      child: Container(color: highlight),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: (MediaQuery.of(innerCtx).size.height * 0.5)
                          .clamp(260.0, 420.0),
                      child: Stack(
                        children: [
                          // Single continuous vertical rail behind all steps
                          Positioned(
                            left: 16, // centered under 32px leading column
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: theme.dividerColor
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              children: List.generate(
                                  categories.length, (index) {
                        final cat = categories[index];
                        final isCurrentCategory = index == activeCategoryIndex;
                        final isCompletedCategory =
                            index < activeCategoryIndex;
                        final isExpanded = index == expandedCategoryIndex;

                        final circleColor = isCurrentCategory
                            ? highlight
                            : isCompletedCategory
                                ? highlight.withValues(alpha: 0.15)
                                : Colors.transparent;
                        final borderColor =
                            isCompletedCategory || isCurrentCategory
                                ? highlight
                                : subtle.withValues(alpha: 0.4);

                        final titleStyle = theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isCurrentCategory
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: onSurface,
                        );

                        final subtitleStyle =
                            theme.textTheme.bodySmall?.copyWith(
                          color: subtle,
                        );

                        final List<int> indices =
                            (cat['indices'] as List<int>);

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == categories.length - 1 ? 0 : 18,
                          ),
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                expandedCategoryIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Column(
                                    children: [
                                      if (index != 0)
                                        Container(
                                          width: 2,
                                          height: 18,
                                          color: isCurrentCategory
                                              ? Colors.black
                                              : Colors.transparent,
                                        ),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: circleColor,
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1.6,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: isCompletedCategory
                                            ? Icon(
                                                Icons.check,
                                                size: 14,
                                                color: isCurrentCategory
                                                    ? Colors.white
                                                    : highlight,
                                              )
                                            : Text(
                                                '${index + 1}',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: isCurrentCategory
                                                      ? Colors.white
                                                      : borderColor,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                      if (index != categories.length - 1)
                                        Container(
                                          width: 2,
                                          height: 26,
                                          color: isCurrentCategory
                                              ? Colors.black
                                              : Colors.transparent,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 180,
                                    ),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              stageIcons[index],
                                              size: 18,
                                              color: highlight,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              cat['title'] as String,
                                              style: titleStyle,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cat['range'] as String,
                                          style: theme
                                              .textTheme.labelSmall
                                              ?.copyWith(
                                            color: subtle,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isExpanded) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            // Keep each stage compact so the
                                            // next rail/category is still visible.
                                            height: 170,
                                            child: SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.only(
                                                right: 2,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: indices
                                                    .map((levelIndex) {
                                              final isUserLevel =
                                                  levelIndex ==
                                                      currentLevelIndex;
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                          bottom: 6,
                                                        ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: 8,
                                                            horizontal: 10,
                                                          ),
                                                          decoration:
                                                              isUserLevel
                                                                  ? BoxDecoration(
                                                                      color: highlight
                                                                          .withValues(
                                                                        alpha:
                                                                            0.06,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: highlight
                                                                            .withValues(
                                                                          alpha:
                                                                              0.7,
                                                                        ),
                                                                        width:
                                                                            1.1,
                                                                      ),
                                                                    )
                                                                  : BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                    ),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              if (isUserLevel)
                                                                ...[
                                                                  Icon(
                                                                    Icons
                                                                        .check_rounded,
                                                                    size: 18,
                                                                    color:
                                                                        highlight,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                ],
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      levels[levelIndex]['title'] ??
                                                                          '',
                                                                      style: theme
                                                                          .textTheme
                                                                          .bodyMedium
                                                                          ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color:
                                                                            onSurface,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 2,
                                                                    ),
                                                                    Text(
                                                                      levels[levelIndex]['desc'] ??
                                                                          '',
                                                                      style:
                                                                          subtitleStyle,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    final borderColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.4 : 0.25,
    );
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
              side: BorderSide(color: isSelected ? selectedBg : borderColor),
            ),
          ),
        );
      }),
    );
  }
}

// Removed unused _PillTag after header redesign

String _initialsFrom(String value) {
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return 'IN';
  final count = letters.length >= 2 ? 2 : 1;
  return letters.substring(0, count).toUpperCase();
}

enum _HeaderAction { pickImage, removeImage }
