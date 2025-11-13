import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/brand_mark.dart';
import '../widgets/floating_nav_bar.dart';
import 'compose_screen.dart';
import '../widgets/tweet_post_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'ios_messages_screen.dart';
import 'trending_screen.dart';
import 'notifications_screen.dart';
import 'quiz_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedBottomNavIndex = 0;
  double _horizontalDragDistance = 0;
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
    final posts = dataService.timelinePosts;
    final initials = _initialsFrom(_authService.currentUserEmail);
    final currentUserHandle = _currentUserHandle;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: Scaffold(
        key: _scaffoldKey,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Institution',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              actions: [
                RepaintBoundary(
                  child: IconButton(
                    tooltip: 'Profile',
                    icon: HexagonAvatar(
                      size: 40,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      borderColor: theme.colorScheme.primary.withValues(
                        alpha: 0.35,
                      ),
                      borderWidth: 1.5,
                      child: Center(
                        child: Text(
                          initials,
                          style: theme.textTheme.labelLarge,
                        ),
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
            SliverToBoxAdapter(
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
                      children: const [_StoryRail(), SizedBox(height: 16)],
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final post = posts[index];
                return RepaintBoundary(
                  child: Builder(builder: (context) {
                    final theme = Theme.of(context);
                    final bool isDark = theme.brightness == Brightness.dark;
                    // Softer divider like X
                    final Color line = theme.colorScheme.onSurface
                        .withValues(alpha: isDark ? 0.12 : 0.06);

                    final Border border = Border(
                      top: index == 0
                          ? BorderSide(color: line, width: 0.6)
                          : BorderSide.none,
                      bottom: BorderSide(color: line, width: 0.6),
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                    );
                  }),
                );
              }, childCount: posts.length),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Extra padding at bottom
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _HexagonComposeButton(
            onTap: _openQuickComposer,
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ComposeScreen()),
          );
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
                    builder: (context) => const IosMinimalistMessagePage(),
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

  void _handleHorizontalDragStart(DragStartDetails details) {
    _horizontalDragDistance = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    final dy = details.delta.dy.abs();
    if (dx > 0 && dx.abs() > dy) {
      _horizontalDragDistance += dx;
    } else if (dx < 0) {
      _horizontalDragDistance = 0;
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_horizontalDragDistance > 80 || velocity > 600) {
      _showQuickControlPanel();
    }
    _horizontalDragDistance = 0;
  }

  Future<void> _openQuickComposer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ComposeScreen()),
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
        icon: Icons.home_outlined,
        label: 'Home Feed',
        onPressed: () async {
          Navigator.of(context).pop();
          widget.onNavigateHome();
        },
      ),
      _QuickControlItem(
        icon: Icons.mode_edit_outline_rounded,
        label: 'Compose',
        onPressed: () async {
          Navigator.of(context).pop();
          widget.onCompose();
        },
      ),
      _QuickControlItem(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        onPressed: () async {
          Navigator.of(context).pop();
          widget.onProfile();
        },
      ),
      _QuickControlItem.togglable(
        icon: Icons.dark_mode_rounded,
        label: 'Dark Theme',
        initialValue: widget.appSettings.isDarkMode,
        onToggle: (value) async {
          await widget.appSettings.toggleDarkMode(value);
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
            MaterialPageRoute(
              builder: (_) => const IosMinimalistMessagePage(),
            ),
          );
        },
      ),
      _QuickControlItem(
        icon: Icons.school_outlined,
        label: 'Colleges',
        onPressed: () async => _showComingSoon('Colleges'),
      ),
      _QuickControlItem(
        icon: Icons.local_fire_department_outlined,
        label: 'Trending',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TrendingScreen(),
            ),
          );
        },
      ),
      _QuickControlItem(
        icon: Icons.note_alt_outlined,
        label: 'Notes',
        onPressed: () async => _showComingSoon('Notes'),
      ),
      _QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Quiz',
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const QuizHubScreen(),
            ),
          );
        },
      ),
      _QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Exam Prep',
        onPressed: () async => _showComingSoon('Exam prep'),
      ),
      _QuickControlItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onPressed: () async => _showComingSoon('Settings'),
      ),
    ];

    _activeStates = _items.map((item) => item.initialValue).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.5;
    final theme = widget.theme;

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
              height: sheetHeight,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quick controls',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildQuickControlGrid(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  widget.userCard,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleItemInteraction(int index) async {
    final item = _items[index];
    final isActive = _activeStates[index];
    if (item.isTogglable) {
      setState(() {
        _activeStates[index] = !isActive;
      });
      final handler = item.onToggle;
      if (handler != null) {
        await handler(_activeStates[index]);
      }
    } else {
      await item.onPressed?.call();
    }
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
          padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : 16),
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

  const _QuickControlItem.togglable({
    required this.icon,
    required this.label,
    required this.initialValue,
    this.onToggle,
  }) : isTogglable = true,
       onPressed = null;

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

    final TextStyle labelStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
        ) ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    final Widget content = item.isTogglable
        ? Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: labelStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Transform.scale(
                scale: 0.82,
                alignment: Alignment.centerRight,
                child: CupertinoSwitch(
                  value: isActive,
                  activeTrackColor: theme.colorScheme.primary,
                  onChanged: (_) => onPressed?.call(),
                ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
              const SizedBox(height: 8),
              Text(item.label, textAlign: TextAlign.center, style: labelStyle),
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
          padding: EdgeInsets.symmetric(
            horizontal: item.isTogglable ? 12 : 14,
            vertical: item.isTogglable ? 10 : 16,
          ),
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

class _HexagonComposeButton extends StatelessWidget {
  const _HexagonComposeButton({required this.onTap});

  final VoidCallback onTap;

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
            child: const Center(
              child: Icon(
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

// Legacy hexagon button shapes removed after switching to rectangular FAB

class _StoryRail extends StatelessWidget {
  const _StoryRail();

  @override
  Widget build(BuildContext context) {
    final stories = _demoStories;
    final theme = Theme.of(context);

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
            final bool isSelf = story.label == 'You';
            final Color borderColor = isSelf
                ? AppTheme.accent
                : theme.colorScheme.primary.withValues(alpha: 0.25);
            final Color background = isSelf
                ? AppTheme.accent.withValues(alpha: 0.9)
                : Theme.of(context).colorScheme.surface;

            return GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HexagonAvatar(
                    size: 56,
                    backgroundColor: background,
                    borderColor: borderColor,
                    borderWidth: isSelf ? 2 : 1.1,
                    child: Center(
                      child: Text(
                        story.initials,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelf ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (isSelf)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.accent,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppTheme.accent,
                          size: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      story.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: isSelf ? FontWeight.w600 : FontWeight.w500,
                        color: isSelf
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
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

const List<_Story> _demoStories = [
  _Story('You'),
  _Story('Design Lab'),
  _Story('Campus Radio'),
  _Story('AI Society'),
  _Story('Eco Club'),
  _Story('Career Office'),
];
