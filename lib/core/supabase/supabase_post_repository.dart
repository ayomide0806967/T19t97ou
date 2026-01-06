import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/feed/domain/post_repository.dart';
import '../../core/utils/time_ago.dart';
import '../../models/post.dart';
import '../../models/thread_entry.dart';

class SupabasePostRepository implements PostRepository {
  SupabasePostRepository(this._client);

  final SupabaseClient _client;

  final List<PostModel> _posts = <PostModel>[];
  final StreamController<List<PostModel>> _timelineController =
      StreamController<List<PostModel>>.broadcast();

  RealtimeChannel? _feedChannel;
  bool _realtimeSubscribed = false;
  Timer? _realtimeReloadTimer;
  bool _realtimeReloadInFlight = false;
  
  // Cache post interaction states for current user
  final Set<String> _likedPostIds = <String>{};
  final Set<String> _bookmarkedPostIds = <String>{};
  final Set<String> _repostedPostIds = <String>{};

  /// Update cached avatar URLs for all posts authored by [handle] and re-emit the timeline.
  /// This avoids a full network reload after a profile avatar update.
  void updateAvatarUrlForHandle(String handle, String? avatarUrl) {
    final normalized = _normalizeHandle(handle);
    bool changed = false;
    for (var i = 0; i < _posts.length; i++) {
      final post = _posts[i];
      if (_normalizeHandle(post.handle) != normalized) continue;
      if (post.avatarUrl == avatarUrl) continue;
      _posts[i] = post.copyWith(avatarUrl: avatarUrl);
      changed = true;
    }
    if (changed) _emitTimeline();
  }

  String _normalizeHandle(String handle) {
    final trimmed = handle.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  @override
  List<PostModel> get posts => List.unmodifiable(_posts);

  @override
  List<PostModel> get timelinePosts => List<PostModel>.from(_posts);

  @override
  Stream<List<PostModel>> watchTimeline() => _timelineController.stream;

  @override
  Stream<ThreadEntry> watchThread(String postId) {
    return _timelineController.stream.map(
      (_) => buildThreadForPost(postId),
    );
  }

  @override
  Stream<List<PostModel>> watchUserTimeline(String handle) {
    final normalized = handle.trim();
    if (normalized.isEmpty) {
      return _timelineController.stream
          .map((_) => const <PostModel>[]);
    }
    return _timelineController.stream.map(
      (_) => postsForHandle(normalized),
    );
  }

  @override
  Future<void> load() async {
    // Load from feed_posts_view for denormalized data
    final rows = await _client
        .from('feed_posts_view')
        .select()
        .order('created_at', ascending: false)
        .limit(100);

    final next = <PostModel>[];
    for (final row in rows as List<dynamic>) {
      if (row is! Map<String, dynamic>) continue;
      next.add(_fromFeedRow(row));
    }
    _posts
      ..clear()
      ..addAll(next);
    
    // Load user's interaction states
    await _loadUserInteractions();

    // Ensure bookmarked posts are present in the local cache so the
    // bookmarks screen can show "all saved posts" even if they're not
    // in the latest timeline slice.
    await _loadMissingBookmarkedPosts();
    
    _emitTimeline();
    
    // Subscribe to realtime changes
    _subscribeToFeed();
  }

  Future<void> _loadUserInteractions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Load liked posts
    final likes = await _client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', userId);
    _likedPostIds.clear();
    for (final row in likes as List) {
      _likedPostIds.add(row['post_id'] as String);
    }

    // Load bookmarked posts
    final bookmarks = await _client
        .from('post_bookmarks')
        .select('post_id')
        .eq('user_id', userId);
    _bookmarkedPostIds.clear();
    for (final row in bookmarks as List) {
      _bookmarkedPostIds.add(row['post_id'] as String);
    }

    // Load reposted posts
    final reposts = await _client
        .from('post_reposts')
        .select('post_id')
        .eq('user_id', userId);
    _repostedPostIds.clear();
    for (final row in reposts as List) {
      _repostedPostIds.add(row['post_id'] as String);
    }
  }

  Future<void> _loadMissingBookmarkedPosts() async {
    if (_bookmarkedPostIds.isEmpty) return;
    final existingIds = _posts.map((p) => p.id).toSet();
    final missing = _bookmarkedPostIds.difference(existingIds).toList();
    if (missing.isEmpty) return;

    final rows = await _client
        .from('feed_posts_view')
        .select()
        .inFilter('id', missing)
        .order('created_at', ascending: false);

    final missingPosts = <PostModel>[];
    for (final row in rows as List<dynamic>) {
      if (row is! Map<String, dynamic>) continue;
      missingPosts.add(_fromFeedRow(row));
    }
    if (missingPosts.isEmpty) return;
    _posts.addAll(missingPosts);
  }

  void _subscribeToFeed() {
    if (_realtimeSubscribed) return;
    _realtimeSubscribed = true;

    void requestReload() {
      _realtimeReloadTimer?.cancel();
      _realtimeReloadTimer = Timer(const Duration(milliseconds: 250), () async {
        if (_realtimeReloadInFlight) return;
        _realtimeReloadInFlight = true;
        try {
          await load();
        } finally {
          _realtimeReloadInFlight = false;
        }
      });
    }

    _feedChannel = _client
        .channel('feed:posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'posts',
          callback: (_) => requestReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_likes',
          callback: (_) => requestReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_reposts',
          callback: (_) => requestReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_comments',
          callback: (_) => requestReload(),
        )
        .subscribe();
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

    // Insert post
    final postResult = await _client.from('posts').insert({
      'author_id': userId,
      'body': body,
      'tags': tags,
      'visibility': 'public',
    }).select('id').single();

    final postId = postResult['id'] as String;

    // Insert media if any
    if (mediaPaths.isNotEmpty) {
      final mediaRows = mediaPaths.asMap().entries.map((entry) => {
            'post_id': postId,
            'media_url': entry.value,
            'media_type': _inferMediaType(entry.value),
            'order_index': entry.key,
          });
      await _client.from('post_media').insert(mediaRows.toList());
    }

    await load();
  }

  String _inferMediaType(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.gif')) return 'gif';
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) return 'video';
    return 'image';
  }

  @override
  Future<void> addQuote({
    required String author,
    required String handle,
    required String comment,
    required PostSnapshot original,
    List<String> tags = const <String>[],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not signed in');
    }

    // Find the original post ID
    final originalPost = _posts.firstWhere(
      (p) => p.body == original.body && p.handle == original.handle,
      orElse: () => PostModel(
        id: '',
        author: original.author,
        handle: original.handle,
        timeAgo: original.timeAgo,
        body: original.body,
      ),
    );

    await _client.from('posts').insert({
      'author_id': userId,
      'body': comment,
      'tags': tags,
      'quote_id': originalPost.id.isNotEmpty ? originalPost.id : null,
      'visibility': 'public',
    });
    await load();
  }

  @override
  Future<void> deletePost({required String postId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('posts').delete().eq('id', postId).eq('author_id', userId);

    _posts.removeWhere((p) => p.id == postId);
    _likedPostIds.remove(postId);
    _bookmarkedPostIds.remove(postId);
    _repostedPostIds.remove(postId);
    _emitTimeline();
  }

  // ============================================================================
  // Likes functionality
  // ============================================================================

  /// Check if current user has liked a post.
  bool hasUserLiked(String postId) => _likedPostIds.contains(postId);

  /// Toggle like on a post. Returns true if now liked, false if unliked.
  Future<bool> toggleLike(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    if (_likedPostIds.contains(postId)) {
      // Unlike
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      _likedPostIds.remove(postId);
      _updatePostLikeCount(postId, -1);
      _emitTimeline();
      return false;
    } else {
      // Like
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
      _likedPostIds.add(postId);
      _updatePostLikeCount(postId, 1);
      _emitTimeline();
      return true;
    }
  }

  void _updatePostLikeCount(String postId, int delta) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(likes: (post.likes + delta).clamp(0, 999999));
    }
  }

  // ============================================================================
  // Bookmarks functionality
  // ============================================================================

  /// Check if current user has bookmarked a post.
  @override
  bool hasUserBookmarked(String postId) => _bookmarkedPostIds.contains(postId);

  /// Toggle bookmark on a post. Returns true if now bookmarked.
  @override
  Future<bool> toggleBookmark(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    if (_bookmarkedPostIds.contains(postId)) {
      // Remove bookmark
      await _client
          .from('post_bookmarks')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      _bookmarkedPostIds.remove(postId);
      _updatePostBookmarkCount(postId, -1);
      _emitTimeline();
      return false;
    } else {
      // Add bookmark
      await _client.from('post_bookmarks').insert({
        'post_id': postId,
        'user_id': userId,
      });
      _bookmarkedPostIds.add(postId);
      _updatePostBookmarkCount(postId, 1);
      _emitTimeline();
      return true;
    }
  }

  void _updatePostBookmarkCount(String postId, int delta) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(bookmarks: (post.bookmarks + delta).clamp(0, 999999));
    }
  }

  // ============================================================================
  // Reposts functionality
  // ============================================================================

  @override
  bool hasUserReposted(String postId, String userHandle) {
    return _repostedPostIds.contains(postId);
  }

  @override
  List<PostModel> bookmarkedPosts() {
    if (_bookmarkedPostIds.isEmpty) return const <PostModel>[];
    return _posts
        .where((post) => _bookmarkedPostIds.contains(post.id))
        .toList(growable: false);
  }

  @override
  Future<bool> toggleRepost({
    required String postId,
    required String userHandle,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    if (_repostedPostIds.contains(postId)) {
      // Remove repost
      await _client
          .from('post_reposts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      _repostedPostIds.remove(postId);
      _updatePostRepostCount(postId, -1);
      _emitTimeline();
      return false;
    } else {
      // Add repost
      await _client.from('post_reposts').insert({
        'post_id': postId,
        'user_id': userId,
      });
      _repostedPostIds.add(postId);
      _updatePostRepostCount(postId, 1);
      _emitTimeline();
      return true;
    }
  }

  void _updatePostRepostCount(String postId, int delta) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(reposts: (post.reposts + delta).clamp(0, 999999));
    }
  }

  // ============================================================================
  // Thread and user posts
  // ============================================================================

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
    
    // Find replies to this post
    final replies = _posts
        .where((p) => p.originalId == postId)  // reply_to_id mapped to originalId
        .map((p) => ThreadEntry(post: p, replies: const <ThreadEntry>[]))
        .toList();
    
    return ThreadEntry(post: root, replies: replies);
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
    final normalized = handle.toLowerCase();
    return _posts
        .where((p) => 
            p.handle.toLowerCase() == normalized && 
            p.originalId != null &&
            p.likes >= minLikes)
        .toList();
  }

  // ============================================================================
  // Helpers
  // ============================================================================

  void _emitTimeline() {
    if (_timelineController.hasListener && !_timelineController.isClosed) {
      _timelineController.add(List<PostModel>.from(_posts));
    }
  }

  PostModel _fromFeedRow(Map<String, dynamic> row) {
    final createdAt = row['created_at'];
    final DateTime ts = createdAt is String
        ? DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final tags = (row['tags'] as List?)?.cast<String>() ?? const <String>[];
    final media = (row['media_urls'] as List?)?.cast<String>() ?? const <String>[];

    // Parse quoted post if present
    PostSnapshot? quoted;
    if (row['quoted_post'] != null && row['quoted_post'] is Map) {
      final q = row['quoted_post'] as Map<String, dynamic>;
      quoted = PostSnapshot(
        author: q['author'] as String? ?? 'Unknown',
        handle: q['handle'] as String? ?? '@unknown',
        timeAgo: q['created_at'] != null 
            ? formatTimeAgo(DateTime.tryParse(q['created_at'] as String)?.toLocal() ?? DateTime.now())
            : 'some time ago',
        body: q['body'] as String? ?? '',
      );
    }

    return PostModel(
      id: (row['id'] ?? '').toString(),
      author: (row['author'] ?? 'Unknown').toString(),
      handle: (row['handle'] ?? '@unknown').toString(),
      avatarUrl: row['avatar_url'] as String?,
      timeAgo: formatTimeAgo(ts),
      body: (row['body'] ?? '').toString(),
      tags: tags,
      mediaPaths: media,
      replies: (row['reply_count'] as num?)?.toInt() ?? 0,
      reposts: (row['repost_count'] as num?)?.toInt() ?? 0,
      likes: (row['like_count'] as num?)?.toInt() ?? 0,
      views: 0, // Views not tracked in current schema
      bookmarks: (row['bookmark_count'] as num?)?.toInt() ?? 0,
      quoted: quoted,
      repostedBy: row['reposted_by'] as String?,
      originalId: row['reply_to_id'] as String?,
    );
  }

  void dispose() {
    _feedChannel?.unsubscribe();
    _timelineController.close();
  }
}
