part of 'trending_screen.dart';

mixin _TrendingScreenBuild on _TrendingScreenStateBase, _TrendingScreenActions {
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

    final currentUserHandle = deriveHandleFromEmail(
      context.read<AuthRepository>().currentUser?.email,
    );

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

    final topPosts = visiblePosts.length > 3
        ? visiblePosts.sublist(0, 3)
        : visiblePosts;

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
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
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
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
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
                                    vertical: 6,
                                  ),
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
                color: theme.dividerColor.withValues(
                  alpha: isDark ? 0.30 : 0.22,
                ),
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
                delegate: SliverChildBuilderDelegate((context, index) {
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
                }, childCount: topPosts.length),
              ),
            SliverToBoxAdapter(
              child: _SectionDivider(
                color: theme.dividerColor.withValues(
                  alpha: isDark ? 0.30 : 0.22,
                ),
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
