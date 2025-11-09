import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../widgets/tweet_post_card.dart';
import '../widgets/hexagon_avatar.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final List<String> _filters = const [
    'Trending Topics',
    'Trending Tweet',
  ];
  String _selected = 'Trending Topics';
  String? _filteredHandle;

  String _deriveHandle(SimpleAuthService auth) {
    final email = auth.currentUserEmail;
    if (email == null || email.isEmpty) return '@yourprofile';
    final normalized = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
    return normalized.isEmpty ? '@yourprofile' : '@$normalized';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    // removed unused `subtle`

    final items = _selected == 'Trending Topics'
        ? _demoTrending
        : _demoTrending
            .where((e) => e.category == _selected)
            .toList();

    final dataService = context.watch<DataService>();
    final timeline = dataService.timelinePosts;
    final allPosts = List.of(timeline);
    allPosts.sort((a, b) {
      int score(PostModel p) => p.likes + p.reposts * 2 + (p.views ~/ 100);
      return score(b).compareTo(score(a));
    });

    final posts = _filteredHandle == null
        ? List<PostModel>.from(allPosts)
        : allPosts.where((post) => post.handle == _filteredHandle).toList();

    final List<PostModel> trendingProfiles = [];
    final Set<String> seen = <String>{};
    for (final post in allPosts) {
      if (seen.add(post.handle)) {
        trendingProfiles.add(post);
        if (trendingProfiles.length == 6) break;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.45 : 0.25),
            ),
          ),
          child: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back, color: onSurface, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Trending',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderBanner(
                    profiles: trendingProfiles,
                    onOpen: () => setState(() {
                      _selected = 'Trending Tweet';
                      _filteredHandle = null;
                    }),
                    onProfileTap: (handle) => setState(() {
                      _selected = 'Trending Tweet';
                      _filteredHandle = handle;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _SearchBar(),
                  const SizedBox(height: 12),
                  _FilterChips(
                    filters: _filters,
                    selected: _selected,
                    onSelected: (value) => setState(() {
                      _selected = value;
                      if (value != 'Trending Tweet') {
                        _filteredHandle = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_selected == 'Trending Tweet')
            (posts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                      child: _TrendingEmptyState(handle: _filteredHandle),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];
                        final handle = _deriveHandle(SimpleAuthService());
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                              20, index == 0 ? 0 : 12, 20, 12),
                          child: TweetPostCard(
                            post: post,
                            currentUserHandle: handle,
                            backgroundColor: Theme.of(context).cardColor,
                          ),
                        );
                      },
                      childCount: posts.length,
                    ),
                  ))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, index == 0 ? 0 : 12, 20, 12),
                    child: _TrendingCard(item: item),
                  );
                },
                childCount: items.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.profiles, this.onOpen, this.onProfileTap});
  final List<PostModel> profiles;
  final VoidCallback? onOpen;
  final ValueChanged<String>? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color outline =
        theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.24);
    final Color chipColor = theme.colorScheme.primary.withValues(alpha: 0.08);
    final Color onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.7 : 0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: outline, width: 1.1),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Trends',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _HexAvatarStrip(
                          profiles: profiles,
                          onProfileTap: onProfileTap,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'See topics getting the biggest reaction from the community.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subtle,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HexAvatarStrip extends StatelessWidget {
  const _HexAvatarStrip({required this.profiles, this.onProfileTap});
  final List<PostModel> profiles;
  final ValueChanged<String>? onProfileTap;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();

    final List<Color> palette = const [
      Color(0xFFD946EF),
      Color(0xFF818CF8),
      Color(0xFFFB7185),
      Color(0xFF38BDF8),
      Color(0xFF34D399),
      Color(0xFFF97316),
      Color(0xFF60A5FA),
    ];

    final List<PostModel> visibleProfiles =
        profiles.length > 6 ? profiles.sublist(0, 6) : profiles;
    return SizedBox(
      height: 40,
      width: 40 + (visibleProfiles.length - 1) * 24,
      child: Stack(
        children: [
          for (int i = 0; i < visibleProfiles.length; i++)
            Positioned(
              left: i * 24,
              child: GestureDetector(
                onTap: onProfileTap == null
                    ? null
                    : () => onProfileTap!(visibleProfiles[i].handle),
                child: HexagonAvatar(
                  size: 40,
                  backgroundColor: palette[i % palette.length],
                  borderColor: Colors.white,
                  borderWidth: 2,
                  child: Center(
                    child: Text(
                      _initialsFor(visibleProfiles[i].author),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '#';
  if (parts.length == 1) {
    final part = parts.first;
    return part.length >= 2
        ? part.substring(0, 2).toUpperCase()
        : part.substring(0, 1).toUpperCase();
  }
  final first = parts.first;
  final last = parts.last;
  return '${first[0]}${last[0]}'.toUpperCase();
}

class _TrendingEmptyState extends StatelessWidget {
  const _TrendingEmptyState({this.handle});
  final String? handle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = handle == null
        ? 'No trending posts yet'
        : 'No posts for $handle right now';
    final subtitle = handle == null
        ? 'Try checking back later or follow more creators to see activity here.'
        : 'When $handle shares something popular, it will show up here.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_fire_department_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ??
                    const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search trending topics... ',
        prefixIcon: Icon(Icons.search, color: theme.textTheme.bodySmall?.color),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color baseBackground = isDark ? Colors.black : Colors.white;
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.08);
    final Color selectedBackground = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFE2E8F0);
    final Color selectedText = theme.colorScheme.onSurface;
    final Color unselectedText =
        isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.65);

    return Row(
      children: List.generate(filters.length, (index) {
        final label = filters[index];
        final bool isSelected = label == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == filters.length - 1 ? 0 : 6,
            ),
            child: ChoiceChip(
              label: Text(label.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => onSelected(label),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: isSelected ? selectedText : unselectedText,
              ),
              shape: const StadiumBorder(),
              side: BorderSide(color: isSelected ? selectedBackground : borderColor),
              backgroundColor: baseBackground,
              selectedColor: selectedBackground,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              elevation: 0,
              pressElevation: 0,
            ),
          ),
        );
      }),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.item});

  final _TrendingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = onSurface.withValues(alpha: isDark ? 0.65 : 0.6);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(gradient: item.gradient, icon: item.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _CategoryPill(text: item.category),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: subtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MetricChip(
                  icon: Icons.local_fire_department_outlined,
                  label: item.trendingScore,
                ),
                const SizedBox(width: 8),
                _MetricChip(icon: Icons.trending_up, label: item.growth),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening ${item.title}…'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.gradient, required this.icon});
  final Gradient gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[50],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingItem {
  const _TrendingItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.trendingScore,
    required this.growth,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final String category;
  final String trendingScore;
  final String growth;
  final IconData icon;
  final Gradient gradient;
}

const List<_TrendingItem> _demoTrending = [
  _TrendingItem(
    title: 'AI study groups forming',
    subtitle: 'Students collaborating on ML projects and Kaggle comps',
    category: 'AI',
    trendingScore: '12.3K',
    growth: '+34%',
    icon: Icons.groups_3_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TrendingItem(
    title: 'Residency application tips',
    subtitle: 'Senior advice threads for matching in 2026',
    category: 'Health',
    trendingScore: '8.1K',
    growth: '+18%',
    icon: Icons.medical_services_outlined,
    gradient: LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TrendingItem(
    title: 'Rust vs Go for services',
    subtitle: 'Discussion on performance, safety and ergonomics',
    category: 'Tech',
    trendingScore: '6.9K',
    growth: '+22%',
    icon: Icons.memory_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFFB7185), Color(0xFFF97316)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TrendingItem(
    title: 'Grant writing workshop',
    subtitle: 'Best practices to land that research funding',
    category: 'Research',
    trendingScore: '4.4K',
    growth: '+12%',
    icon: Icons.attach_money_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF34D399)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TrendingItem(
    title: 'Board prep resources',
    subtitle: 'High-yield decks and spaced repetition strategies',
    category: 'Education',
    trendingScore: '3.2K',
    growth: '+9%',
    icon: Icons.menu_book_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF9F7AEA), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];
