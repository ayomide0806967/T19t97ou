import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/app_providers.dart';
import '../../core/user/handle.dart';
import '../../core/ui/initials.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../widgets/tweet_post_card.dart';
import '../../widgets/app_tab_scaffold.dart';
import '../../core/ui/app_toast.dart';
import '../../core/supabase/supabase_post_repository.dart';
import '../../theme/app_theme.dart';
import '../../constants/toast_durations.dart';
import '../../screens/edit_profile_screen.dart';
import '../../screens/settings_screen.dart';
import '../messages/replies/message_replies_route.dart';
import '../messages/messages_screen.dart';

part 'profile_screen_parts.dart';
part 'profile_screen_header.dart';
part 'profile_screen_stats.dart';
part 'profile_screen_actions.dart';
part 'profile_screen_images.dart';
part 'profile_screen_sheets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.handleOverride,
    this.readOnly = false,
    this.initialTab = 0,
  });

  final String? handleOverride;
  final bool readOnly;
  final int initialTab;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
  int _followersCount = 0;
  int _followingCount = 0;

  void _setLocalHeaderImage(Uint8List? bytes) {
    if (!mounted) return;
    setState(() => _headerImage = bytes);
  }

  void _setLocalProfileImage(Uint8List? bytes) {
    if (!mounted) return;
    setState(() => _profileImage = bytes);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTab;
    _selectedTab = initial < 0 ? 0 : (initial > 2 ? 2 : initial);
    _refreshFollowCounts();
  }

  String get _authHandle {
    return deriveHandleFromEmail(
      ref.read(authRepositoryProvider).currentUser?.email,
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

  String get _bioText => _bioOverride ?? '';

  Future<void> _refreshFollowCounts() async {
    if (!mounted) return;
    if (widget.readOnly || widget.handleOverride != null) return;
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    final profileRepo = ref.read(profileRepositoryProvider);
    try {
      final followers = await profileRepo.getFollowerCount(userId);
      final following = await profileRepo.getFollowingCount(userId);
      if (!mounted) return;
      setState(() {
        _followersCount = followers;
        _followingCount = following;
      });
    } catch (_) {
      // Keep defaults (0) if unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = ref.watch(postRepositoryProvider);
    final profileRepository = ref.read(profileRepositoryProvider);
    final currentUserHandle = _currentUserHandle;
    final email =
        ref.read(authRepositoryProvider).currentUser?.email ??
        'user@institution.edu';
    final initials = initialsFrom(widget.handleOverride ?? email);
    final posts = repository.postsForHandle(currentUserHandle);
    final replies = repository.repliesForHandle(currentUserHandle);
    final bookmarks = widget.readOnly
        ? const <PostModel>[]
        : repository.bookmarkedPosts();

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
      if (_selectedTab == 1) return 'No bookmarks yet.';
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
      await _refreshFollowCounts();
      AppToast.showSnack(
        context,
        'Profile changes saved',
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
          onRefresh: () async {
            await _handlePullToRefresh();
            await _refreshFollowCounts();
          },
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: StreamBuilder<UserProfile>(
                  stream: profileRepository.watchProfile(),
                  initialData: profileRepository.profile,
                  builder: (context, snapshot) {
                    final profile = snapshot.data ?? profileRepository.profile;
                    final bio = widget.readOnly
                        ? ''
                        : (_bioOverride ?? profile.bio.trim());
                    final likesCount =
                        posts.fold<int>(0, (sum, p) => sum + p.likes);
                    final activityProgress =
                        posts.isEmpty ? 0.0 : (posts.length / 10).clamp(0.0, 1.0);
                    final headerUrl = (!widget.readOnly &&
                            widget.handleOverride == null)
                        ? profile.headerUrl
                        : null;
                    final avatarUrl = (!widget.readOnly &&
                            widget.handleOverride == null)
                        ? profile.avatarUrl
                        : null;
                    return _ProfileHeader(
                      headerImage: _headerImage,
                      headerImageUrl: headerUrl,
                      profileImage: _profileImage,
                      profileImageUrl: avatarUrl,
                      initials: initials,
                      displayName: displayName,
                      handle: currentUserHandle,
                      bio: bio,
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
                      followersCount: _followersCount,
                      followingCount: _followingCount,
                      likesCount: likesCount,
                      activityLevelLabel: 'Novice',
                      activityProgress: activityProgress,
                    );
                  },
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final post = visiblePosts[index];
                      final theme = Theme.of(context);
                      final bool isDark = theme.brightness == Brightness.dark;
                      final Color line = theme.colorScheme.onSurface.withValues(
                        alpha: isDark ? 0.12 : 0.06,
                      );

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
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: TweetPostCard(
                                key: ValueKey(post.id),
                                post: post,
                                currentUserHandle: currentUserHandle,
                                showRepostToast: false,
                                onReply: (_) {
                                  Navigator.of(context).push(
                                    messageRepliesRouteFromPost(
                                      post: post,
                                      currentUserHandle: currentUserHandle,
                                    ),
                                  );
                                },
                                onTap: () {
                                  Navigator.of(context).push(
                                    messageRepliesRouteFromPost(
                                      post: post,
                                      currentUserHandle: currentUserHandle,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: visiblePosts.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
