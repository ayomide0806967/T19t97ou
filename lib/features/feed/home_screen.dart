import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_nav.dart';
import '../../core/ui/initials.dart';
import '../../models/post.dart';
import '../../screens/compose_screen.dart';
import '../../screens/settings_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_tab_scaffold.dart';
import '../../widgets/swiss_bank_icon.dart';
import '../auth/application/auth_controller.dart';
import '../auth/application/session_providers.dart';
import '../classes/application/class_providers.dart';
import '../../widgets/tweet_post_card.dart';
import '../messages/replies/message_replies_route.dart';
import 'application/feed_controller.dart';
import 'home_screen_parts.dart';
import 'home_screen_overlays.dart';



class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final GlobalKey<NestedScrollViewState> _nestedScrollKey =
      GlobalKey<NestedScrollViewState>();
  late final TabController _tabController;
  late final AnimationController _logoRefreshController;
  bool _isRefreshingFeed = false;
  double _tabOverscrollAccum = 0;
  bool _openedQuickControlsFromSwipe = false;
  bool _quickControlsSheetOpen = false;
  int? _quickControlsSwipePointer;
  Offset? _quickControlsSwipeStart;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _logoRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _logoRefreshController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePullToRefresh() async {
    if (_isRefreshingFeed) return;
    setState(() => _isRefreshingFeed = true);
    _logoRefreshController.repeat();

    try {
      HapticFeedback.lightImpact();
      await ref.read(feedControllerProvider.notifier).refresh();
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
    final state = _nestedScrollKey.currentState;
    final futures = <Future<void>>[];

    final outer = state?.outerController;
    if (outer != null && outer.hasClients && outer.offset > 0) {
      futures.add(
        outer.animateTo(
          0,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        ),
      );
    }

    final inner = state?.innerController;
    if (inner != null && inner.hasClients && inner.offset > 0) {
      futures.add(
        inner.animateTo(
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
    final feedState = ref.watch(feedControllerProvider);
    final baseTimeline = feedState.posts;
    final currentUserHandle = ref.watch(currentUserHandleProvider);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color line = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.12 : 0.06,
    );
    const Color accent = Color(0xFFFFB066);

    final TextStyle labelStyle =
        theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

    return AppTabScaffold(
      currentIndex: 0,
      isHomeRoot: true,
      onHomeReselect: _scrollFeedToTop,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          key: _nestedScrollKey,
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  floating: true,
                  pinned: false,
                  snap: true,
                  elevation: 0,
                  forceElevated: innerBoxIsScrolled,
                  automaticallyImplyLeading: false,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: IconButton(
                      icon: const TwoLineMenuIcon(),
                      splashRadius: 22,
                      onPressed: _showQuickControlPanel,
                    ),
                  ),
                  backgroundColor:
                      theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
                  shadowColor: Colors.black.withValues(alpha: 0.05),
                  centerTitle: true,
                  title: _buildFeedLogo(context),
                  actions: [
                    RepaintBoundary(
                      child: IconButton(
                        tooltip: 'Search',
                        icon: const SearchIcon(
                          size: 28,
                          color: Color(0xFF9CA3AF),
                          strokeWidthFactor: 0.10,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(AppNav.trending());
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(44),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: line, width: 0.6),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: TabBar(
                            controller: _tabController,
                            indicator: const UnderlineTabIndicator(
                              borderSide: BorderSide(
                                color: accent,
                                width: 2,
                              ),
                              insets: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            dividerColor: line,
                            labelStyle: labelStyle.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            unselectedLabelStyle: labelStyle.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            labelColor: theme.colorScheme.onSurface.withValues(
                              alpha: 0.98,
                            ),
                            unselectedLabelColor:
                                theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                            tabs: const [
                              Tab(text: 'For You'),
                              Tab(text: 'Following'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _handleQuickControlsSwipePointerDown,
                onPointerMove: _handleQuickControlsSwipePointerMove,
                onPointerUp: _handleQuickControlsSwipePointerEnd,
                onPointerCancel: _handleQuickControlsSwipePointerEnd,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (_tabController.index != 0) return false;
                    if (notification.metrics.axis != Axis.horizontal) {
                      return false;
                    }

                    if (notification is ScrollStartNotification) {
                      _tabOverscrollAccum = 0;
                      _openedQuickControlsFromSwipe = false;
                      return false;
                    }

                    if (notification is OverscrollNotification) {
                      // On the first tab, swiping right past the start produces
                      // negative overscroll; use it as a gesture to open quick controls.
                      if (notification.overscroll < 0 &&
                          !_openedQuickControlsFromSwipe &&
                          !_quickControlsSheetOpen) {
                        _tabOverscrollAccum += -notification.overscroll;
                        if (_tabOverscrollAccum >= 12) {
                          _openedQuickControlsFromSwipe = true;
                          _showQuickControlPanel();
                        }
                      }
                      return false;
                    }

                    if (notification is ScrollEndNotification) {
                      _tabOverscrollAccum = 0;
                      _openedQuickControlsFromSwipe = false;
                      return false;
                    }

                    return false;
                  },
                  child: Builder(
                    builder: (tabContext) => _buildFeedTab(
                      tabContext,
                      posts: _sortedTrending(baseTimeline),
                      currentUserHandle: currentUserHandle,
                      pageStorageKey:
                          const PageStorageKey<String>('feed_for_you'),
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (tabContext) => _buildFeedTab(
                  tabContext,
                  posts: baseTimeline,
                  currentUserHandle: currentUserHandle,
                  pageStorageKey:
                      const PageStorageKey<String>('feed_following'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTab(
    BuildContext context, {
    required List<PostModel> posts,
    required String currentUserHandle,
    required PageStorageKey<String> pageStorageKey,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color line = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.12 : 0.06,
    );

    return RefreshIndicator(
      color: Colors.black,
      notificationPredicate: (_) => true,
      onRefresh: _handlePullToRefresh,
      child: CustomScrollView(
        key: pageStorageKey,
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final classSource = ref.read(classSourceProvider);
                      final colleges =
                          classSource.userColleges(currentUserHandle);
                      return StoryRail(colleges: colleges);
                    },
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                final Border border = Border(
                  top: index == 0
                      ? BorderSide.none
                      : BorderSide(color: line, width: 0.6),
                  bottom: BorderSide(color: line, width: 0.6),
                );
                return RepaintBoundary(
                  key: ValueKey<String>('post_${post.id}'),
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
                );
              },
              childCount: posts.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedLogo(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      return Image.asset(
        'assets/images/in_logo.png',
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    return SwissBankIcon(
      size: 40,
      color: const Color(0xFF9CA3AF),
      strokeWidthFactor: 0.085,
      refreshProgress: _isRefreshingFeed ? _logoRefreshController : null,
    );
  }

  void _handleQuickControlsSwipePointerDown(PointerDownEvent event) {
    if (_tabController.index != 0) return;
    if (_quickControlsSheetOpen) return;
    _quickControlsSwipePointer = event.pointer;
    _quickControlsSwipeStart = event.position;
  }

  void _handleQuickControlsSwipePointerMove(PointerMoveEvent event) {
    if (_tabController.index != 0) return;
    if (_quickControlsSheetOpen) return;
    if (_openedQuickControlsFromSwipe) return;
    if (_quickControlsSwipePointer != event.pointer) return;

    final start = _quickControlsSwipeStart;
    if (start == null) return;

    final dx = event.position.dx - start.dx;
    final dy = event.position.dy - start.dy;
    if (dx >= 18 && dx > dy.abs() * 1.4) {
      _openedQuickControlsFromSwipe = true;
      _showQuickControlPanel();
    }
  }

  void _handleQuickControlsSwipePointerEnd(PointerEvent event) {
    if (_quickControlsSwipePointer != event.pointer) return;
    _quickControlsSwipePointer = null;
    _quickControlsSwipeStart = null;
    _tabOverscrollAccum = 0;
    _openedQuickControlsFromSwipe = false;
  }

  Future<void> _showQuickControlPanel() async {
    if (_quickControlsSheetOpen) return;
    _quickControlsSheetOpen = true;
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return QuickControlPanel(
            theme: theme,
            userCard: _buildUserProfileCard(),
            onNavigateHome: _scrollFeedToTop,
            onCompose: () async {
              navigator.pop();
              await navigator.push(
                MaterialPageRoute(builder: (_) => const ComposeScreen()),
              );
            },
            onSignOut: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _quickControlsSheetOpen = false;
          _tabOverscrollAccum = 0;
          _openedQuickControlsFromSwipe = false;
        });
      } else {
        _quickControlsSheetOpen = false;
      }
    }
  }

  Widget _buildUserProfileCard() {
    final email =
        ref.read(currentUserProvider)?.email ?? 'user@institution.edu';
    final initials = initialsFrom(email, fallback: 'IN');
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
                        '',
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
                          await ref.read(authControllerProvider.notifier)
                              .signOut();
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
      key: ValueKey<String>('tweet_${post.id}'),
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
