import 'dart:async';

import 'comment_repository.dart';

/// Local in-memory implementation of [CommentRepository].
///
/// This is intended for offline/demo mode only. Data is kept in memory for the
/// lifetime of the app and is not persisted.
class LocalCommentRepository implements CommentRepository {
  final Map<String, List<Comment>> _commentsByPost = <String, List<Comment>>{};
  final Map<String, StreamController<List<Comment>>> _controllers =
      <String, StreamController<List<Comment>>>{};

  @override
  Stream<List<Comment>> watchComments(String postId) {
    _controllers.putIfAbsent(
      postId,
      () => StreamController<List<Comment>>.broadcast(),
    );
    _emit(postId);
    return _controllers[postId]!.stream;
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    return List<Comment>.unmodifiable(_commentsByPost[postId] ?? <Comment>[]);
  }

  @override
  Future<Comment> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    final now = DateTime.now();
    final id = 'local_comment_${now.microsecondsSinceEpoch}';
    final comment = Comment(
      id: id,
      postId: postId,
      authorId: 'local_user',
      authorName: 'Local User',
      authorHandle: '@local',
      body: body,
      parentCommentId: parentCommentId,
      createdAt: now,
      updatedAt: null,
      likes: 0,
      isLiked: false,
    );
    final list = _commentsByPost.putIfAbsent(postId, () => <Comment>[]);
    list.add(comment);
    _emit(postId);
    return comment;
  }

  @override
  Future<Comment> editComment({
    required String commentId,
    required String body,
  }) async {
    for (final entry in _commentsByPost.entries) {
      final list = entry.value;
      final index = list.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final updated = list[index].copyWith(
          body: body,
          updatedAt: DateTime.now(),
        );
        list[index] = updated;
        _emit(entry.key);
        return updated;
      }
    }
    throw StateError('Comment not found');
  }

  @override
  Future<void> deleteComment(String commentId) async {
    for (final entry in _commentsByPost.entries) {
      final list = entry.value;
      final before = list.length;
      list.removeWhere((c) => c.id == commentId);
      final removed = list.length != before;
      if (removed) {
        _emit(entry.key);
        return;
      }
    }
  }

  @override
  Future<bool> toggleLike(String commentId) async {
    for (final entry in _commentsByPost.entries) {
      final list = entry.value;
      final index = list.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final existing = list[index];
        final isLiked = !existing.isLiked;
        final likes = (existing.likes) + (isLiked ? 1 : -1);
        list[index] = existing.copyWith(
          isLiked: isLiked,
          likes: likes < 0 ? 0 : likes,
        );
        _emit(entry.key);
        return isLiked;
      }
    }
    return false;
  }

  void _emit(String postId) {
    final controller = _controllers[postId];
    if (controller == null || controller.isClosed) return;
    controller.add(
      List<Comment>.unmodifiable(_commentsByPost[postId] ?? <Comment>[]),
    );
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}
