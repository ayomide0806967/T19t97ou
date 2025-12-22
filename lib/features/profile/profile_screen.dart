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
part 'profile_screen_actions.dart';
part 'profile_screen_images.dart';
part 'profile_screen_sheets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.handleOverride, this.readOnly = false});

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
    final email =
        context.read<AuthRepository>().currentUser?.email ??
        'user@institution.edu';
    final initials = initialsFrom(widget.handleOverride ?? email);
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
