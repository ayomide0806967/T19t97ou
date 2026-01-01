import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ui/theme_mode_controller.dart';
import 'navigation_drawer_screen.dart';


mixin NavigationDrawerBuildHelpers on ConsumerState<NavigationDrawerScreen> {
  Widget buildNavigationDrawer(
    ThemeData theme,
    Color surface,
    Color onSurface,
    Color subtle,
  ) {
    final dividerColor = theme.dividerColor.withValues(alpha: 0.2);

    return Drawer(
      backgroundColor: surface,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(right: BorderSide(color: dividerColor)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              buildSearchBar(theme, onSurface, subtle),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildNavigationItems(theme, onSurface, subtle),
                      const SizedBox(height: 32),
                      buildSection(theme, 'Pinned', [
                        NavigationItem(
                          icon: Icons.analytics_outlined,
                          title: 'Research & Analysis',
                          color: const Color(0xFF4299E1),
                        ),
                        NavigationItem(
                          icon: Icons.search_outlined,
                          title: 'Web Search',
                          color: const Color(0xFF48BB78),
                        ),
                        NavigationItem(
                          icon: Icons.book_outlined,
                          title: 'Knowledge Base',
                          color: const Color(0xFF9F7AEA),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      buildSection(theme, 'Recents', [
                        NavigationItem(
                          icon: Icons.person_search_outlined,
                          title: 'User research analysis',
                          color: const Color(0xFF718096),
                        ),
                        NavigationItem(
                          icon: Icons.compare_arrows_outlined,
                          title: 'Competitive analysis',
                          color: const Color(0xFF718096),
                        ),
                        NavigationItem(
                          icon: Icons.note_outlined,
                          title: 'Meeting notes',
                          color: const Color(0xFF718096),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      buildSection(theme, 'Yesterday', [
                        NavigationItem(
                          icon: Icons.trending_up_outlined,
                          title: 'Market trends analysis',
                          color: const Color(0xFF718096),
                        ),
                        NavigationItem(
                          icon: Icons.science_outlined,
                          title: 'Usability testing results',
                          color: const Color(0xFF718096),
                        ),
                        NavigationItem(
                          icon: Icons.compare_arrows_outlined,
                          title: 'Competitive analysis',
                          color: const Color(0xFF718096),
                        ),
                      ]),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              buildUserProfileCard(theme, onSurface, subtle),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar(ThemeData theme, Color onSurface, Color subtle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(color: subtle),
          prefixIcon: Icon(Icons.search, color: subtle, size: 20),
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

  Widget buildNavigationItems(
    ThemeData theme,
    Color onSurface,
    Color subtle,
  ) {
    return Column(
      children: [
        NavigationItem(
          icon: Icons.add_circle_outline,
          title: 'New Chat',
          color: const Color(0xFF48BB78),
          hasBadge: true,
        ),
        const SizedBox(height: 8),
        NavigationItem(
          icon: Icons.folder_outlined,
          title: 'Projects',
          color: const Color(0xFF4299E1),
        ),
        const SizedBox(height: 8),
        NavigationItem(
          icon: Icons.library_books_outlined,
          title: 'Library',
          color: const Color(0xFFED8936),
        ),
      ],
    );
  }

  Widget buildSection(ThemeData theme, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface
                  .withValues(alpha: theme.brightness == Brightness.dark ? 0.55 : 0.5),
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

  Widget buildUserProfileCard(
    ThemeData theme,
    Color onSurface,
    Color subtle,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (theme.brightness != Brightness.dark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showProfileDropdown(),
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
                  child: const Center(
                    child: Text(
                      'JB',
                      style: TextStyle(
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
                        'James Brown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'james@alignui.com',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtle,
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
                    'PRO',
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

  void showProfileDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final surface = theme.colorScheme.surface;
        final divider = theme.dividerColor;

        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: divider.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
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
                  color: divider.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      buildDropdownItem(
                        theme: theme,
                        icon: ref.watch(themeModeControllerProvider) ==
                                ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        title: 'Dark Mode',
                        trailing: Switch(
                          value: ref.watch(themeModeControllerProvider) ==
                              ThemeMode.dark,
                          onChanged: (value) async {
                            Navigator.pop(sheetContext);
                            await ref
                                .read(
                                  themeModeControllerProvider.notifier,
                                )
                                .toggleDarkMode(value);
                          },
                          activeThumbColor: theme.colorScheme.primary,
                          activeTrackColor:
                              theme.colorScheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    const SizedBox(height: 12),
                    buildDropdownItem(
                      theme: theme,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () => Navigator.pop(sheetContext),
                    ),
                    buildDropdownItem(
                      theme: theme,
                      icon: Icons.language_outlined,
                      title: 'Language',
                      onTap: () => Navigator.pop(sheetContext),
                    ),
                    buildDropdownItem(
                      theme: theme,
                      icon: Icons.help_outline,
                      title: 'Help',
                      onTap: () => Navigator.pop(sheetContext),
                    ),
                      const SizedBox(height: 8),
                      Divider(color: divider),
                      const SizedBox(height: 8),
                      buildDropdownItem(
                        theme: theme,
                        icon: Icons.logout_outlined,
                        title: 'Log out',
                        color: const Color(0xFFF56565),
                        onTap: () => Navigator.pop(sheetContext),
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

  Widget buildDropdownItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    final itemColor = color ?? theme.colorScheme.onSurface;

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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: itemColor,
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

  Widget buildWelcomeSection(ThemeData theme, Color onSurface) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, James!',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s what\'s happening with your projects today.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Text(
              '3 new tasks • 5 messages • 2 updates',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatsGrid(ThemeData theme, Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            buildStatCard(
              theme: theme,
              onSurface: onSurface,
              title: 'Active Projects',
              value: '12',
              icon: Icons.folder_outlined,
              color: const Color(0xFF4299E1),
              change: '+2',
            ),
            buildStatCard(
              theme: theme,
              onSurface: onSurface,
              title: 'Completed Tasks',
              value: '48',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF48BB78),
              change: '+8',
            ),
            buildStatCard(
              theme: theme,
              onSurface: onSurface,
              title: 'Team Members',
              value: '24',
              icon: Icons.people_outline,
              color: const Color(0xFF9F7AEA),
              change: '+1',
            ),
            buildStatCard(
              theme: theme,
              onSurface: onSurface,
              title: 'Messages',
              value: '156',
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFFED8936),
              change: '+12',
            ),
          ],
        ),
      ],
    );
  }

  Widget buildStatCard({
    required ThemeData theme,
    required Color onSurface,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.25),
        ),
        boxShadow: theme.brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.arrow_upward,
                color: const Color(0xFF48BB78),
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                change,
                style: const TextStyle(
                  color: Color(0xFF48BB78),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRecentActivity(
    ThemeData theme,
    Color onSurface,
    Color subtle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
            boxShadow: theme.brightness == Brightness.dark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            children: [
              buildActivityItem(
                theme: theme,
                onSurface: onSurface,
                subtle: subtle,
                icon: Icons.file_download_outlined,
                title: 'Research Report Completed',
                subtitle: 'Market analysis Q3 2024',
                time: '2 hours ago',
                color: const Color(0xFF4299E1),
              ),
              buildActivityItem(
                theme: theme,
                onSurface: onSurface,
                subtle: subtle,
                icon: Icons.chat_outlined,
                title: 'New team message',
                subtitle: 'Design team discussion',
                time: '4 hours ago',
                color: const Color(0xFF48BB78),
              ),
              buildActivityItem(
                theme: theme,
                onSurface: onSurface,
                subtle: subtle,
                icon: Icons.task_alt_outlined,
                title: 'Task completed',
                subtitle: 'Update user documentation',
                time: '6 hours ago',
                color: const Color(0xFFED8936),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildActivityItem({
    required ThemeData theme,
    required Color onSurface,
    required Color subtle,
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: subtle),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.labelSmall?.copyWith(color: subtle),
          ),
        ],
      ),
    );
  }

  Widget buildQuickActions(ThemeData theme, Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                theme: theme,
                icon: Icons.add_circle_outline,
                label: 'New Project',
                color: const Color(0xFF4299E1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                theme: theme,
                icon: Icons.upload_file_outlined,
                label: 'Upload File',
                color: const Color(0xFF48BB78),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                theme: theme,
                icon: Icons.schedule_outlined,
                label: 'Schedule',
                color: const Color(0xFF9F7AEA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem extends StatelessWidget {
  const NavigationItem({
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.2);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface,
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
