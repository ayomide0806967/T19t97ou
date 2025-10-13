import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_avatar.dart';
import '../widgets/brand_mark.dart';
import '../widgets/floating_nav_bar.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'compose_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'For You',
    'OSCE Prep',
    'Clinical Skills',
    'Public Health',
    'Medication Safety',
    'Leadership',
    'Research',
  ];

  final List<TrendingTopic> _trendingTopics = [
    TrendingTopic(
      category: 'NMCN',
      title: 'OSCE Medication Checks',
      posts: '9.4K',
      engagement: '💡 Key Focus',
    ),
    TrendingTopic(
      category: 'Clinical Skills',
      title: 'Sterile Dressing Routine',
      posts: '7.2K',
      engagement: '📈 Rising',
    ),
    TrendingTopic(
      category: 'Public Health',
      title: 'Community Hypertension Drive',
      posts: '5.9K',
      engagement: '🌍 Impact',
    ),
    TrendingTopic(
      category: 'Midwifery',
      title: 'Labour Support Protocols',
      posts: '6.8K',
      engagement: '🤰 Active',
    ),
    TrendingTopic(
      category: 'Mental Wellness',
      title: 'Night Shift Recovery',
      posts: '4.1K',
      engagement: '✨ New',
    ),
  ];

  final List<SuggestedUser> _suggestedUsers = [
    SuggestedUser(
      name: 'Clinical Skills Lab',
      handle: '@skills_lab',
      bio: 'Daily demos for procedures & simulations',
      followers: '3.6K',
      isVerified: true,
    ),
    SuggestedUser(
      name: 'Nursing Leadership Forum',
      handle: '@matrons_circle',
      bio: 'Charge nurses sharing shift-ready playbooks',
      followers: '5.1K',
      isVerified: true,
    ),
    SuggestedUser(
      name: 'NMCN Exam Coach',
      handle: '@nmcncoach',
      bio: 'Bite-sized revisions for OSCE & qualifying exams',
      followers: '7.9K',
      isVerified: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: CustomScrollView(
                slivers: [
                  _buildSearchHeader(),
                  _buildCategories(),
                  _buildTrendingTopics(),
                  _buildSuggestedUsers(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchHeader() {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.4 : 0.2),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BrandMark(size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Explore',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search nursing topics, clinical tips, tags...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: () {},
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CategoryChip(
                label: _categories[index],
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = index;
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  List<TrendingTopic> get _filteredTopics {
    final query = _searchController.text.trim().toLowerCase();
    final selectedCategory = _categories[_selectedCategory];
    return _trendingTopics.where((t) {
      final matchesQuery =
          query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query);
      final matchesCategory =
          selectedCategory == 'For You' || t.category == selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Widget _buildTrendingTopics() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppTheme.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trending Topics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._filteredTopics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TrendingTopicCard(topic: topic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedUsers() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested for You',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ..._suggestedUsers.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SuggestedUserCard(user: user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return FloatingNavBar(
      currentIndex: 1,
      destinations: [
        FloatingNavBarDestination(
          icon: Icons.home_outlined,
          label: 'Home',
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        const FloatingNavBarDestination(
          icon: Icons.explore_outlined,
          label: 'Explore',
        ),
        FloatingNavBarDestination(
          icon: Icons.mode_edit_outline_rounded,
          label: 'Compose',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ComposeScreen()),
            );
          },
        ),
        FloatingNavBarDestination(
          icon: Icons.mark_chat_unread_outlined,
          label: 'Chat',
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          },
        ),
        FloatingNavBarDestination(
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accent : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TrendingTopicCard extends StatelessWidget {
  const _TrendingTopicCard({required this.topic});

  final TrendingTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  topic.category,
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                topic.posts,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            topic.title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            topic.engagement,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SuggestedUserCard extends StatelessWidget {
  const _SuggestedUserCard({required this.user});

  final SuggestedUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          HexagonAvatar(
            size: 48,
            child: Center(
              child: Text(
                user.name.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                      user.name,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppTheme.accent,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.handle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.bio,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                user.followers,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'followers',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrendingTopic {
  const TrendingTopic({
    required this.category,
    required this.title,
    required this.posts,
    required this.engagement,
  });

  final String category;
  final String title;
  final String posts;
  final String engagement;
}

class SuggestedUser {
  const SuggestedUser({
    required this.name,
    required this.handle,
    required this.bio,
    required this.followers,
    required this.isVerified,
  });

  final String name;
  final String handle;
  final String bio;
  final String followers;
  final bool isVerified;
}
