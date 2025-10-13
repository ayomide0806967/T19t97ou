import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/brand_mark.dart';
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
        title: const SizedBox.shrink(),
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const BrandMark(size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'Institution',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _StoryRail(),
                        const SizedBox(height: 16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ComposeScreen()),
          );
        },
        tooltip: 'Compose',
        mini: true,
        backgroundColor: AppTheme.buttonPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.edit_rounded, size: 18),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color background = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.92);
    final Color activeColor = theme.colorScheme.onSurface;
    final Color inactiveColor = activeColor.withValues(alpha: 0.55);

    Widget buildItem({
      required IconData icon,
      required String label,
      required int index,
      required VoidCallback onPressed,
    }) {
      final bool isActive = _selectedBottomNavIndex == index;
      final Color color = isActive ? activeColor : inactiveColor;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    void resetToHome() {
      if (_selectedBottomNavIndex != 0 && mounted) {
        setState(() => _selectedBottomNavIndex = 0);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            buildItem(
              icon: Icons.home_outlined,
              label: 'Home',
              index: 0,
              onPressed: () {
                if (_selectedBottomNavIndex != 0) {
                  setState(() => _selectedBottomNavIndex = 0);
                }
              },
            ),
            buildItem(
              icon: Icons.explore_outlined,
              label: 'Explore',
              index: 1,
              onPressed: () {
                setState(() => _selectedBottomNavIndex = 1);
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const ExploreScreen(),
                      ),
                    )
                    .then((_) {
                      resetToHome();
                    });
              },
            ),
            buildItem(
              icon: Icons.mode_edit_outline_rounded,
              label: 'Compose',
              index: 2,
              onPressed: () {
                setState(() => _selectedBottomNavIndex = 2);
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const ComposeScreen(),
                      ),
                    )
                    .then((_) {
                      resetToHome();
                    });
              },
            ),
            buildItem(
              icon: Icons.mark_chat_unread_outlined,
              label: 'Chat',
              index: 3,
              onPressed: () {
                setState(() => _selectedBottomNavIndex = 3);
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(),
                      ),
                    )
                    .then((_) {
                      resetToHome();
                    });
              },
            ),
            buildItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              index: 4,
              onPressed: () {
                setState(() => _selectedBottomNavIndex = 4);
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const BrandMark(size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Institution',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF4A5568),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
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
    final theme = Theme.of(context);
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF2D3748),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
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
