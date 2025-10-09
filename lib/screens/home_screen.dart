import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/simple_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/tweet_shell.dart';
import '../widgets/simple_comment_section.dart';
import '../state/app_settings.dart';
import '../services/data_service.dart';
import 'profile_screen.dart';
import 'explore_screen.dart';
import 'chat_screen.dart';
import 'quote_screen.dart';
import 'compose_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
// Theme is now controlled globally via AppSettings; keeping local field removed.
  int _selectedBottomNavIndex = 0;
  List<_Post> _posts = List.from(_demoPosts);

  SimpleAuthService get _authService => SimpleAuthService();

  void _addNewPost({
    required String type,
    _Post? originalPost,
    String? comment,
    List<String>? postTags,
    List<String>? postMedia,
  }) {
    final newPost = _Post(
      author: 'You',
      handle: '@yourprofile',
      timeAgo: 'just now',
      body: comment ?? '',
      quotedPost: type == 'Quote' ? originalPost : null,
      replies: 0,
      reposts: 0,
      likes: 0,
      views: 0,
      bookmarks: 0,
      tags: postTags ?? <String>[],
    );

    setState(() {
      _posts.insert(0, newPost);
    });

    _showToast('Post published successfully!');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
final dataService = context.watch<DataService>();
    final posts = dataService.posts
        .map((p) => _Post(
              author: p.author,
              handle: p.handle,
              timeAgo: p.timeAgo,
              body: p.body,
              replies: p.replies,
              reposts: p.reposts,
              likes: p.likes,
              views: p.views,
              bookmarks: p.bookmarks,
              tags: p.tags,
              quotedPost: p.quoted != null
                  ? _Post(
                      author: p.quoted!.author,
                      handle: p.quoted!.handle,
                      timeAgo: p.quoted!.timeAgo,
                      body: p.quoted!.body,
                      replies: 0,
                      reposts: 0,
                      likes: 0,
                      views: 0,
                      bookmarks: 0,
                      tags: p.quoted!.tags,
                    )
                  : null,
            ))
        .toList();
    final initials = _initialsFrom(_authService.currentUserEmail);

    return Scaffold(
      key: _scaffoldKey,
appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF2D3748), size: 24),
          onPressed: () {
            if (_scaffoldKey.currentState != null) {
              _scaffoldKey.currentState!.openDrawer();
            }
          },
          tooltip: 'Open menu',
        ),
        titleSpacing: 0,
        title: Text(
          'Institution',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          RepaintBoundary(
            child: IconButton(
              tooltip: 'Profile',
              icon: HexagonAvatar(
                size: 40,
                child: Center(
                  child: Text(
                    initials,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),
          RepaintBoundary(
            child: IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_outlined),
              onPressed: () async {
                await _authService.signOut();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: RepaintBoundary(
        child: _buildNavigationDrawer(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Institution',
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: const Color(0xFF1E293B),
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 32),
                              const _StoryRail(),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: const [
                                  _PillTag('Announcements'),
                                  _PillTag('Events'),
                                  _PillTag('Research'),
                                  _PillTag('Community'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        RepaintBoundary(
child: _ComposeCard(onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ComposeScreen(),
                      ),
                    );
                  })
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                return RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
child: _PostCard(
                            post: post,
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
          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // Extra padding at bottom
          ),
        ],
      ),
      floatingActionButton: RepaintBoundary(
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
builder: (context) => const ComposeScreen(),
              ),
            );
          },
          label: const Text('Compose'),
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          backgroundColor: AppTheme.buttonPrimary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final platform = Theme.of(context).platform;
    final isMobile = platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    final barContent = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ModernBottomBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              isActive: _selectedBottomNavIndex == 0,
              onTap: () {
                setState(() {
                  _selectedBottomNavIndex = 0;
                });
              },
              isFirst: true,
            ),
            _ModernBottomBarItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: 'Explore',
              isActive: _selectedBottomNavIndex == 1,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ExploreScreen()),
                );
              },
            ),
            _ModernBottomBarItem(
              icon: Icons.add_circle_outline,
              activeIcon: Icons.add_circle,
              label: 'Create',
              isActive: _selectedBottomNavIndex == 2,
              onTap: () {
                setState(() {
                  _selectedBottomNavIndex = 2;
                });
              },
              isCreate: true,
            ),
                    _ModernBottomBarItem(
                      icon: Icons.mark_chat_unread_outlined,
                      activeIcon: Icons.mark_chat_unread_rounded,
                      label: 'Chat',
                      isActive: _selectedBottomNavIndex == 3,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ChatScreen()),
                        );
                      },
                      badge: '12',
                    ),
            _ModernBottomBarItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              isActive: _selectedBottomNavIndex == 4,
              onTap: () {
                setState(() {
                  _selectedBottomNavIndex = 4;
                });
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              isLast: true,
            ),
          ],
        ),
      ),
    );

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withValues(alpha: 0.8),
                        blurRadius: 0,
                        offset: const Offset(0, -1),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: barContent,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: RepaintBoundary(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNavigationItems(),
                      const SizedBox(height: 24),
                      _buildSection('Your Pages', [
                        _NavigationItem(
                          icon: Icons.pages_outlined,
                          title: 'Design Club',
                          color: const Color(0xFF4299E1),
                        ),
                        _NavigationItem(
                          icon: Icons.groups_outlined,
                          title: 'Student Union',
                          color: const Color(0xFF48BB78),
                        ),
                        _NavigationItem(
                          icon: Icons.sports_esports_outlined,
                          title: 'Gaming Society',
                          color: const Color(0xFF9F7AEA),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Trending', [
                        _NavigationItem(
                          icon: Icons.tag_outlined,
                          title: '#CampusLife',
                          color: const Color(0xFF718096),
                        ),
                        _NavigationItem(
                          icon: Icons.tag_outlined,
                          title: '#StudentSuccess',
                          color: const Color(0xFF718096),
                        ),
                        _NavigationItem(
                          icon: Icons.tag_outlined,
                          title: '#InnovationHub',
                          color: const Color(0xFF718096),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Events', [
                        _NavigationItem(
                          icon: Icons.event_outlined,
                          title: 'Tech Workshop',
                          color: const Color(0xFF718096),
                        ),
                        _NavigationItem(
                          icon: Icons.event_outlined,
                          title: 'Study Group',
                          color: const Color(0xFF718096),
                        ),
                        _NavigationItem(
                          icon: Icons.event_outlined,
                          title: 'Career Fair',
                          color: const Color(0xFF718096),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildUserProfileCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search posts, people, tags...',
          hintStyle: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFA0AEC0),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItems() {
    return Column(
      children: [
        _NavigationItem(
          icon: Icons.home_outlined,
          title: 'Home Feed',
          color: const Color(0xFF48BB78),
          hasBadge: true,
        ),
        const SizedBox(height: 8),
        _NavigationItem(
          icon: Icons.tag_outlined,
          title: 'Trending Topics',
          color: const Color(0xFF4299E1),
        ),
        const SizedBox(height: 8),
        _NavigationItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          color: const Color(0xFFED8936),
        ),
        const SizedBox(height: 8),
        _NavigationItem(
          icon: Icons.message_outlined,
          title: 'Messages',
          color: const Color(0xFF9F7AEA),
        ),
        const SizedBox(height: 8),
        _NavigationItem(
          icon: Icons.people_outlined,
          title: 'Friends',
          color: const Color(0xFFF56565),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: item,
        )),
      ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            blurRadius: 0,
            offset: const Offset(0, -2),
            spreadRadius: 1,
          ),
        ],
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
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
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
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF2D3748),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@productlead • ${_authService.currentUserEmail?.toLowerCase() ?? 'user@institution.edu'}',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF718096),
                          fontSize: 12,
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
      builder: (context) => Container(
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
_buildDropdownItem(
                    icon: Theme.of(context).brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (value) {
                        context.read<AppSettings>().toggleDarkMode(value);
                      },
                      activeColor: const Color(0xFF4299E1),
                    ),
                  ),
                  _buildDropdownItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
          ],
        ),
      ),
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
              Icon(
                icon,
                color: itemColor,
                size: 20,
              ),
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
}

class _ModernBottomBarItem extends StatefulWidget {
  const _ModernBottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
    this.isFirst = false,
    this.isLast = false,
    this.isCreate = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;
  final bool isFirst;
  final bool isLast;
  final bool isCreate;

  @override
  State<_ModernBottomBarItem> createState() => _ModernBottomBarItemState();
}

class _ModernBottomBarItemState extends State<_ModernBottomBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppTheme.accent.withValues(alpha: 0.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_ModernBottomBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only trigger animation if the active state actually changed
    if (oldWidget.isActive != widget.isActive && _controller.status != AnimationStatus.forward && _controller.status != AnimationStatus.reverse) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF64748B);
    final color = widget.isActive ? AppTheme.accent : inactive;
    final borderColor = isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white;

    return Expanded(
      child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: widget.isFirst || widget.isLast ? 8 : 4,
              vertical: 4,
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.isCreate ? 56 : 48,
                height: widget.isCreate ? 56 : 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.isCreate ? 16 : 14),
                  color: widget.isCreate
                    ? Colors.black
                    : _colorAnimation.value,
                  border: widget.isCreate
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
                  boxShadow: [
                    if (widget.isActive && !widget.isCreate)
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    if (widget.isCreate)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.isCreate ? 1.0 : _scaleAnimation.value,
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              widget.isActive ? widget.activeIcon : widget.icon,
                              color: widget.isCreate ? Colors.white : color,
                              size: widget.isCreate ? 28 : 24,
                              weight: widget.isCreate ? 700 : 400,
                            ),
                          ),
                          if (widget.badge != null && !widget.isCreate)
                            Positioned(
                              right: widget.isCreate ? 2 : -4,
                              top: widget.isCreate ? 2 : -6,
                              child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.badge!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (!widget.isCreate) ...[
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: widget.isActive ? 0.2 : 0.1,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryRail extends StatelessWidget {
  const _StoryRail();

  @override
  Widget build(BuildContext context) {
    final stories = _demoStories;
    final theme = Theme.of(context);

    return SizedBox(
      height: 140,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          // Add scroll physics feedback if needed
          return false;
        },
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: stories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 20),
          itemBuilder: (context, index) {
            final story = stories[index];
            return GestureDetector(
              onTap: () {
                // Add tap feedback
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 85,
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: story.label == 'You'
                            ? [
                                AppTheme.accent.withValues(alpha: 0.8),
                                AppTheme.accent.withValues(alpha: 0.6),
                              ]
                            : [
                                const Color(0xFFF8FAFC),
                                const Color(0xFFF1F5F9),
                              ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: story.label == 'You'
                              ? AppTheme.accent.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.05),
                            blurRadius: story.label == 'You' ? 12 : 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          HexagonAvatar(
                            size: 76,
                            backgroundColor: story.label == 'You'
                              ? Colors.transparent
                              : AppTheme.surface,
                            child: Center(
                              child: Text(
                                story.initials,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: story.label == 'You'
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          if (story.label == 'You')
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.accent, width: 2),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppTheme.accent,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: Text(
                          story.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: story.label == 'You'
                              ? FontWeight.w600
                              : FontWeight.w500,
                            color: story.label == 'You'
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.08)
                : AppTheme.divider,
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HexagonAvatar(
                  size: 48,
                  child: const Icon(Icons.add, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Share an update with the community…',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.textTertiary),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                _ComposerTool(icon: Icons.photo_outlined, label: 'Media'),
                SizedBox(width: 18),
                _ComposerTool(icon: Icons.bar_chart_outlined, label: 'Poll'),
                SizedBox(width: 18),
                _ComposerTool(icon: Icons.calendar_month_outlined, label: 'Event'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerTool extends StatelessWidget {
  const _ComposerTool({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, this.onQuoteCreated});

  final _Post post;
  final Function(String comment)? onQuoteCreated;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late int replies = widget.post.replies;
  late int reposts = widget.post.reposts;
  late int likes = widget.post.likes;
  late int views = widget.post.views;
  late int bookmarks = widget.post.bookmarks;

  bool liked = false;
  bool bookmarked = false;
  bool reposted = false;

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _handleAction(_MetricType type) {
    switch (type) {
      case _MetricType.reply:
        setState(() => replies += 1);
        _showCommentBottomSheet();
        break;
      case _MetricType.rein:
        _showReinDropdown();
        break;
      case _MetricType.like:
        setState(() {
          liked = !liked;
          likes += liked ? 1 : -1;
        });
        break;
      case _MetricType.view:
        setState(() => views += 1);
        _showToast(context, 'Insights panel coming soon');
        break;
      case _MetricType.bookmark:
        setState(() {
          bookmarked = !bookmarked;
          bookmarks += bookmarked ? 1 : -1;
        });
        break;
      case _MetricType.share:
        _showToast(context, 'Share sheet coming soon');
        break;
    }
  }

  void _showReinDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildReinDropdownItem(
                    icon: Icons.repeat_rounded,
                    title: 'Re-institute',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        reposted = !reposted;
                        reposts += reposted ? 1 : -1;
                      });
                      _showToast(context, reposted ? 'Re-instituted!' : 'Removed re-institution');
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildReinDropdownItem(
                    icon: Icons.format_quote_rounded,
                    title: 'Quote',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => QuoteScreen(
                            author: widget.post.author,
                            handle: widget.post.handle,
                            timeAgo: widget.post.timeAgo,
                            body: widget.post.body,
                            initials: _initialsFrom(widget.post.author),
                            tags: widget.post.tags,
                            onPostQuote: (comment) {
                              if (widget.onQuoteCreated != null) {
                                widget.onQuoteCreated!(comment);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  _buildReinDropdownItem(
                    icon: Icons.close_rounded,
                    title: 'Cancel',
                    color: const Color(0xFF64748B),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
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
              Expanded(
                child: SimpleCommentSection(
                  postAuthor: widget.post.author,
                  postBody: widget.post.body,
                  postTime: widget.post.timeAgo,
                  comments: _getSimpleDemoComments(),
                  onAddComment: (content) {
                    Navigator.pop(context);
                    _showToast(context, 'Reply posted successfully!');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  List<SimpleComment> _getSimpleDemoComments() {
    return [
      SimpleComment(
        author: 'Sarah Johnson',
        timeAgo: '2h',
        body: 'This is exactly what our campus needs! Looking forward to seeing the impact on student innovation.',
        avatarColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        likes: 12,
        isLiked: false,
      ),
      SimpleComment(
        author: 'Mike Chen',
        timeAgo: '1h',
        body: 'Completely agree! The interdisciplinary approach will be game-changing.',
        avatarColors: [const Color(0xFFF093FB), const Color(0xFFF5576C)],
        likes: 3,
        isLiked: true,
      ),
      SimpleComment(
        author: 'Dr. Emily Watson',
        timeAgo: '45m',
        body: 'As a faculty member, I\'m excited about the collaboration opportunities this will create.',
        avatarColors: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
        likes: 28,
        isLiked: true,
      ),
      SimpleComment(
        author: 'Alex Rivera',
        timeAgo: '30m',
        body: 'The timing is perfect for this initiative. Students have been asking for more collaborative spaces.',
        avatarColors: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
        likes: 8,
        isLiked: false,
      ),
    ];
  }

  Widget _buildReinDropdownItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
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
              Icon(
                icon,
                color: itemColor,
                size: 20,
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final metrics = [
      _TweetMetricData(type: _MetricType.reply, icon: Icons.mode_comment_outlined, count: replies),
      _TweetMetricData(type: _MetricType.rein, icon: Icons.swap_vertical_circle, count: reposts, isActive: reposted),
      _TweetMetricData(type: _MetricType.like, icon: liked ? Icons.favorite : Icons.favorite_border, count: likes, isActive: liked),
      _TweetMetricData(type: _MetricType.view, icon: Icons.trending_up_rounded, count: views),
      _TweetMetricData(type: _MetricType.bookmark, icon: bookmarked ? Icons.bookmark : Icons.bookmark_border, count: bookmarks, isActive: bookmarked),
      const _TweetMetricData(type: _MetricType.share, icon: Icons.send_rounded),
    ];

    return TweetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HexagonAvatar(
                size: 56,
                child: Center(
                  child: Text(
                    widget.post.initials,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post.author, style: theme.textTheme.labelLarge?.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${widget.post.handle} • ${widget.post.timeAgo}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showToast(context, 'Post options coming soon'),
                icon: const Icon(Icons.more_horiz, color: AppTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.post.body.isNotEmpty)
            Text(
              widget.post.body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          if (widget.post.quotedPost != null) ...[
            const SizedBox(height: 16),
            _QuoteCard(post: widget.post.quotedPost!),
          ],
          if (widget.post.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.post.tags.map((tag) => _PillTag(tag)).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _TweetMetric(data: metrics[0], onTap: () => _handleAction(metrics[0].type)),
              ),
              Expanded(
                child: _TweetMetric(data: metrics[1], onTap: () => _handleAction(metrics[1].type)),
              ),
              Expanded(
                child: _TweetMetric(data: metrics[2], onTap: () => _handleAction(metrics[2].type)),
              ),
              Expanded(
                child: _TweetMetric(data: metrics[3], onTap: () => _handleAction(metrics[3].type)),
              ),
              Expanded(
                child: _TweetMetric(data: metrics[4], onTap: () => _handleAction(metrics[4].type)),
              ),
              Expanded(
                child: _TweetMetric(data: metrics[5], onTap: () => _handleAction(metrics[5].type)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TweetMetricData {
  const _TweetMetricData({
    required this.type,
    required this.icon,
    this.count,
    this.isActive = false,
  });

  final _MetricType type;
  final IconData icon;
  final int? count;
  final bool isActive;

  _TweetMetricData copyWith({bool? isActive, int? count}) => _TweetMetricData(
        type: type,
        icon: icon,
        count: count ?? this.count,
        isActive: isActive ?? this.isActive,
      );
}

class _TweetMetric extends StatelessWidget {
  const _TweetMetric({required this.data, required this.onTap});

  final _TweetMetricData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRein = data.type == _MetricType.rein;
    final color = data.isActive ? AppTheme.accent : AppTheme.textSecondary;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );

    Widget child = Row(
      children: [
        if (isRein)
          Text(
            'Re-in',
            style: textStyle?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          )
        else
          Icon(data.icon, size: 20, color: color),
        if (data.count != null) ...[
          const SizedBox(width: 4),
          Text(
            _formatMetric(data.count!),
            style: textStyle?.copyWith(fontSize: 12),
          ),
        ],
      ],
    );

    if (isRein) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: data.isActive ? AppTheme.accent.withValues(alpha: 0.1) : Colors.transparent,
            border: data.isActive
              ? Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1)
              : null,
          ),
          child: child,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: child,
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w600),
      backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.hasBadge = false,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF2D3748),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasBadge)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _MetricType { reply, rein, like, view, bookmark, share }

String _initialsFrom(String? value) {
  if (value == null || value.isEmpty) return 'IN';
  final letters = value.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isEmpty) return 'IN';
  final count = letters.length >= 2 ? 2 : 1;
  return letters.substring(0, count).toUpperCase();
}

String _formatMetric(int value) {
  if (value >= 1000000) {
    final formatted = value / 1000000;
    return formatted >= 10 ? '${formatted.toStringAsFixed(0)}M' : '${formatted.toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final formatted = value / 1000;
    return formatted >= 10 ? '${formatted.toStringAsFixed(0)}K' : '${formatted.toStringAsFixed(1)}K';
  }
  return value.toString();
}

class _Post {
  const _Post({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    required this.replies,
    required this.reposts,
    required this.likes,
    required this.views,
    required this.bookmarks,
    this.tags = const <String>[],
    this.quotedPost,
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final int replies;
  final int reposts;
  final int likes;
  final int views;
  final int bookmarks;
  final List<String> tags;
  final _Post? quotedPost;

  String get initials {
    final parts = author.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

const List<_Post> _demoPosts = [
  _Post(
    author: 'Dr. Maya Chen',
    handle: '@dean_creative',
    timeAgo: '2h',
    body:
        'Excited to announce the new Innovation Studio. A collaborative environment designed for prototyping, creative coding, and rapid experimentation.',
    tags: ['Innovation', 'Design Labs'],
    replies: 91,
    reposts: 51,
    likes: 968,
    views: 46100,
    bookmarks: 18,
  ),
  _Post(
    author: 'Student Affairs',
    handle: '@life_at_in',
    timeAgo: '4h',
    body:
        'This Friday we host our minimalist mixer on the West Terrace. Expect acoustic sets, local roasters, and plenty of space to breathe.',
    tags: ['Events', 'Community'],
    replies: 42,
    reposts: 27,
    likes: 312,
    views: 18600,
    bookmarks: 23,
  ),
  _Post(
    author: 'Research Collective',
    handle: '@insights',
    timeAgo: '1d',
    body:
        'We just published our annual state of campus innovation report. Streamlined briefs, interactive prototypes, and open data sets are available now.',
    tags: ['Research', 'Open Data'],
    replies: 58,
    reposts: 36,
    likes: 742,
    views: 32900,
    bookmarks: 41,
  ),
];

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.post});

  final _Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    post.initials,
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 14,
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
                    Row(
                      children: [
                        Text(
                          post.author,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.handle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.body.length > 200
              ? '${post.body.substring(0, 200)}...'
              : post.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.5,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
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

const List<_Story> _demoStories = [
  _Story('You'),
  _Story('Design Lab'),
  _Story('Campus Radio'),
  _Story('AI Society'),
  _Story('Eco Club'),
  _Story('Career Office'),
];
