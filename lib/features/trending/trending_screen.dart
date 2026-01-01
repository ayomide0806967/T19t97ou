import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/app_providers.dart';
import '../../core/navigation/app_nav.dart';
import '../../core/ui/quick_controls/quick_control_item.dart';
import '../../core/ui/snackbars.dart';
import '../../core/ui/theme_mode_controller.dart';
import '../../models/post.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_tab_scaffold.dart';
import '../../widgets/quick_control_grid.dart';
import '../../widgets/tweet_post_card.dart';
import '../auth/application/auth_controller.dart';
import '../auth/application/session_providers.dart';
import '../feed/application/feed_controller.dart';

part 'trending_screen_parts.dart';
part 'trending_screen_quick_controls.dart';
part 'trending_screen_actions.dart';
part 'trending_screen_build.dart';

class TrendingScreen extends ConsumerStatefulWidget {
  const TrendingScreen({super.key});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

abstract class _TrendingScreenStateBase extends ConsumerState<TrendingScreen> {
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
        (i) => _TopicItem(
          topic: _fallbackTopics[i],
          count: _fallbackTopicCounts[i],
        ),
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
}

class _TrendingScreenState extends _TrendingScreenStateBase
    with _TrendingScreenActions, _TrendingScreenBuild {}
