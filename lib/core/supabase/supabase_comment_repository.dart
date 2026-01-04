import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../comment/comment_repository.dart';


/// Supabase implementation of [CommentRepository].
///
/// Uses:
/// - `post_comments` table for comment data
/// - Realtime subscriptions for live updates
class SupabaseCommentRepository implements CommentRepository {
  SupabaseCommentRepository(this._client);

  final SupabaseClient _client;

  final Map<String, StreamController<List<Comment>>> _controllers = {};
  final Map<String, RealtimeChannel> _channels = {};
  final Set<String> _likedCommentIds = {};

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Stream<List<Comment>> watchComments(String postId) {
    if (!_controllers.containsKey(postId)) {
      _controllers[postId] = StreamController<List<Comment>>.broadcast(
        onListen: () => _subscribeToComments(postId),
        onCancel: () => _unsubscribeFromComments(postId),
      );
      // Initial load
      getComments(postId).then((comments) {
        if (_controllers[postId]?.hasListener ?? false) {
          _controllers[postId]!.add(comments);
        }
      });
    }
    return _controllers[postId]!.stream;
  }

  void _subscribeToComments(String postId) {
    _channels[postId] = _client
        .channel('comments:$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (payload) async {
            final comments = await getComments(postId);
            _controllers[postId]?.add(comments);
          },
        )
        .subscribe();
  }

  void _unsubscribeFromComments(String postId) {
    _channels[postId]?.unsubscribe();
    _channels.remove(postId);
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    final rows = await _client
        .from('post_comments')
        .select('''
          id,
          post_id,
          author_id,
          body,
          parent_comment_id,
          created_at,
          updated_at,
          profiles!inner(full_name, handle, avatar_url)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (rows as List).map((row) => _commentFromRow(row)).toList();
  }

  @override
  Future<Comment> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    final row = await _client.from('post_comments').insert({
      'post_id': postId,
      'author_id': userId,
      'body': body,
      'parent_comment_id': parentCommentId,
    }).select('''
      id,
      post_id,
      author_id,
      body,
      parent_comment_id,
      created_at,
      updated_at,
      profiles!inner(full_name, handle, avatar_url)
    ''').single();

    return _commentFromRow(row);
  }

  @override
  Future<Comment> editComment({
    required String commentId,
    required String body,
  }) async {
    final row = await _client
        .from('post_comments')
        .update({'body': body})
        .eq('id', commentId)
        .select('''
          id,
          post_id,
          author_id,
          body,
          parent_comment_id,
          created_at,
          updated_at,
          profiles!inner(full_name, handle, avatar_url)
        ''')
        .single();

    return _commentFromRow(row);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _client.from('post_comments').delete().eq('id', commentId);
  }

  @override
  Future<bool> toggleLike(String commentId) async {
    // Note: Comment likes table not in current schema
    // This is a client-side mock until comment_likes table is added
    if (_likedCommentIds.contains(commentId)) {
      _likedCommentIds.remove(commentId);
      return false;
    } else {
      _likedCommentIds.add(commentId);
      return true;
    }
  }

  Comment _commentFromRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    return Comment(
      id: row['id'] as String,
      postId: row['post_id'] as String,
      authorId: row['author_id'] as String,
      authorName: profile?['full_name'] as String? ?? '',
      authorHandle: profile?['handle'] as String? ?? '',
      authorAvatarUrl: profile?['avatar_url'] as String?,
      body: row['body'] as String,
      parentCommentId: row['parent_comment_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _channels.clear();
    _controllers.clear();
  }
}
