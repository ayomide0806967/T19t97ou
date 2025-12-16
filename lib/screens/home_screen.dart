import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../services/class_service.dart';
import '../widgets/swiss_bank_icon.dart';
import '../widgets/floating_nav_bar.dart';
import 'compose_screen.dart';
import '../widgets/tweet_post_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'ios_messages_screen.dart';
import 'neutral_page.dart';
import 'notifications_screen.dart';
import 'quiz_dashboard_screen.dart';
import 'trending_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _composeFabKey = GlobalKey();
  bool _isFabMenuOpen = false;
  int _selectedBottomNavIndex = 0;
  int _selectedFeedTabIndex = 0;
  final PageController _feedPageController = PageController();
  late final AnimationController _logoRefreshController;
  bool _isRefreshingFeed = false;
  double _rightSwipeOverscroll = 0;
  bool _didTriggerQuickControlSwipe = false;
  SimpleAuthService get _authService => SimpleAuthService();
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
    super.dispose();
  }

  Future<void> _handlePullToRefresh() async {
    if (_isRefreshingFeed) return;
    setState(() => _isRefreshingFeed = true);
    _logoRefreshController.repeat();

    try {
      HapticFeedback.lightImpact();
      await context.read<DataService>().load();
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

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final baseTimeline = dataService.timelinePosts;
    final currentUserHandle = _currentUserHandle;

    return Scaffold(
      key: _scaffoldKey,
      body: NestedScrollView(
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TrendingScreen(),
                      ),
                    );
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
            if (_selectedFeedTabIndex == 0) {
              if (notification is OverscrollNotification &&
                  notification.overscroll < 0) {
                _rightSwipeOverscroll += -notification.overscroll;
                if (!_didTriggerQuickControlSwipe &&
                    _rightSwipeOverscroll > 24) {
                  _didTriggerQuickControlSwipe = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _showQuickControlPanel();
                  });
                }
              }

              if (notification is ScrollEndNotification) {
                _rightSwipeOverscroll = 0;
                _didTriggerQuickControlSwipe = false;
              }
            }
            return false;
          },
          child: PageView(
            controller: _feedPageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _selectedFeedTabIndex = index);
              }
              _rightSwipeOverscroll = 0;
              _didTriggerQuickControlSwipe = false;
            },
            children: [
              _buildFeedList(
                context,
                _sortedTrending(baseTimeline),
                currentUserHandle,
              ),
              _buildFeedList(context, baseTimeline, currentUserHandle),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: KeyedSubtree(
          key: _composeFabKey,
          child: _HexagonComposeButton(
            onTap: _showFabMenu,
            showPlus: _isFabMenuOpen,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFeedList(
    BuildContext context,
    List<PostModel> posts,
    String currentUserHandle, {
    Key? key,
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

    return KeyedSubtree(
      key: key,
      child: RefreshIndicator(
        color: Colors.black,
        notificationPredicate: (notification) => notification.depth == 1,
        onRefresh: _handlePullToRefresh,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10),
          children: children,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    void resetToHome() {
      if (_selectedBottomNavIndex != 0 && mounted) {
        setState(() => _selectedBottomNavIndex = 0);
      }
    }

    return FloatingNavBar(
      currentIndex: _selectedBottomNavIndex,
      onIndexChange: (index) {
        // Center button opens full-page composer (no modal)
        if (index == 2) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ComposeScreen()));
          return;
        }
        if (mounted) {
          setState(() => _selectedBottomNavIndex = index);
        }
      },
      destinations: [
        FloatingNavBarDestination(
          icon: Icons.home_filled,
          onTap: () {
            if (mounted) {
              setState(() => _selectedBottomNavIndex = 0);
            }
          },
        ),
        // Messages
        FloatingNavBarDestination(
          icon: Icons.mail_outline_rounded,
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => const NeutralPage(),
                  ),
                )
                .then((_) => resetToHome());
          },
        ),
        FloatingNavBarDestination(icon: Icons.add, onTap: null),
        // Notifications (love/heart)
        FloatingNavBarDestination(
          icon: Icons.favorite_border_rounded,
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                )
                .then((_) => resetToHome());
          },
        ),
        FloatingNavBarDestination(
          icon: Icons.person_outline_rounded,
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                )
                .then((_) {
                  resetToHome();
                });
          },
        ),
      ],
    );
  }

  Future<void> _openQuickComposer() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ComposeScreen()));
  }

  void _showFabMenu() async {
    if (_isFabMenuOpen) return;

    final renderObject = _composeFabKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final Offset topLeft = renderObject.localToGlobal(Offset.zero);
    final Size size = renderObject.size;
    final Rect fabRect = topLeft & size;

    final Size screenSize = MediaQuery.sizeOf(context);
    final double right = screenSize.width - fabRect.right;
    final double bottom = screenSize.height - fabRect.bottom;

    if (mounted) {
      setState(() => _isFabMenuOpen = true);
    }

    final navigator = Navigator.of(context);
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Compose menu',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      // Route itself has no animation; overlay animates internally on entry only.
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        void close() => Navigator.of(dialogContext).pop();

        return _ComposeFabMenuOverlay(
          anchorRight: right,
          anchorBottom: bottom,
          onClose: close,
          actions: [
            _ComposeFabAction(
              label: 'Go Class',
              icon: Icons.school_rounded,
              animationOrder: 2,
              onTap: () {
                close();
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => const IosMinimalistMessagePage(),
                  ),
                );
              },
            ),
            _ComposeFabAction(
              label: 'Quizzes',
              icon: Icons.quiz_outlined,
              animationOrder: 1,
              onTap: () {
                close();
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => const QuizDashboardScreen(),
                  ),
                );
              },
            ),
            _ComposeFabAction(
              label: 'Photos',
              icon: Icons.photo_outlined,
              animationOrder: 0,
              showPlus: true,
              onTap: () {
                close();
                _openQuickComposer();
              },
            ),
          ],
          onCompose: () {
            close();
            _openQuickComposer();
          },
        );
      },
    );

    if (!mounted) return;
    setState(() => _isFabMenuOpen = false);
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
          onNavigateHome: () {
            setState(() => _selectedBottomNavIndex = 0);
          },
          onCompose: () async {
            navigator.pop();
            await navigator.push(
              MaterialPageRoute(builder: (_) => const ComposeScreen()),
            );
          },
          onProfile: () {
            setState(() => _selectedBottomNavIndex = 4);
            navigator.push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildUserProfileCard() {
    final initials = _initialsFrom(_authService.currentUserEmail);
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
                          await _authService.signOut();
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
    final sorted = List<PostModel>.from(posts);
    int score(PostModel p) => p.likes + (p.reposts * 2) + (p.views ~/ 100);
    sorted.sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _FeedTabBar extends StatefulWidget {
  const _FeedTabBar({
    required this.selectedIndex,
    required this.onChanged,
    required this.pageController,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final PageController pageController;

  @override
  State<_FeedTabBar> createState() => _FeedTabBarState();
}

class _FeedTabBarState extends State<_FeedTabBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;

    final TextStyle baseStyle =
        theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

    Widget buildLabel(String label, int index) {
      final bool isSelected = widget.selectedIndex == index;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            if (!isSelected) {
              widget.onChanged(index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: baseStyle.copyWith(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: isSelected ? 0.98 : 0.65,
                ),
              ),
              child: Center(child: Text(label)),
            ),
          ),
        ),
      );
    }

    // Rebuild indicator position continuously while the PageView is being swiped.
    return AnimatedBuilder(
      animation: widget.pageController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double tabWidth = totalWidth / 2;

            final double t = () {
              if (widget.pageController.hasClients) {
                return (widget.pageController.page ??
                        widget.pageController.initialPage.toDouble())
                    .clamp(0.0, 1.0);
              }
              return widget.selectedIndex.toDouble().clamp(0.0, 1.0);
            }();

            // Indicator spans most of each tab, leaving a small inset so it
            // doesn't feel full-width, while still reaching closer to edges.
            const double inset = 8;
            final double indicatorWidth = tabWidth - (inset * 2);
            final double indicatorLeft = (tabWidth * t) + inset;

            return SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Row(
                    children: [
                      buildLabel('For You', 0),
                      buildLabel('Following', 1),
                    ],
                  ),
                  Positioned(
                    left: indicatorLeft,
                    bottom: 0,
                    child: RepaintBoundary(
                      child: Container(
                        height: 4,
                        width: indicatorWidth,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TwoLineMenuIcon extends StatelessWidget {
  const _TwoLineMenuIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [_MenuLine(), SizedBox(height: 6), _MenuLine()],
      ),
    );
  }
}

class _SearchIcon extends StatelessWidget {
  const _SearchIcon({
    this.size = 28,
    required this.color,
    this.strokeWidthFactor = 0.06,
  });

  final double size;
  final Color color;
  final double strokeWidthFactor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SearchIconPainter(
          color: color,
          strokeWidthFactor: strokeWidthFactor,
        ),
      ),
    );
  }
}

class _SearchIconPainter extends CustomPainter {
  _SearchIconPainter({required this.color, required this.strokeWidthFactor});

  final Color color;
  final double strokeWidthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double sw = s * strokeWidthFactor;
    final Paint stroke = Paint()
      ..color = color
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Offset center = Offset(s * 0.46, s * 0.46);
    final double radius = s * 0.26;
    canvas.drawCircle(center, radius, stroke);

    final Offset handleStart = Offset(s * 0.64, s * 0.64);
    final Offset handleEnd = Offset(s * 0.82, s * 0.82);
    canvas.drawLine(handleStart, handleEnd, stroke);
  }

  @override
  bool shouldRepaint(_SearchIconPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidthFactor != strokeWidthFactor;
}

class _MenuLine extends StatelessWidget {
  const _MenuLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _QuickControlPanel extends StatefulWidget {
  const _QuickControlPanel({
    required this.theme,
    required this.appSettings,
    required this.userCard,
    required this.onNavigateHome,
    required this.onCompose,
    required this.onProfile,
  });

  final ThemeData theme;
  final AppSettings appSettings;
  final Widget userCard;
  final VoidCallback onNavigateHome;
  final VoidCallback onCompose;
  final VoidCallback onProfile;

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
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IosMinimalistMessagePage()),
          );
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
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuizDashboardScreen()),
          );
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
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IosMinimalistMessagePage()),
          );
        },
      ),
      _QuickControlItem(
        icon: Icons.search_rounded,
        label: 'Search',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => TrendingScreen()));
        },
      ),
      _QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Settings',
        onPressed: () async => _showComingSoon('Settings'),
      ),
      _QuickControlItem(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        onPressed: () async {
          Navigator.of(context).pop();
          widget.onProfile();
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
      child: Align(
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
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

    final Color baseBorder = theme.dividerColor.withValues(
      alpha: isDark ? 0.35 : 0.35,
    );
    final Color activeBorder = theme.colorScheme.primary.withValues(
      alpha: isDark ? 0.38 : 0.45,
    );
    final Color baseBackground = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white;
    final Color activeBackground = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : theme.colorScheme.primary.withValues(alpha: 0.08);

    final decoration = BoxDecoration(
      color: isActive ? activeBackground : baseBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isActive ? activeBorder : baseBorder, width: 1),
    );

    final bool isThemeTile = item.label == 'Dark Theme';
    final String displayLabel = isThemeTile
        ? (isDark ? 'White mode' : 'Dark mode')
        : item.label;
    final IconData displayIcon = isThemeTile
        ? (isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded)
        : item.icon;

    final TextStyle labelStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
        ) ??
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          displayIcon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
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

class _ComposeFabAction {
  const _ComposeFabAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.showPlus = false,
    this.animationOrder = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool showPlus;
  final int animationOrder;
}

class _ComposeFabMenuOverlay extends StatefulWidget {
  const _ComposeFabMenuOverlay({
    required this.anchorRight,
    required this.anchorBottom,
    required this.onClose,
    required this.onCompose,
    required this.actions,
  });

  final double anchorRight;
  final double anchorBottom;
  final VoidCallback onClose;
  final VoidCallback onCompose;
  final List<_ComposeFabAction> actions;

  @override
  State<_ComposeFabMenuOverlay> createState() => _ComposeFabMenuOverlayState();
}

class _ComposeFabMenuOverlayState extends State<_ComposeFabMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double t = _animation.value;
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onClose,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 2 * t, sigmaY: 2 * t),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.94 * t),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: widget.anchorRight,
                bottom: widget.anchorBottom,
                child: _ComposeFabMenu(
                  animation: _animation,
                  onClose: widget.onClose,
                  onCompose: widget.onCompose,
                  actions: widget.actions,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComposeFabMenu extends StatelessWidget {
  const _ComposeFabMenu({
    required this.animation,
    required this.onClose,
    required this.onCompose,
    required this.actions,
  });

  final Animation<double> animation;
  final VoidCallback onClose;
  final VoidCallback onCompose;
  final List<_ComposeFabAction> actions;

  @override
  Widget build(BuildContext context) {
    const double itemGap = 18;
    final theme = Theme.of(context);
    final Animation<double> buttonScale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int index = 0; index < actions.length; index++) ...[
          _ComposeFabStaggeredEntry(
            animation: animation,
            index: actions[index].animationOrder,
            child: _FabMenuItem(
              label: actions[index].label,
              icon: actions[index].icon,
              showPlus: actions[index].showPlus,
              onTap: actions[index].onTap,
            ),
          ),
          if (index != actions.length - 1) const SizedBox(height: itemGap),
        ],
        const SizedBox(height: 14),
        _ComposeFabStaggeredEntry(
          animation: animation,
          index: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, -10),
                child: Text(
                  'Post',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ScaleTransition(
                scale: buttonScale,
                child: _HexagonComposeButton(onTap: onCompose, showPlus: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComposeFabStaggeredEntry extends StatelessWidget {
  const _ComposeFabStaggeredEntry({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Stagger each item clearly: 0 -> Photos, 1 -> Quizzes, 2 -> Go Class.
    final double start = 0.10 + (index * 0.18);
    final double end = (start + 0.40).clamp(0.0, 1.0);
    final Animation<double> entry = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
      // On dismiss, jump quickly from visible to hidden (no staggered fade).
      reverseCurve: Threshold(0.999),
    );

    return FadeTransition(
      opacity: entry,
      child: SlideTransition(
        position: Tween<Offset>(
          // Slight upward + outward sweep
          begin: const Offset(0.08, 0.20),
          end: Offset.zero,
        ).animate(entry),
        child: RotationTransition(
          // Fan-like swing from the side into place
          turns: Tween<double>(
            begin: 0.5, // half‑turn fan motion
            end: 0.0,
          ).animate(entry),
          child: child,
        ),
      ),
    );
  }
}

class _HexagonComposeButton extends StatelessWidget {
  const _HexagonComposeButton({required this.onTap, this.showPlus = false});

  final VoidCallback onTap;
  final bool showPlus;

  @override
  Widget build(BuildContext context) {
    // Solid black rectangular composer button
    final Color buttonColor = Colors.black;
    final BorderRadius radius = BorderRadius.circular(12);

    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: showPlus
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        Transform.translate(
                          offset: const Offset(-8, -6),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.label,
    required this.icon,
    this.showPlus = false,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool showPlus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    // Keep popup labels black in both light and dark,
    // to match the design of the overlay.
    const Color labelColor = Colors.black;
    final Color iconColor = isDark ? Colors.white : Colors.black;
    final Color chipColor = isDark ? theme.colorScheme.surface : Colors.white;
    // Stronger black shadow for popup icons in both modes.
    final Color chipShadowColor = Colors.black.withValues(
      alpha: isDark ? 0.85 : 0.5,
    );
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 24),
          Material(
            color: chipColor,
            shape: const CircleBorder(),
            elevation: 12,
            shadowColor: chipShadowColor,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: showPlus
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: iconColor, size: 24),
                          Transform.translate(
                            offset: Offset(-8, -6),
                            child: Icon(
                              Icons.add_rounded,
                              color: iconColor,
                              size: 14,
                            ),
                          ),
                        ],
                      )
                    : Icon(icon, size: 24, color: iconColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy hexagon button shapes removed after switching to rectangular FAB

class _StoryRail extends StatelessWidget {
  const _StoryRail({required this.currentUserHandle});

  final String currentUserHandle;

  @override
  Widget build(BuildContext context) {
    final classes = ClassService.userColleges(currentUserHandle);
    final List<_Story> stories = classes.map((c) => _Story(c.name)).toList();
    final theme = Theme.of(context);

    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 112,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => false,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: stories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final story = stories[index];
            final Color borderColor = theme.colorScheme.primary.withValues(
              alpha: 0.25,
            );
            final Color background = Theme.of(context).colorScheme.surface;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HexagonAvatar(
                    size: 56,
                    backgroundColor: background,
                    borderColor: borderColor,
                    borderWidth: 1.1,
                    child: Center(
                      child: Text(
                        story.initials,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      story.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.currentUserHandle});

  final PostModel post;
  final String currentUserHandle;

  @override
  Widget build(BuildContext context) {
    // Use DataService via higher-level builders where needed

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

String _initialsFrom(String? value) {
  if (value == null || value.isEmpty) return 'IN';
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return 'IN';
  final count = letters.length >= 2 ? 2 : 1;
  return letters.substring(0, count).toUpperCase();
}

class _Story {
  const _Story(this.label);

  final String label;

  String get initials {
    final letters = label.replaceAll(RegExp('[^A-Za-z]'), '');
    if (letters.length >= 2) {
      return letters.substring(0, 2).toUpperCase();
    }
    return letters.substring(0, 1).toUpperCase();
  }
}
