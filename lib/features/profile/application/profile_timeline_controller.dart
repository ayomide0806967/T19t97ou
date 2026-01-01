import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/app_providers.dart';
import '../../../models/post.dart';
import '../../feed/domain/post_repository.dart';

part 'profile_timeline_controller.g.dart';

class ProfileTimelineState {
  const ProfileTimelineState({
    this.posts = const <PostModel>[],
    this.replies = const <PostModel>[],
    this.bookmarks = const <PostModel>[],
  });

  final List<PostModel> posts;
  final List<PostModel> replies;
  final List<PostModel> bookmarks;

  ProfileTimelineState copyWith({
    List<PostModel>? posts,
    List<PostModel>? replies,
    List<PostModel>? bookmarks,
  }) {
    return ProfileTimelineState(
      posts: posts ?? this.posts,
      replies: replies ?? this.replies,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}

@riverpod
class ProfileTimelineController extends _$ProfileTimelineController {
  PostRepository get _repository => ref.read(postRepositoryProvider);

  @override
  ProfileTimelineState build(String handle) {
    final normalized = handle.trim();
    if (normalized.isEmpty) {
      return const ProfileTimelineState();
    }

    // Subscribe to the user's timeline so that new posts/bookmarks flow
    // into the profile screen reactively.
    final sub = _repository.watchUserTimeline(normalized).listen((posts) {
      final replies = _repository.repliesForHandle(normalized);
      final bookmarks =
          posts.where((post) => post.bookmarks > 0).toList(growable: false);
      state = ProfileTimelineState(
        posts: posts,
        replies: replies,
        bookmarks: bookmarks,
      );
    });
    ref.onDispose(sub.cancel);

    // Initial snapshot based on the current repository contents.
    final initialPosts = _repository.postsForHandle(normalized);
    final initialReplies = _repository.repliesForHandle(normalized);
    final initialBookmarks = initialPosts
        .where((post) => post.bookmarks > 0)
        .toList(growable: false);

    return ProfileTimelineState(
      posts: initialPosts,
      replies: initialReplies,
      bookmarks: initialBookmarks,
    );
  }
}
