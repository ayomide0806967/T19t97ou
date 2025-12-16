import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/simple_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/tweet_post_card.dart';
import 'compose_screen.dart';
import 'neutral_page.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  String _query = '';
  int _selectedBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _searchController.addListener(() {
      final next = _searchController.text;
      if (next == _query) return;
      setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  int _score(PostModel p) => p.likes + (p.reposts * 2) + (p.views ~/ 100);

  String _normalizedQuery() => _query.trim().toLowerCase();

  List<_TopicItem> _topicItemsFor(
    List<MapEntry<String, int>> sortedTopics, {
    required String query,
  }) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      if (sortedTopics.isNotEmpty) {
        return sortedTopics
            .take(6)
            .map((e) => _TopicItem(topic: e.key, count: e.value))
            .toList();
      }
      return List<_TopicItem>.generate(
        _fallbackTopics.length,
        (i) => _TopicItem(topic: _fallbackTopics[i], count: _fallbackTopicCounts[i]),
      );
    }

    final matched = sortedTopics
        .where((e) => e.key.toLowerCase().contains(q))
        .take(8)
        .map((e) => _TopicItem(topic: e.key, count: e.value))
        .toList();
    if (matched.isNotEmpty) return matched;

    final fallbackMatched = <_TopicItem>[];
    for (int i = 0; i < _fallbackTopics.length; i++) {
      if (_fallbackTopics[i].toLowerCase().contains(q)) {
        fallbackMatched.add(
          _TopicItem(topic: _fallbackTopics[i], count: _fallbackTopicCounts[i]),
        );
      }
    }
    return fallbackMatched.take(8).toList();
  }

  Future<void> _showQuickControls() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.75 : 0.65,
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded),
                  title: const Text('Back to top'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  },
                ),
                if (_query.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.clear_rounded),
                    title: const Text('Clear search'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _searchController.clear();
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.arrow_back_rounded, color: subtle),
                  title: Text(
                    'Back',
                    style: theme.textTheme.bodyLarge?.copyWith(color: subtle),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).maybePop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final dataService = context.watch<DataService>();
    final timeline = dataService.timelinePosts;
    final allPosts = List.of(timeline);
    allPosts.sort((a, b) {
      return _score(b).compareTo(_score(a));
    });

    final currentUserHandle = _deriveHandle(SimpleAuthService());

    final Map<String, int> topicCounts = <String, int>{};
    for (final post in allPosts) {
      for (final tag in post.tags) {
        final cleaned = tag.trim();
        if (cleaned.isEmpty) continue;
        topicCounts[cleaned] = (topicCounts[cleaned] ?? 0) + 1;
      }
    }
    final List<MapEntry<String, int>> topTopics = topicCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    final q = _normalizedQuery();

    final visiblePosts = q.isEmpty
        ? allPosts
        : allPosts.where((p) {
            return p.author.toLowerCase().contains(q) ||
                p.handle.toLowerCase().contains(q) ||
                p.body.toLowerCase().contains(q) ||
                p.tags.any((t) => t.toLowerCase().contains(q));
          }).toList();

    final topPosts =
        visiblePosts.length > 3 ? visiblePosts.sublist(0, 3) : visiblePosts;

    final List<PostModel> whoToFollow = <PostModel>[];
    final Set<String> seenHandles = <String>{};
    for (final post in allPosts) {
      if (post.handle == currentUserHandle) continue;
      if (seenHandles.add(post.handle)) {
        whoToFollow.add(post);
      }
      if (whoToFollow.length == 3) break;
    }

    final visibleWhoToFollow = q.isEmpty
        ? whoToFollow
        : whoToFollow.where((p) {
            return p.author.toLowerCase().contains(q) ||
                p.handle.toLowerCase().contains(q);
          }).toList();

    final topicItems = _topicItemsFor(topTopics, query: _query);

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
            tooltip: 'Quick controls',
            icon: _QuickControlIcon(color: onSurface.withValues(alpha: 0.65)),
            onPressed: _showQuickControls,
          ),
        ),
        title: Text(
          'TRENDS',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: _TrendingSearchBar(
                controller: _searchController,
                hintText: 'Search IN INSTITUTION',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Top topics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (topicItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No topics found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double gap = 8;
                        final int itemCount = topicItems.length;
                        final double itemWidth =
                            (constraints.maxWidth - (gap * 2)) / 3;

                        final List<Widget> rows = <Widget>[];

                        for (int i = 0; i < itemCount; i += 3) {
                          rows.add(
                            Row(
                              children: [
                                for (int j = 0; j < 3; j++)
                                  if (i + j < itemCount)
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: j < 2 ? gap : 0,
                                        ),
                                        child: SizedBox(
                                          width: itemWidth,
                                          child: _TopicChip(
                                            topic: topicItems[i + j].topic,
                                            count: topicItems[i + j].count,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Expanded(child: SizedBox()),
                              ],
                            ),
                          );

                          if (i + 3 < itemCount) {
                            rows.add(
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Divider(
                                  height: 1,
                                  thickness: 1.2,
                                  color: theme.dividerColor.withValues(
                                    alpha: isDark ? 0.65 : 0.45,
                                  ),
                                ),
                              ),
                            );
                          }
                        }

                        return Column(children: rows);
                      },
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionDivider(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.30 : 0.22),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _SectionHeader(
                title: 'Top posts',
                subtitle: 'Most engagement across the app',
              ),
            ),
          ),
          if (visiblePosts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _TrendingEmptyState(),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = topPosts[index];
                  final bool isLast = index == topPosts.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          index == 0 ? 0 : 12,
                          20,
                          12,
                        ),
                        child: TweetPostCard(
                          post: post,
                          currentUserHandle: currentUserHandle,
                          backgroundColor: theme.cardColor,
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: theme.dividerColor.withValues(
                              alpha: isDark ? 0.30 : 0.22,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                childCount: topPosts.length,
              ),
            ),
          SliverToBoxAdapter(
            child: _SectionDivider(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.30 : 0.22),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _SectionHeader(
                title: 'Who to follow',
                subtitle: 'Creators with active discussions',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _SectionCard(
                child: Column(
                  children: [
                    if (visibleWhoToFollow.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: _WhoToFollowEmpty(),
                      )
                    else
                      for (int i = 0; i < visibleWhoToFollow.length; i++)
                        _FollowRow(
                          author: visibleWhoToFollow[i].author,
                          handle: visibleWhoToFollow[i].handle,
                          showDivider: i != visibleWhoToFollow.length - 1,
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
        if (index == 2) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ComposeScreen()))
              .then((_) => resetToHome());
          return;
        }
        if (mounted) setState(() => _selectedBottomNavIndex = index);
      },
      destinations: [
        FloatingNavBarDestination(
          icon: Icons.home_filled,
          onTap: () {
            if (!mounted) return;
            setState(() => _selectedBottomNavIndex = 0);
            Navigator.of(context).maybePop();
          },
        ),
        FloatingNavBarDestination(
          icon: Icons.mail_outline_rounded,
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => const NeutralPage()))
                .then((_) => resetToHome());
          },
        ),
        const FloatingNavBarDestination(icon: Icons.add, onTap: null),
        FloatingNavBarDestination(
          icon: Icons.favorite_border_rounded,
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => const NotificationsScreen()))
                .then((_) => resetToHome());
          },
        ),
        FloatingNavBarDestination(
          icon: Icons.person_outline_rounded,
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => const ProfileScreen()))
                .then((_) => resetToHome());
          },
        ),
      ],
    );
  }
}

class _TopicItem {
  const _TopicItem({required this.topic, required this.count});

  final String topic;
  final int count;
}

class _TrendingSearchBar extends StatelessWidget {
  const _TrendingSearchBar({
    required this.controller,
    required this.hintText,
    this.dense = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.55,
    );

    final Color fill = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        boxShadow: dense
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: AppTheme.tweetBody(theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTheme.tweetBody(subtle),
          prefixIcon: Icon(Icons.search, color: subtle),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close_rounded, color: subtle),
                  onPressed: controller.clear,
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: dense,
          contentPadding: dense
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}

const List<String> _fallbackTopics = [
  'NMCN Key Points',
  'Skills Lab',
  'Emergency Care',
  'Community Posting',
  'OSCE Practice',
  'Exam Prep',
  'Clinical Skills',
  'Research Updates',
  'Case Studies',
  'Student Life',
  'Medication Safety',
  'Simulation Lab',
];

const List<int> _fallbackTopicCounts = [
  39200,
  13700,
  1227,
  1271,
  8450,
  2310,
  5640,
  4210,
  3125,
  2760,
];

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, thickness: 1, color: color),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.2);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.showDivider,
    this.count,
  });

  final String topic;
  final int? count;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );
    final Color line = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.18);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In Nigeria',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic,
                      style: AppTheme.tweetBody(theme.colorScheme.onSurface)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCount(count ?? 0)} posts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(top: 2),
                icon: Icon(Icons.more_vert_rounded, color: subtle),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('More options for $topic'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: line),
      ],
    );
  }

  static String _formatCount(int value) {
    if (value >= 1000000) {
      final m = value / 1000000.0;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final k = value / 1000.0;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return value.toString();
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.topic,
    required this.count,
  });

  final String topic;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );
    final Color border =
        theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topic,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.tweetBody(theme.colorScheme.onSurface).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_TopicRow._formatCount(count)} posts',
            style: theme.textTheme.bodySmall?.copyWith(color: subtle),
          ),
        ],
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.author,
    required this.handle,
    required this.showDivider,
  });

  final String author;
  final String handle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );
    final Color line = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.18);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialsFor(author),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      handle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtle,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Following $handle'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Follow'),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.zero,
            child: Divider(height: 1, thickness: 1, color: line),
          ),
      ],
    );
  }

  static String _initialsFor(String name) {
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
}

class _WhoToFollowEmpty extends StatelessWidget {
  const _WhoToFollowEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color subtle = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.65 : 0.6,
    );
    return Text(
      'No suggestions yet.',
      style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
    );
  }
}

class _TrendingEmptyState extends StatelessWidget {
  const _TrendingEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const title = 'No posts yet';
    const subtitle =
        'Try checking back later or follow more creators to see activity here.';

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

class _QuickControlIcon extends StatelessWidget {
  const _QuickControlIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuickControlLine(color: color),
          const SizedBox(height: 6),
          _QuickControlLine(color: color),
        ],
      ),
    );
  }
}

class _QuickControlLine extends StatelessWidget {
  const _QuickControlLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
