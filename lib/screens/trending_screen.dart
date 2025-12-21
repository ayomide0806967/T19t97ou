import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth/auth_repository.dart';
import '../core/user/handle.dart';
import '../core/feed/post_repository.dart';
import '../core/navigation/app_nav.dart';
import '../models/post.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_tab_scaffold.dart';
import '../widgets/tweet_post_card.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  String _query = '';

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
    final navigator = Navigator.of(context);
    final appSettings = context.read<AppSettings>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _TrendingQuickControlPanel(
          theme: theme,
          appSettings: appSettings,
          onCompose: () async {
            await navigator.push(AppNav.compose());
          },
          onBackToTop: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          },
          onClearSearch: () {
            _searchController.clear();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final timeline = context.watch<PostRepository>().timelinePosts;
    final allPosts = List.of(timeline);
    allPosts.sort((a, b) {
      return _score(b).compareTo(_score(a));
    });

    final currentUserHandle =
        deriveHandleFromEmail(context.read<AuthRepository>().currentUser?.email);

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

    return AppTabScaffold(
      currentIndex: 0,
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          // A swipe from left to right (positive velocity) should
          // navigate back to the home feed.
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 0) {
            Navigator.of(context).maybePop();
          }
        },
        child: CustomScrollView(
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
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
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
                color:
                    theme.dividerColor.withValues(alpha: isDark ? 0.30 : 0.22),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
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
                color:
                    theme.dividerColor.withValues(alpha: isDark ? 0.30 : 0.22),
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
      ),
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

class _TrendingQuickControlPanel extends StatefulWidget {
  const _TrendingQuickControlPanel({
    required this.theme,
    required this.appSettings,
    required this.onCompose,
    required this.onBackToTop,
    required this.onClearSearch,
  });

  final ThemeData theme;
  final AppSettings appSettings;
  final VoidCallback onCompose;
  final VoidCallback onBackToTop;
  final VoidCallback onClearSearch;

  @override
  State<_TrendingQuickControlPanel> createState() =>
      _TrendingQuickControlPanelState();
}

class _TrendingQuickControlPanelState
    extends State<_TrendingQuickControlPanel> {
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
          await Navigator.of(context).push(AppNav.classes());
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
          await Navigator.of(context).push(AppNav.quizDashboard());
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
          await Navigator.of(context).push(AppNav.classes());
        },
      ),
      _QuickControlItem(
        icon: Icons.search_rounded,
        label: 'Search',
        onPressed: () async {
          Navigator.of(context).pop();
          // Already on search/trends page – just close the panel.
        },
      ),
      _QuickControlItem(
        icon: Icons.quiz_outlined,
        label: 'Settings',
        onPressed: () async => _showComingSoon('Settings'),
      ),
      _QuickControlItem(
        icon: Icons.logout_outlined,
        label: 'Log out',
        onPressed: () async {
          Navigator.of(context).pop();
          await context.read<AuthRepository>().signOut();
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
  })  : isTogglable = false,
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

    final bool isLogoutTile = item.label == 'Log out';

    final Color baseIconColor = isActive
        ? (isDark ? Colors.white : Colors.black)
        : theme.colorScheme.onSurface.withValues(alpha: 0.70);
    final Color baseBorderColor = theme.dividerColor.withValues(
      alpha: isActive ? 0.4 : 0.25,
    );
    final Color baseBackgroundColor = isDark
        ? Colors.white.withValues(alpha: isActive ? 0.12 : 0.04)
        : Colors.white.withValues(alpha: isActive ? 0.9 : 0.8);

    final Color iconColor = isLogoutTile ? Colors.white : baseIconColor;
    final Color borderColor =
        isLogoutTile ? const Color(0xFFF56565) : baseBorderColor;
    final Color backgroundColor =
        isLogoutTile ? const Color(0xFFF56565) : baseBackgroundColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed == null ? null : () => onPressed!(),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 24, color: iconColor),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
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
