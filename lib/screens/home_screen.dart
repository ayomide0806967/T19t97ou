import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/tweet_post_card.dart';
import 'thread_screen.dart';
import 'chat_screen.dart';
import 'compose_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();
    final posts = dataService.posts;
    final initials = _initialsFrom(_authService.currentUserEmail);
    final currentUserHandle = _currentUserHandle;

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
                  child: Text(initials, style: theme.textTheme.labelLarge),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
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
      drawer: RepaintBoundary(child: _buildNavigationDrawer()),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
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
                          child: _ComposeCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ComposeScreen(),
                                ),
                              );
                            },
                          ),
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
            delegate: SliverChildBuilderDelegate((context, index) {
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
                          currentUserHandle: currentUserHandle,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: posts.length),
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
              MaterialPageRoute(builder: (context) => const ComposeScreen()),
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
                  MaterialPageRoute(
                    builder: (context) => const ExploreScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
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
        child: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
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
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
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
                              ? Colors.white.withValues(alpha: 0.05)
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
          },
        ),
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
          hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 16),
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
        ...items.map(
          (item) =>
              Padding(padding: const EdgeInsets.only(bottom: 4), child: item),
        ),
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
                      const SizedBox(height: 2),
                      Text(
                        '@productlead • ${_authService.currentUserEmail?.toLowerCase() ?? 'user@institution.edu'}',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : const Color(0xFF718096),
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
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: Theme.of(context).brightness == Brightness.dark,
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppTheme.accent.withValues(alpha: 0.1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_ModernBottomBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only trigger animation if the active state actually changed
    if (oldWidget.isActive != widget.isActive &&
        _controller.status != AnimationStatus.forward &&
        _controller.status != AnimationStatus.reverse) {
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
    final inactive = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF64748B);
    final color = widget.isActive ? AppTheme.accent : inactive;
    final borderColor = isDark
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white;

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
                  borderRadius: BorderRadius.circular(
                    widget.isCreate ? 16 : 14,
                  ),
                  color: widget.isCreate ? Colors.black : _colorAnimation.value,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.35 : 0.15,
                                      ),
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
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
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
                                  border: Border.all(
                                    color: AppTheme.accent,
                                    width: 2,
                                  ),
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
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
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
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                _ComposerTool(icon: Icons.photo_outlined, label: 'Media'),
                SizedBox(width: 18),
                _ComposerTool(icon: Icons.bar_chart_outlined, label: 'Poll'),
                SizedBox(width: 18),
                _ComposerTool(
                  icon: Icons.calendar_month_outlined,
                  label: 'Event',
                ),
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

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.currentUserHandle});

  final PostModel post;
  final String currentUserHandle;

  @override
  Widget build(BuildContext context) {
    final dataService = context.read<DataService>();

    return TweetPostCard(
      post: post,
      currentUserHandle: currentUserHandle,
      onTap: () {
        final thread = dataService.buildThreadForPost(post.id);
        Navigator.of(context).push(
          ThreadScreen.route(
            entry: thread,
            currentUserHandle: currentUserHandle,
          ),
        );
      },
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF4B5563);

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      backgroundColor: background,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
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
                Icon(icon, color: color, size: 20),
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

const List<_Story> _demoStories = [
  _Story('You'),
  _Story('Design Lab'),
  _Story('Campus Radio'),
  _Story('AI Society'),
  _Story('Eco Club'),
  _Story('Career Office'),
];
