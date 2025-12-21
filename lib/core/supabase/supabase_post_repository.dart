import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/feed/post_repository.dart';
import '../../core/utils/time_ago.dart';
import '../../models/post.dart';
import '../../models/thread_entry.dart';

class SupabasePostRepository extends ChangeNotifier implements PostRepository {
  SupabasePostRepository(this._client);

  final SupabaseClient _client;

  final List<PostModel> _posts = <PostModel>[];

  @override
  List<PostModel> get posts => List.unmodifiable(_posts);

  @override
  List<PostModel> get timelinePosts => List<PostModel>.from(_posts);

  @override
  Future<void> load() async {
    final rows = await _client
        .from('feed_posts')
        .select()
        .order('created_at', ascending: false);

    final next = <PostModel>[];
    for (final row in rows as List<dynamic>) {
      if (row is! Map<String, dynamic>) continue;
      next.add(_fromFeedRow(row));
    }
    _posts
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  @override
  Future<void> clearAll() async {
    throw UnimplementedError('clearAll is not supported for Supabase feed.');
  }

  @override
  Future<void> addPost({
    required String author,
    required String handle,
    required String body,
    List<String> tags = const <String>[],
    List<String> mediaPaths = const <String>[],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    await _client.from('posts').insert({
      'author_id': userId,
      'body': body,
      'tags': tags,
      'media_paths': mediaPaths,
    });
    await load();
  }

  @override
  Future<void> addQuote({
    required String author,
    required String handle,
    required String comment,
    required PostSnapshot original,
    List<String> tags = const <String>[],
  }) async {
    throw UnimplementedError('Quote posts are not wired to Supabase yet.');
  }

  @override
  bool hasUserReposted(String postId, String userHandle) {
    // Prefer the async path for correctness; keep sync API conservative.
    return false;
  }

  @override
  Future<bool> toggleRepost({
    required String postId,
    required String userHandle,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }

    final existing = await _client
        .from('post_reposts')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('post_reposts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      await load();
      return false;
    }

    await _client.from('post_reposts').insert({
      'post_id': postId,
      'user_id': userId,
    });
    await load();
    return true;
  }

  @override
  ThreadEntry buildThreadForPost(String postId) {
    final root = _posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => PostModel(
        id: postId,
        author: 'Unknown',
        handle: '@unknown',
        timeAgo: 'just now',
        body: '',
      ),
    );
    return ThreadEntry(post: root, replies: const <ThreadEntry>[]);
  }

  @override
  List<PostModel> postsForHandle(String handle) {
    final normalized = handle.toLowerCase();
    return _posts
        .where((p) => p.handle.toLowerCase() == normalized)
        .toList();
  }

  @override
  List<PostModel> postsForHandles(Set<String> handles) {
    final lower = handles.map((h) => h.toLowerCase()).toSet();
    return _posts
        .where((p) => lower.contains(p.handle.toLowerCase()))
        .toList();
  }

  @override
  List<PostModel> repliesForHandle(String handle, {int minLikes = 0}) {
    return const <PostModel>[];
  }

  PostModel _fromFeedRow(Map<String, dynamic> row) {
    final createdAt = row['created_at'];
    final DateTime ts = createdAt is String
        ? DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final tags = (row['tags'] as List?)?.cast<String>() ?? const <String>[];
    final media =
        (row['media_paths'] as List?)?.cast<String>() ?? const <String>[];

    return PostModel(
      id: (row['id'] ?? '').toString(),
      author: (row['author'] ?? 'Unknown').toString(),
      handle: (row['handle'] ?? '@unknown').toString(),
      timeAgo: formatTimeAgo(ts),
      body: (row['body'] ?? '').toString(),
      tags: tags,
      mediaPaths: media,
      replies: (row['replies'] as num?)?.toInt() ?? 0,
      reposts: (row['reposts'] as num?)?.toInt() ?? 0,
      likes: (row['likes'] as num?)?.toInt() ?? 0,
      views: (row['views'] as num?)?.toInt() ?? 0,
      bookmarks: (row['bookmarks'] as num?)?.toInt() ?? 0,
      repostedBy: row['reposted_by'] as String?,
      originalId: row['original_id'] as String?,
    );
  }
}

