import 'package:flutter/material.dart';

class NavigationDrawerScreen extends StatefulWidget {
  const NavigationDrawerScreen({super.key});

  @override
  State<NavigationDrawerScreen> createState() => _NavigationDrawerScreenState();
}

class _NavigationDrawerScreenState extends State<NavigationDrawerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF2D3748), size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2D3748), size: 22),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 32),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildRecentActivity(),
            const SizedBox(height: 32),
            _buildQuickActions(),
          ],
        ),
      ),
      drawer: _buildNavigationDrawer(),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF8F9FA),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFF1F3F4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNavigationItems(),
                      const SizedBox(height: 32),
                      _buildSection('Pinned', [
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
                      _buildSection('Recents', [
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
                      _buildSection('Yesterday', [
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(0, -1),
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white,
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
                      const Text(
                        'James Brown',
                        style: TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'james@alignui.com',
                        style: TextStyle(
                          color: const Color(0xFF718096),
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
                    icon: _darkMode ? Icons.dark_mode : Icons.light_mode,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() {
                          _darkMode = value;
                        });
                        Navigator.pop(context);
                      },
                      activeColor: const Color(0xFF4299E1),
                    ),
                  ),
                  _buildDropdownItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Navigator.pop(context),
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

  Widget _buildWelcomeSection() {
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
          const Text(
            'Welcome back, James!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
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

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 24,
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
            _buildStatCard(
              title: 'Active Projects',
              value: '12',
              icon: Icons.folder_outlined,
              color: const Color(0xFF4299E1),
              change: '+2',
            ),
            _buildStatCard(
              title: 'Completed Tasks',
              value: '48',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF48BB78),
              change: '+8',
            ),
            _buildStatCard(
              title: 'Team Members',
              value: '24',
              icon: Icons.people_outline,
              color: const Color(0xFF9F7AEA),
              change: '+1',
            ),
            _buildStatCard(
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 12,
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

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.file_download_outlined,
                title: 'Research Report Completed',
                subtitle: 'Market analysis Q3 2024',
                time: '2 hours ago',
                color: const Color(0xFF4299E1),
              ),
              _buildActivityItem(
                icon: Icons.chat_outlined,
                title: 'New team message',
                subtitle: 'Design team discussion',
                time: '4 hours ago',
                color: const Color(0xFF48BB78),
              ),
              _buildActivityItem(
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

  Widget _buildActivityItem({
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
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFFA0AEC0),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'New Project',
                color: const Color(0xFF4299E1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.upload_file_outlined,
                label: 'Upload File',
                color: const Color(0xFF48BB78),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
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
            style: TextStyle(
              color: color,
              fontSize: 12,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(0, -1),
            spreadRadius: 1,
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
