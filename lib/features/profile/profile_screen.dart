import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/user/handle.dart';
import '../../core/feed/post_repository.dart';
import '../../core/ui/initials.dart';
import '../../models/post.dart';
import '../../widgets/tweet_post_card.dart';
import '../../widgets/app_tab_scaffold.dart';
import '../../core/ui/app_toast.dart';
import '../../theme/app_theme.dart';
import '../../constants/toast_durations.dart';
import '../../screens/edit_profile_screen.dart';
import '../../screens/settings_screen.dart';
import '../messages/replies/message_replies_route.dart';
import '../messages/messages_screen.dart';

part 'profile_screen_parts.dart';
part 'profile_screen_header.dart';
part 'profile_screen_stats.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.handleOverride,
    this.readOnly = false,
  });

  final String? handleOverride;
  final bool readOnly;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  Uint8List? _headerImage;
  Uint8List? _profileImage;
  String? _nameOverride;
  String? _bioOverride;
  final ImagePicker _picker = ImagePicker();
  bool _isRefreshing = false;
  bool _isFollowingOther = false;
  bool _notifyThreads = true;
  bool _notifyReplies = true;
  bool _pushNotificationsEnabled = false;

  void _showHeaderToast(String message) {
    AppToast.showTopOverlay(context, message, duration: ToastDurations.standard);
  }

  Future<void> _handlePickProfileImage() async {
    if (widget.readOnly) return;
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _profileImage = bytes);
    AppToast.showSnack(
      context,
      'Profile photo updated',
      duration: ToastDurations.standard,
    );
  }

  Future<void> _showProfilePhotoViewer() async {
    final bool hasImage = _profileImage != null;
    final String initials = initialsFrom(
      (context.read<AuthRepository>().currentUser?.email ??
          'user@institution.edu'),
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
                      AppToast.showSnack(
                        context,
                        'Profile photo removed',
                        duration: ToastDurations.standard,
                      );
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
                      AppToast.showSnack(
                        context,
                        'Cover photo removed',
                        duration: ToastDurations.standard,
                      );
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
          body: InteractiveViewer(
            constrained: false,
            minScale: 1.0,
            maxScale: 6.0,
            child: Center(
              child: Image(image: image, fit: BoxFit.none),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFullPlaceholder({
    required Widget child,
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
          body: Center(child: child),
        ),
      ),
    );
  }

  Future<void> _openProfilePhotoDirect() async {
    if (_profileImage != null) {
      return _openFullImage(
        image: MemoryImage(_profileImage!),
        title: 'Profile photo',
      );
    }
    final initials = initialsFrom(widget.handleOverride ?? _currentUserHandle);
    return _openFullPlaceholder(
      title: 'Profile photo',
      child: Container(
        width: 260,
        height: 260,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          initials,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    );
  }

  Future<void> _openHeaderPhotoDirect() async {
    if (_headerImage != null) {
      return _openFullImage(
        image: MemoryImage(_headerImage!),
        title: 'Cover photo',
      );
    }
    return _openFullPlaceholder(
      title: 'Cover photo',
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Icon(
              Icons.wallpaper_outlined,
              color: Colors.white70,
              size: 72,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleChangeHeader() async {
    if (widget.readOnly) return;
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
        AppToast.showSnack(
          context,
          'Cover photo updated',
          duration: ToastDurations.standard,
        );
        break;
      case _HeaderAction.removeImage:
        setState(() => _headerImage = null);
        AppToast.showSnack(
          context,
          'Cover photo removed',
          duration: ToastDurations.standard,
        );
        break;
      case null:
        break;
    }
  }

  Future<void> _handlePullToRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      HapticFeedback.lightImpact();
      await context.read<PostRepository>().load();
      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _handleMessageUser() async {
    if (!widget.readOnly) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MessagesScreen()),
    );
  }

  void _handleToggleFollow() {
    if (!widget.readOnly) return;
    final displayName =
        _nameOverride ?? _displayNameFromHandle(_currentUserHandle);
    setState(() {
      _isFollowingOther = !_isFollowingOther;
    });
    _showHeaderToast(
      _isFollowingOther
          ? 'You are now following $displayName'
          : 'You unfollowed $displayName',
    );
  }

  String get _authHandle {
    return deriveHandleFromEmail(
      context.read<AuthRepository>().currentUser?.email,
      fallback: '@yourprofile',
    );
  }

  String get _currentUserHandle {
    final override = widget.handleOverride;
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return _authHandle;
  }

  String _displayNameFromHandle(String handle) {
    final base = handle.replaceFirst(RegExp('^@'), '');
    if (base.isEmpty) return 'Profile';
    final parts = base.split(RegExp(r'[_\.]'));
    String name = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
    if (name.length > 13) {
      name = name.substring(0, 13);
    }
    return name;
  }

  String get _bioText =>
      _bioOverride ??
      'Guiding nursing and midwifery teams through safe practice, exam preparation, and compassionate leadership across our teaching hospital.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<PostRepository>();
    final currentUserHandle = _currentUserHandle;
    final email = context.read<AuthRepository>().currentUser?.email ??
        'user@institution.edu';
    final initials =
        initialsFrom(widget.handleOverride ?? email);
    final posts = dataService.postsForHandle(currentUserHandle);
    final replies = dataService.repliesForHandle(currentUserHandle);
    final bookmarks = posts.where((post) => post.bookmarks > 0).toList();

    final displayName = widget.readOnly
        ? _displayNameFromHandle(currentUserHandle)
        : (_nameOverride ?? _displayNameFromHandle(currentUserHandle));

    final List<PostModel> visiblePosts;
    switch (_selectedTab) {
      case 1:
        visiblePosts = bookmarks;
        break;
      case 2:
        visiblePosts = replies;
        break;
      default:
        visiblePosts = posts;
    }

    final emptyMessage = () {
      if (_selectedTab == 0) return "You haven't posted yet.";
      if (_selectedTab == 1) return 'No classes yet.';
      return 'No replies yet.';
    }();

    void handleEditProfile() async {
      if (widget.readOnly) return;
      final result = await Navigator.of(context).push<EditProfileResult>(
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(
            initialName: displayName,
            initialBio: _bioText,
            initials: initials,
            initialHeaderImage: _headerImage,
            initialProfileImage: _profileImage,
          ),
        ),
      );

      if (!mounted || result == null) return;
      setState(() {
        _headerImage = result.headerImage;
        _profileImage = result.profileImage;
        _nameOverride = result.name.isEmpty ? null : result.name;
        _bioOverride = result.bio.isEmpty ? null : result.bio;
      });
      AppToast.showSnack(
        context,
        'Profile changes saved (coming soon)',
        duration: ToastDurations.standard,
      );
    }

    void handleShareProfile() {
      final sanitizedHandle = currentUserHandle.startsWith('@')
          ? currentUserHandle.substring(1)
          : currentUserHandle;
      Clipboard.setData(
        ClipboardData(text: 'https://academicnightingale.app/$sanitizedHandle'),
      );
      AppToast.showSnack(
        context,
        'Profile link copied to clipboard',
        duration: ToastDurations.standard,
      );
    }

    void handleNotifications() {
      _openNotificationsSheet(handle: currentUserHandle);
    }

    void handleMore() {
      _openProfileMoreSheet(
        handle: currentUserHandle,
        showSettings: !widget.readOnly,
        onCopyLink: handleShareProfile,
      );
    }

    // Removed legacy local handleChangeHeader (replaced with _handleChangeHeader)

    return AppTabScaffold(
      currentIndex: 4,
      appBar: null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: Colors.black,
          onRefresh: _handlePullToRefresh,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  headerImage: _headerImage,
                  profileImage: _profileImage,
                  initials: initials,
                  displayName: displayName,
                  handle: currentUserHandle,
                  bio: _bioText,
                  readOnly: widget.readOnly,
                  onProfileImageTap: widget.readOnly
                      ? _openProfilePhotoDirect
                      : _showProfilePhotoViewer,
                  onHeaderTap: widget.readOnly
                      ? _openHeaderPhotoDirect
                      : _showHeaderImageViewer,
                  onChangeCover: _handleChangeHeader,
                  onEditProfile: handleEditProfile,
                  onMessage: _handleMessageUser,
                  onToggleFollow: _handleToggleFollow,
                  isFollowingOther: _isFollowingOther,
                  onNotifications: handleNotifications,
                  onMore: handleMore,
                  activityLevelLabel: 'Novice',
                  activityProgress: 0.5,
                ),
              ),
              SliverPadding(
                // Minimal vertical padding so the first tweet's divider
                // line touches the tabs.
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
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
                                  showRepostToast: false,
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
      ),
    );
  }

  Future<void> _openNotificationsSheet({required String handle}) async {
    final String label = handle.startsWith('@') ? handle.substring(1) : handle;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF2F2F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;
        final sheetSurface = isDark ? theme.colorScheme.surface : Colors.white;
        final onSurface = theme.colorScheme.onSurface;
        final subtle = onSurface.withValues(
          alpha: isDark ? 0.62 : 0.58,
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            final boxBorder = Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.18),
              width: 1,
            );

            Widget optionRow({
              required String title,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                trailing: selected
                    ? Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: onSurface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: sheetSurface,
                        ),
                      )
                    : Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: onSurface.withValues(
                              alpha: isDark ? 0.35 : 0.28,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                onTap: onTap,
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.22)
                              : const Color(0xFFBDBDBD),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sheetSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: boxBorder,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            optionRow(
                              title: 'Threads',
                              selected: _notifyThreads,
                              onTap: () => setModalState(() {
                                _notifyThreads = !_notifyThreads;
                              }),
                            ),
                            Divider(
                              height: 1,
                              thickness: 1.5,
                              indent: 16,
                              endIndent: 16,
                              color: theme.dividerColor.withValues(
                                alpha: isDark ? 0.28 : 0.34,
                              ),
                            ),
                            optionRow(
                              title: 'Replies',
                              selected: _notifyReplies,
                              onTap: () => setModalState(() {
                                _notifyReplies = !_notifyReplies;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sheetSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: boxBorder,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: Text(
                            'Push notifications',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          trailing: Semantics(
                            button: true,
                            toggled: _pushNotificationsEnabled,
                            label: 'Push notifications',
                            child: InkWell(
                              onTap: () => setModalState(() {
                                _pushNotificationsEnabled =
                                    !_pushNotificationsEnabled;
                              }),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOut,
                                width: 54,
                                height: 32,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: _pushNotificationsEnabled
                                      ? Colors.black
                                      : (isDark
                                          ? const Color(0xFF4A4A4A)
                                          : const Color(0xFFBDBDBD)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOut,
                                  alignment: _pushNotificationsEnabled
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "You'll get activity notifications for $label.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtle,
                            height: 1.3,
                          ),
                        ),
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

  Future<void> _openProfileMoreSheet({
    required String handle,
    required bool showSettings,
    required VoidCallback onCopyLink,
  }) async {
    final String label = handle.startsWith('@') ? handle.substring(1) : handle;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color sheetBg =
        isDark ? theme.colorScheme.surface : const Color(0xFFF2F2F2);
    final Color sheetSurface = isDark ? theme.colorScheme.surface : Colors.white;
    final Color onSurface = theme.colorScheme.onSurface;
    final Border boxBorder = Border.all(
      color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.18),
      width: 1,
    );

    Widget handleRow({
      required BuildContext context,
      required String title,
      required IconData icon,
      Color? textColor,
      Color? iconColor,
      VoidCallback? onTap,
    }) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor ?? onSurface,
          ),
        ),
        trailing: Icon(icon, color: iconColor ?? onSurface),
        onTap: onTap == null
            ? null
            : () {
                Navigator.of(context).pop();
                onTap();
              },
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final divider = Divider(
          height: 1,
          thickness: 1.2,
          indent: 18,
          endIndent: 18,
          color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.32),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: boxBorder,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        handleRow(
                          context: sheetContext,
                          title: 'QR Code',
                          icon: Icons.qr_code_2_rounded,
                          onTap: () => AppToast.showSnack(
                            context,
                            'QR code coming soon',
                            duration: ToastDurations.standard,
                          ),
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Copy profile link',
                          icon: Icons.link_rounded,
                          onTap: onCopyLink,
                        ),
                        divider,
                        handleRow(
                          context: sheetContext,
                          title: 'Share to',
                          icon: Icons.ios_share_rounded,
                          onTap: () => AppToast.showSnack(
                            context,
                            'Share sheet coming soon',
                            duration: ToastDurations.standard,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showSettings)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: boxBorder,
                      ),
                      child: handleRow(
                        context: sheetContext,
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        onTap: () {
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: boxBorder,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          handleRow(
                            context: sheetContext,
                            title: 'Block',
                            icon: Icons.block_rounded,
                            textColor: Colors.red,
                            iconColor: Colors.red,
                            onTap: () => AppToast.showSnack(
                              context,
                              'Blocked $label (coming soon)',
                              duration: ToastDurations.standard,
                            ),
                          ),
                          divider,
                          handleRow(
                            context: sheetContext,
                            title: 'Report',
                            icon: Icons.report_gmailerrorred_outlined,
                            textColor: Colors.red,
                            iconColor: Colors.red,
                            onTap: () => AppToast.showSnack(
                              context,
                              'Report $label (coming soon)',
                              duration: ToastDurations.standard,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: boxBorder,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Removed extra safety-actions card; block/report are above.
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
