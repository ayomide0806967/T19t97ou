import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/user/handle.dart';
import '../../core/ui/initials.dart';
import '../../core/ui/snackbars.dart';
import '../../core/ui/quick_controls/quick_control_item.dart';
import '../../core/feed/post_repository.dart';
import '../../core/navigation/app_nav.dart';
import '../../models/post.dart';
import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hexagon_avatar.dart';
import '../../services/class_service.dart';
import '../../widgets/swiss_bank_icon.dart';
import '../../widgets/app_tab_scaffold.dart';
import '../../widgets/quick_control_grid.dart';
import '../../screens/compose_screen.dart';
import '../../widgets/tweet_post_card.dart';
import '../../screens/settings_screen.dart';
import '../messages/replies/message_replies_route.dart';

part 'home_screen_parts.dart';
part 'home_screen_overlays.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _outerScrollController = ScrollController();
  final ScrollController _forYouScrollController = ScrollController();
  final ScrollController _followingScrollController = ScrollController();
  int _selectedFeedTabIndex = 0;
  final PageController _feedPageController = PageController();
  late final AnimationController _logoRefreshController;
  bool _isRefreshingFeed = false;
  double _feedOverscrollAccum = 0;
  bool _openedQuickControlsFromSwipe = false;

  @override
  void initState() {
    super.initState();
    _logoRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _logoRefreshController.dispose();
    _feedPageController.dispose();
    _outerScrollController.dispose();
    _forYouScrollController.dispose();
    _followingScrollController.dispose();
    super.dispose();
  }

  Future<void> _handlePullToRefresh() async {
    if (_isRefreshingFeed) return;
    setState(() => _isRefreshingFeed = true);
    _logoRefreshController.repeat();

    try {
      HapticFeedback.lightImpact();
      await context.read<PostRepository>().load();
      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      if (mounted) {
        _logoRefreshController
          ..stop()
          ..value = 0;
        setState(() => _isRefreshingFeed = false);
      }
    }
  }

  void _scrollFeedToTop() {
    final futures = <Future<void>>[];

    if (_outerScrollController.hasClients &&
        _outerScrollController.offset > 0) {
      futures.add(
        _outerScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        ),
      );
    }

    final controller = _selectedFeedTabIndex == 0
        ? _forYouScrollController
        : _followingScrollController;
    if (controller.hasClients && controller.offset > 0) {
      futures.add(
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        ),
      );
    }

    if (futures.isEmpty) return;
    Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final baseTimeline = context.watch<PostRepository>().timelinePosts;
    final auth = context.read<AuthRepository>();
    final currentUserHandle = deriveHandleFromEmail(auth.currentUser?.email);

    return AppTabScaffold(
      currentIndex: 0,
      isHomeRoot: true,
      onHomeReselect: _scrollFeedToTop,
      body: NestedScrollView(
        controller: _outerScrollController,
        floatHeaderSlivers: true,
        physics: const ClampingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconButton(
                icon: const _TwoLineMenuIcon(),
                splashRadius: 22,
                onPressed: _showQuickControlPanel,
              ),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            centerTitle: true,
            title: SwissBankIcon(
              size: 30,
              color: const Color(0xFF9CA3AF),
              strokeWidthFactor: 0.085,
              refreshProgress: _isRefreshingFeed
                  ? _logoRefreshController
                  : null,
            ),
            actions: [
              RepaintBoundary(
                child: IconButton(
                  tooltip: 'Search',
                  icon: _SearchIcon(
                    size: 28,
                    color: const Color(0xFF9CA3AF),
                    strokeWidthFactor: 0.10,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(AppNav.trending());
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final bool isDark = theme.brightness == Brightness.dark;
                final Color line = theme.colorScheme.onSurface.withValues(
                  alpha: isDark ? 0.12 : 0.06,
                );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full-width divider line like X, with centered tab content.
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: line, width: 0.6),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _FeedTabBar(
                                selectedIndex: _selectedFeedTabIndex,
                                pageController: _feedPageController,
                                onChanged: (index) {
                                  if (mounted) {
                                    setState(
                                      () => _selectedFeedTabIndex = index,
                                    );
                                    _feedPageController.animateToPage(
                                      index,
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _StoryRail(
                            currentUserHandle: currentUserHandle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Only react on the "For You" page, and only for horizontal
            // PageView scrolling (ignore vertical ListView scroll).
            if (_selectedFeedTabIndex != 0) return false;
            if (notification.metrics.axis != Axis.horizontal) return false;

            if (notification is ScrollStartNotification) {
              _feedOverscrollAccum = 0;
              _openedQuickControlsFromSwipe = false;
              return false;
            }

            if (notification is OverscrollNotification) {
              // On the first page, a right swipe overscrolls past the min
              // extent (negative overscroll). Use that as the gesture to open
              // quick controls without interfering with normal tab swipes.
              if (notification.overscroll < 0 &&
                  !_openedQuickControlsFromSwipe) {
                _feedOverscrollAccum += -notification.overscroll;
                if (_feedOverscrollAccum >= 12) {
                  _openedQuickControlsFromSwipe = true;
                  _showQuickControlPanel();
                }
              }
              return false;
            }

            if (notification is ScrollEndNotification) {
              _feedOverscrollAccum = 0;
              _openedQuickControlsFromSwipe = false;
              return false;
            }

            return false;
          },
          child: PageView(
            controller: _feedPageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _selectedFeedTabIndex = index);
              }
            },
            children: [
              _buildFeedList(
                context,
                _sortedTrending(baseTimeline),
                currentUserHandle,
                controller: _forYouScrollController,
              ),
              _buildFeedList(
                context,
                baseTimeline,
                currentUserHandle,
                controller: _followingScrollController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedList(
    BuildContext context,
    List<PostModel> posts,
    String currentUserHandle, {
    ScrollController? controller,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color line = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.12 : 0.06,
    );

    final List<Widget> children = <Widget>[];
    for (int index = 0; index < posts.length; index++) {
      final post = posts[index];
      final Border border = Border(
        top: index == 0 ? BorderSide.none : BorderSide(color: line, width: 0.6),
        bottom: BorderSide(color: line, width: 0.6),
      );
      children.add(
        RepaintBoundary(
          child: Container(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 14, bottom: 1),
            decoration: BoxDecoration(border: border),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _PostCard(
                    post: post,
                    currentUserHandle: currentUserHandle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      notificationPredicate: (_) => true,
      onRefresh: _handlePullToRefresh,
      child: ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 10),
        children: children,
      ),
    );
  }

  void _showQuickControlPanel() {
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    final appSettings = context.read<AppSettings>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _QuickControlPanel(
          theme: theme,
          appSettings: appSettings,
          userCard: _buildUserProfileCard(),
          onNavigateHome: _scrollFeedToTop,
          onCompose: () async {
            navigator.pop();
            await navigator.push(
              MaterialPageRoute(builder: (_) => const ComposeScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildUserProfileCard() {
    final initials = initialsFrom(
      context.read<AuthRepository>().currentUser?.email ?? '',
      fallback: 'IN',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showProfileDropdown(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alex Rivera',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : const Color(0xFF2D3748),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF48BB78).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '18.4K',
                    style: TextStyle(
                      color: Color(0xFF48BB78),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDropdownItem(
                        icon: Theme.of(context).brightness == Brightness.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        title: 'Dark Mode',
                        trailing: Switch(
                          value:
                              Theme.of(context).brightness == Brightness.dark,
                          onChanged: (value) {
                            context.read<AppSettings>().toggleDarkMode(value);
                          },
                          activeTrackColor: const Color(
                            0xFF4299E1,
                          ).withValues(alpha: 0.5),
                          activeThumbColor: const Color(0xFF4299E1),
                        ),
                      ),
                      _buildDropdownItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDropdownItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildDropdownItem(
                        icon: Icons.help_outline,
                        title: 'Help',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 8),
                      _buildDropdownItem(
                        icon: Icons.logout_outlined,
                        title: 'Log out',
                        color: const Color(0xFFF56565),
                        onTap: () async {
                          Navigator.pop(context);
                          await context.read<AuthRepository>().signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    final itemColor = color ?? const Color(0xFF2D3748);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: itemColor, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  List<PostModel> _sortedTrending(List<PostModel> posts) {
    // Keep the "For You" feed in the same order as the base timeline
    // so newly created posts appear at the top of the main feed.
    return List<PostModel>.from(posts);
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.currentUserHandle});

  final PostModel post;
  final String currentUserHandle;

  @override
  Widget build(BuildContext context) {
    return TweetPostCard(
      post: post,
      currentUserHandle: currentUserHandle,
      showRepostBanner: true,
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
    );
  }
}
