import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../feed/domain/post_repository.dart';
import '../../../models/thread_entry.dart';

/// Controller for message-thread side effects that should impact the global
/// feed, such as ensuring a reply also surfaces a repost.
class MessageThreadController extends Notifier<void> {
  @override
  void build() {}

  PostRepository get _repository => ref.read(postRepositoryProvider);

  /// Ensures that replying to a message also surfaces the related post
  /// as a repost on the user's timeline.
  Future<void> ensureRepostForReply({
    required String postId,
    required String userHandle,
  }) async {
    final handle = userHandle.trim();
    if (handle.isEmpty) return;

    final alreadyReposted = _repository.hasUserReposted(postId, handle);
    if (alreadyReposted) return;

    await _repository.toggleRepost(postId: postId, userHandle: handle);
  }

  /// Toggles a repost for the given user and post, returning the new state.
  Future<bool> toggleRepost({
    required String postId,
    required String userHandle,
  }) {
    return _repository.toggleRepost(postId: postId, userHandle: userHandle);
  }

  /// Returns whether the given user has already reposted the post.
  bool hasUserReposted({
    required String postId,
    required String userHandle,
  }) {
    final handle = userHandle.trim();
    if (handle.isEmpty) return false;
    return _repository.hasUserReposted(postId, handle);
  }

  /// Builds a full thread for the given post id using the underlying
  /// [PostRepository]. This keeps widget code from depending on the
  /// repository directly.
  ThreadEntry buildThread(String postId) {
    return _repository.buildThreadForPost(postId);
  }
}

final messageThreadControllerProvider =
    NotifierProvider<MessageThreadController, void>(
  MessageThreadController.new,
);
