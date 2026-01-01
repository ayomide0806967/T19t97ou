import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/app_providers.dart';
import '../../../models/post.dart';
import 'class_topic_posts_state.dart';

part 'class_topic_posts_controller.g.dart';

/// Controller that exposes posts for a given class topic tag, with simple
/// paging semantics used by the iOS "topic notes" feed.
@riverpod
class ClassTopicPostsController extends _$ClassTopicPostsController {
  static const int _pageSize = 10;

  @override
  ClassTopicPostsState build(String topicTag) {
    final posts = _postsForTag(topicTag);
    final initialVisible =
        posts.isEmpty ? 0 : (posts.length < _pageSize ? posts.length : _pageSize);
    return ClassTopicPostsState(
      topicTag: topicTag,
      posts: posts,
      visibleCount: initialVisible,
      isLoading: false,
    );
  }

  List<PostModel> _postsForTag(String topicTag) {
    final repo = ref.read(postRepositoryProvider);
    return repo.posts.where((p) => p.tags.contains(topicTag)).toList();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current.isLoading) return;
    if (current.posts.isEmpty) return;
    if (current.visibleCount >= current.posts.length) return;

    state = current.copyWith(isLoading: true, errorMessage: null);

    // Preserve the slight delay from the legacy implementation so the UI
    // shows a subtle loading spinner.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final posts = _postsForTag(current.topicTag);
    final nextVisible = current.visibleCount + _pageSize;
    final clampedVisible =
        nextVisible > posts.length ? posts.length : nextVisible;

    state = state.copyWith(
      posts: posts,
      visibleCount: clampedVisible,
      isLoading: false,
    );
  }
}

