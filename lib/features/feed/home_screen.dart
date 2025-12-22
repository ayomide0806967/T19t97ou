import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/user/handle.dart';
import '../../core/ui/initials.dart';
import '../../core/feed/post_repository.dart';
import '../../core/navigation/app_nav.dart';
import '../../models/post.dart';
import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hexagon_avatar.dart';
import '../../services/class_service.dart';
import '../../widgets/swiss_bank_icon.dart';
import '../../widgets/app_tab_scaffold.dart';
import '../../screens/compose_screen.dart';
import '../../widgets/tweet_post_card.dart';
import '../../screens/settings_screen.dart';
import '../messages/replies/message_replies_route.dart';

part 'home_screen_parts.dart';

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
              refreshProgress:
                  _isRefreshingFeed ? _logoRefreshController : null,
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

class _QuickControlPanel extends StatefulWidget {
  const _QuickControlPanel({
    required this.theme,
    required this.appSettings,
    required this.userCard,
    required this.onNavigateHome,
    required this.onCompose,
  });

  final ThemeData theme;
  final AppSettings appSettings;
  final Widget userCard;
  final VoidCallback onNavigateHome;
  final VoidCallback onCompose;

  @override
  State<_QuickControlPanel> createState() => _QuickControlPanelState();
}

class _QuickControlPanelState extends State<_QuickControlPanel> {
  late final List<_QuickControlItem> _items;
  late final List<bool> _activeStates;

  Future<void> _showComingSoon(String feature) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$feature is coming soon',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _items = [
      _QuickControlItem(
        icon: Icons.school_rounded,
        label: 'Class',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.classes());
        },
      ),
      _QuickControlItem(
        icon: Icons.mode_edit_outline_rounded,
        label: 'Post',
        onPressed: () async {
          Navigator.of(context).pop();
          widget.onCompose();
        },
      ),
      _QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Quiz',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.quizDashboard());
        },
      ),
      _QuickControlItem(
        icon: Icons.dark_mode_rounded,
        label: 'Dark Theme',
        onPressed: () async {
          final next = !widget.appSettings.isDarkMode;
          await widget.appSettings.toggleDarkMode(next);
          setState(() {
            _activeStates[3] = next;
          });
        },
      ),
      _QuickControlItem(
        icon: Icons.notifications_none_outlined,
        label: 'Notifications',
        onPressed: () async => _showComingSoon('Notifications'),
      ),
      _QuickControlItem(
        icon: Icons.forum_outlined,
        label: 'Messages',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.classes());
        },
      ),
      _QuickControlItem(
        icon: Icons.search_rounded,
        label: 'Search',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(AppNav.trending());
        },
      ),
      _QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Settings',
        onPressed: () async => _showComingSoon('Settings'),
      ),
      _QuickControlItem(
        icon: Icons.logout_outlined,
        label: 'Log out',
        onPressed: () async {
          Navigator.of(context).pop();
          await context.read<AuthRepository>().signOut();
        },
      ),
    ];

    _activeStates = _items.map((item) => item.initialValue).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final bool isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(0, value * 60), child: child);
      },
      child: Stack(
        children: [
          // Tap-through scrim: tapping anywhere above the panel closes it.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.16),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickControlGrid(),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'IN INSTITUTION',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleItemInteraction(int index) async {
    final item = _items[index];
    await item.onPressed?.call();
  }

  Widget _buildQuickControlGrid() {
    if (_items.isEmpty) return const SizedBox.shrink();

    const maxColumns = 3;
    final columns = _items.length < maxColumns ? _items.length : maxColumns;
    final rows = (_items.length / columns).ceil();
    final List<Widget> gridRows = [];

    for (var row = 0; row < rows; row++) {
      final int startIndex = row * columns;
      if (startIndex >= _items.length) break;

      final List<Widget> cells = [];
      for (var column = 0; column < columns; column++) {
        final index = startIndex + column;
        final hasItem = index < _items.length;
        cells.add(
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: column == columns - 1 ? 0 : 14),
              child: hasItem
                  ? _QuickControlButton(
                      item: _items[index],
                      isActive: _activeStates[index],
                      onPressed: () => _handleItemInteraction(index),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }

      gridRows.add(
        Padding(
          padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : 10),
          child: Row(children: cells),
        ),
      );
    }

    return Column(children: gridRows);
  }

}

class _QuickControlItem {
  const _QuickControlItem({
    required this.icon,
    required this.label,
    this.onPressed,
  }) : isTogglable = false,
       onToggle = null,
       initialValue = false;

  final IconData icon;
  final String label;
  final Future<void> Function()? onPressed;
  final Future<void> Function(bool)? onToggle;
  final bool isTogglable;
  final bool initialValue;
}

class _QuickControlButton extends StatelessWidget {
  const _QuickControlButton({
    required this.item,
    required this.isActive,
    required this.onPressed,
  });

  final _QuickControlItem item;
  final bool isActive;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final bool isLogoutTile = item.label == 'Log out';

    final Color baseBorder = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.35,
    );
    final Color activeBorder = theme.colorScheme.primary.withValues(
      alpha: isDark ? 0.38 : 0.45,
    );
    final Color baseBackground =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
    final Color activeBackground = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : theme.colorScheme.primary.withValues(alpha: 0.08);

    final Color tileBorder = isLogoutTile
        ? const Color(0xFFF56565)
        : (isActive ? activeBorder : baseBorder);
    final Color tileBackground = isLogoutTile
        ? const Color(0xFFF56565)
        : (isActive ? activeBackground : baseBackground);

    final decoration = BoxDecoration(
      color: tileBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: tileBorder, width: 1),
    );

    final bool isThemeTile = item.label == 'Dark Theme';
    final String displayLabel = isThemeTile
        ? (isDark ? 'White mode' : 'Dark mode')
        : item.label;
    final IconData displayIcon = isThemeTile
        ? (isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded)
        : item.icon;

    final Color labelColor = isLogoutTile
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.82);

    final TextStyle labelStyle = theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: labelColor,
        ) ??
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: labelColor);

    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          displayIcon,
          size: 20,
          color: isLogoutTile
              ? Colors.white
              : theme.colorScheme.onSurface.withValues(alpha: 0.72),
        ),
        const SizedBox(height: 8),
        Text(
          displayLabel,
          textAlign: TextAlign.center,
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        onTap: onPressed == null ? null : () => onPressed?.call(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}

/* Modal composer (deprecated; replaced by full-screen ComposeScreen)
class _QuickComposerSheet extends StatefulWidget {
  const _QuickComposerSheet({
    required this.initials,
    required this.handle,
    required this.author,
    required this.onSubmit,
    this.onViewProfile,
    this.onOpenQuiz,
    this.avatarBackgroundColor,
    this.avatarBorderColor,
  });

  final String initials;
  final String handle;
  final String author;
  final Future<void> Function(String content) onSubmit;
  final VoidCallback? onViewProfile;
  final Future<void> Function()? onOpenQuiz;
  final Color? avatarBackgroundColor;
  final Color? avatarBorderColor;

  @override
  State<_QuickComposerSheet> createState() => _QuickComposerSheetState();
}

class _QuickComposerSheetState extends State<_QuickComposerSheet> {
  final TaggedTextEditingController _controller = TaggedTextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 280 || _isPosting) return;

    setState(() {
      _isPosting = true;
    });
    await widget.onSubmit(text);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showActionToast(String message) {
    if (!mounted) return;
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

  Future<void> _handleQuizTap() async {
    final callback = widget.onOpenQuiz;
    if (callback != null) {
      await callback();
    } else {
      _showActionToast('Quiz builder coming soon');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final Color surface = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.96)
        : Colors.white;
    final Color glassColor = surface.withValues(alpha: isDark ? 0.82 : 0.88);

    final String trimmed = _controller.text.trim();
    final bool canPost =
        trimmed.isNotEmpty && trimmed.length <= 280 && !_isPosting;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Share an update',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TweetComposerCard(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmit: (_) {
                    if (canPost) {
                      _handleSubmit();
                    }
                  },
                  hintText: 'What\'s happening?',
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  backgroundColor:
                      theme.cardColor.withValues(alpha: isDark ? 0.9 : 0.95),
                  boxShadow: const [],
                  isSubmitting: _isPosting,
                  onChanged: (_) => setState(() {}),
                  onImageTap: null,
                  onGifTap: null,
                  onQuizTap: _handleQuizTap,
                    footer: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: widget.onViewProfile,
                          borderRadius: BorderRadius.circular(12),
                          child: HexagonAvatar(
                            size: 44,
                            backgroundColor: widget.avatarBackgroundColor ??
                                theme.colorScheme.surfaceContainerHighest,
                            borderColor: widget.avatarBorderColor ??
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.35),
                            borderWidth: 1.6,
                            child: Center(
                              child: Text(
                                widget.initials,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: trimmed.isEmpty ? 0.45 : 1,
                          child: _ComposerFooterIcon(
                            icon: Icons.add_photo_alternate_outlined,
                            onTap: () => _showActionToast(
                              'Attach image coming soon',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: trimmed.isEmpty ? 0.45 : 1,
                          child: _ComposerFooterIcon(
                            icon: Icons.gif_box_outlined,
                            onTap: () => _showActionToast(
                              'GIF library coming soon',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onViewProfile,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ) ??
                                  const TextStyle(),
                              child: Text(
                                widget.handle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(width: 12),
                        Text(
                          '${_controller.text.length}/280',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _controller.text.length > 280
                                ? Colors.redAccent
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.45,
                                  ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: canPost ? _handleSubmit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isPosting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Post',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerFooterIcon extends StatelessWidget {
  const _ComposerFooterIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : Colors.black;
    final Color background = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
*/

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
