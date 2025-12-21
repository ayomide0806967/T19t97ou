import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_repository.dart';
import '../core/user/handle.dart';
import '../core/feed/post_repository.dart';
import '../models/post.dart';
import '../widgets/tweet_post_card.dart';
import '../widgets/app_tab_scaffold.dart';
import '../core/ui/app_toast.dart';
import '../theme/app_theme.dart';
import '../constants/toast_durations.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../features/messages/replies/message_replies_route.dart';
import '../features/messages/messages_screen.dart';

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
    final String initials = _initialsFrom(
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
    final initials = _initialsFrom(widget.handleOverride ?? _currentUserHandle);
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
        _initialsFrom(widget.handleOverride ?? email);
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.headerImage,
    required this.profileImage,
    required this.initials,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.readOnly,
    required this.onProfileImageTap,
    required this.onHeaderTap,
    required this.onChangeCover,
    required this.onEditProfile,
    required this.onMessage,
    required this.onToggleFollow,
    required this.isFollowingOther,
    required this.onNotifications,
    required this.onMore,
    required this.activityLevelLabel,
    required this.activityProgress,
  });

  final Uint8List? headerImage;
  final Uint8List? profileImage;
  final String initials;
  final String displayName;
  final String handle;
  final String bio;
  final bool readOnly;
  final VoidCallback onProfileImageTap;
  final VoidCallback onHeaderTap;
  final VoidCallback onChangeCover;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onToggleFollow;
  final bool isFollowingOther;
  final VoidCallback onNotifications;
  final VoidCallback onMore;
  final String activityLevelLabel;
  final double activityProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.58);
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
              // Header actions (no camera icon)
              Positioned(
                top: 12 + MediaQuery.of(context).padding.top,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (readOnly) ...[
                      IconButton(
                        onPressed: onNotifications,
                        tooltip: 'Notifications',
                        icon: const Icon(Icons.notifications_none_outlined),
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
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: onMore,
                      tooltip: 'More',
                      icon: const Icon(Icons.more_horiz_rounded),
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
                  ],
                ),
              ),
              // Rectangular avatar overlapping the cover by half (fully hittestable)
              Positioned(
                left: 24,
                bottom: 0,
                child: GestureDetector(
                  onTap: onProfileImageTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
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
                        color: profileImage == null
                            ? (isDark
                                ? Colors.black.withValues(alpha: 0.12)
                                : Colors.white)
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
              if (!readOnly)
                Positioned(
                  right: 16,
                  bottom: -4,
                  child: OutlinedButton(
                    onPressed: onEditProfile,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Colors.black),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                    ),
                    child: const Text('Edit profile'),
                  ),
                )
              else
                Positioned(
                  right: 16,
                  bottom: -6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onMessage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          side: BorderSide(
                            color: onSurface.withValues(alpha: 0.25),
                          ),
                          foregroundColor: onSurface,
                          backgroundColor:
                              theme.colorScheme.surface.withValues(
                            alpha: isDark ? 0.8 : 0.9,
                          ),
                        ),
                        icon: const Icon(Icons.mail_outline_rounded, size: 16),
                        label: const Text(
                          'Message',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final bool isFollowing = isFollowingOther;
                          final Color followBg = isFollowing
                              ? Colors.transparent
                              : (isDark ? Colors.white : Colors.black);
                          final Color followFg = isFollowing
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.black : Colors.white);
                          final BorderSide followBorder = BorderSide(
                            color:
                                (isDark ? Colors.white : Colors.black)
                                    .withValues(
                              alpha: isFollowing ? 0.28 : 1,
                            ),
                            width: 1,
                          );

                          return OutlinedButton(
                            onPressed: onToggleFollow,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              side: followBorder,
                              foregroundColor: followFg,
                              backgroundColor: followBg,
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
                displayName,
                style: AppTheme.tweetBody(onSurface).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? onSurface
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                handle,
                style: AppTheme.tweetBody(subtle),
              ),
              const SizedBox(height: 12),
              Text(
                bio,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: onSurface,
                  height: 1.45,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 14),
              // Followers and counts under bio
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
                    interactive: !readOnly,
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
  const _ProfileLevelStat({
    required this.label,
    required this.progress,
    this.interactive = true,
  });

  final String label;
  final double progress; // 0..1
  final bool interactive;

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
      onTap: interactive ? () => _openLevelDetails(context) : null,
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

  static const _tabs = ['Posts', 'Classes', 'Replies'];

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
