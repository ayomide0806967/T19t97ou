import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/error/app_error_handler.dart';
import '../domain/post_repository.dart';
import '../../../models/post.dart';
import '../domain/feed_state.dart';

/// Riverpod controller that exposes the main feed timeline.
///
/// This sits between UI and the underlying PostRepository implementation
/// (local demo data vs Supabase) and centralizes loading / error handling.
class FeedController extends Notifier<FeedState> {
  StreamSubscription<List<PostModel>>? _subscription;

  @override
  FeedState build() {
    // Subscribe to timeline changes so external mutations (compose, classes)
    // automatically flow into the feed.
    _subscription ??=
        _repository.watchTimeline().listen(_handleTimelineChanged);
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    // Start in a loading state; the first refresh will populate posts.
    _refreshAsync();
    return const FeedState(posts: <PostModel>[], isLoading: true);
  }

  PostRepository get _repository => ref.read(postRepositoryProvider);

  Future<void> refresh() => _refreshAsync();

  void _handleTimelineChanged(List<PostModel> posts) {
    final current = state;
    state = current.copyWith(
      posts: List<PostModel>.from(posts),
    );
  }

  Future<void> _refreshAsync() async {
    final current = state;
    state = current.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.load();
      state = FeedState(
        posts: List<PostModel>.from(_repository.timelinePosts),
        isLoading: false,
      );
    } catch (e) {
      final appError = AppErrorHandler.handle(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: appError.message,
      );
    }
  }

  // =========================================================================
  // Interaction helpers (convenience methods for UI)
  // =========================================================================

  /// Toggle like on a post. Returns true if now liked.
  Future<bool?> toggleLike(String postId) async {
    try {
      return await _repository.toggleLike(postId);
    } catch (e) {
      final appError = AppErrorHandler.handle(e);
      state = state.copyWith(errorMessage: appError.message);
      return null;
    }
  }

  /// Toggle bookmark on a post. Returns true if now bookmarked.
  Future<bool?> toggleBookmark(String postId) async {
    try {
      return await _repository.toggleBookmark(postId);
    } catch (e) {
      final appError = AppErrorHandler.handle(e);
      state = state.copyWith(errorMessage: appError.message);
      return null;
    }
  }

  /// Toggle repost on a post. Returns true if now reposted.
  Future<bool?> toggleRepost({
    required String postId,
    required String userHandle,
  }) async {
    try {
      return await _repository.toggleRepost(
        postId: postId,
        userHandle: userHandle,
      );
    } catch (e) {
      final appError = AppErrorHandler.handle(e);
      state = state.copyWith(errorMessage: appError.message);
      return null;
    }
  }

  /// Delete a post.
  Future<bool> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId: postId);
      return true;
    } catch (e) {
      final appError = AppErrorHandler.handle(e);
      state = state.copyWith(errorMessage: appError.message);
      return false;
    }
  }
}

final feedControllerProvider =
    NotifierProvider<FeedController, FeedState>(FeedController.new);
