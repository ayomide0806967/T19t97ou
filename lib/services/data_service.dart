import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/thread_entry.dart';
import '../models/post.dart';
import '../features/feed/domain/post_repository.dart';

class DataService implements PostRepository {
  static const _storageKey = 'feed_posts';
  static const _bookmarksStorageKey = 'feed_bookmarks';
  static const _likesStorageKey = 'feed_likes';
  final Random _random = Random();

  final List<PostModel> _posts = <PostModel>[];
  final Set<String> _bookmarkedPostIds = <String>{};
  final Set<String> _likedPostIds = <String>{};
  final StreamController<List<PostModel>> _timelineController =
      StreamController<List<PostModel>>.broadcast();

  @override
  List<PostModel> get posts => List.unmodifiable(_posts);

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    final rawBookmarks = prefs.getStringList(_bookmarksStorageKey);
    final rawLikes = prefs.getStringList(_likesStorageKey);
    _bookmarkedPostIds
      ..clear()
      ..addAll(rawBookmarks ?? const <String>[]);
    _likedPostIds
      ..clear()
      ..addAll(rawLikes ?? const <String>[]);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _posts
        ..clear()
        ..addAll(list.map(PostModel.fromJson));
      _emitTimeline();
      return;
    }

    // No demo seeding: start with an empty timeline.
    _posts
      ..clear();
    await _save();
  }

  @override
  Future<void> clearAll() async {
    _posts.clear();
    _bookmarkedPostIds.clear();
    _likedPostIds.clear();
    await _save();
  }

  @override
  Stream<List<PostModel>> watchTimeline() => _timelineController.stream;

  @override
  Stream<ThreadEntry> watchThread(String postId) {
    // For the in-memory demo implementation, derive the thread from the
    // current posts whenever the timeline emits.
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
  Future<void> addPost({
    required String author,
    required String handle,
    required String body,
    List<String> tags = const <String>[],
    List<String> mediaPaths = const <String>[],
  }) async {
    final post = PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: author,
      handle: handle,
      timeAgo: 'just now',
      body: body,
      tags: tags,
      mediaPaths: mediaPaths,
      views: 120 + _random.nextInt(880),
      repostedBy: null,
      originalId: null,
    );
    _posts.insert(0, post);
    await _save();
  }

  @override
  Future<void> addQuote({
    required String author,
    required String handle,
    required String comment,
    required PostSnapshot original,
    List<String> tags = const <String>[],
  }) async {
    final post = PostModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      author: author,
      handle: handle,
      timeAgo: 'just now',
      body: comment,
      tags: tags,
      quoted: original,
      views: 75 + _random.nextInt(650),
      repostedBy: null,
      originalId: null,
    );
    _posts.insert(0, post);
    await _save();
  }

  @override
  Future<void> deletePost({required String postId}) async {
    final beforeCount = _posts.length;
    _posts.removeWhere((post) => post.id == postId);
    if (_posts.length == beforeCount) return;
    await _save();
  }

  bool hasUserRetweeted(String postId, String userHandle) =>
      hasUserReposted(postId, userHandle);

  @override
  bool hasUserReposted(String postId, String userHandle) {
    final targetId = postId;
    return _posts.any(
      (post) => post.originalId == targetId && post.repostedBy == userHandle,
    );
  }

  // =========================================================================
  // Like operations
  // =========================================================================

  @override
  bool hasUserLiked(String postId) => _likedPostIds.contains(postId);

  @override
  Future<bool> toggleLike(String postId) async {
    final bool nowLiked;
    if (_likedPostIds.contains(postId)) {
      _likedPostIds.remove(postId);
      _updateLikeCount(postId, -1);
      nowLiked = false;
    } else {
      _likedPostIds.add(postId);
      _updateLikeCount(postId, 1);
      nowLiked = true;
    }
    await _save();
    return nowLiked;
  }

  void _updateLikeCount(String postId, int delta) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    _posts[index] = post.copyWith(likes: (post.likes + delta).clamp(0, 999999));
  }

  @override
  Future<bool> toggleRepost({
    required String postId,
    required String userHandle,
  }) async {
    final originalIndex = _posts.indexWhere((post) => post.id == postId);
    if (originalIndex == -1) {
      return false;
    }

    final existingIndex = _posts.indexWhere(
      (post) => post.originalId == postId && post.repostedBy == userHandle,
    );

    if (existingIndex != -1) {
      final existing = _posts.removeAt(existingIndex);
      final originIdx = _posts.indexWhere(
        (post) => post.id == existing.originalId,
      );
      if (originIdx != -1) {
        final origin = _posts[originIdx];
        final updated = origin.copyWith(
          reposts: (origin.reposts - 1).clamp(0, 1 << 30),
        );
        _posts[originIdx] = updated;
      }
      await _save();
      return false;
    }

    final original = _posts[originalIndex];
    final retweet = original.copyWith(
      id: 'rt_${DateTime.now().microsecondsSinceEpoch}',
      timeAgo: 'just now',
      repostedBy: userHandle,
      originalId: postId,
    );

    _posts[originalIndex] = original.copyWith(reposts: original.reposts + 1);
    _posts.insert(0, retweet);
    await _save();
    return true;
  }

  @override
  ThreadEntry buildThreadForPost(String postId) {
    final root = _posts.firstWhere(
      (post) => post.id == postId,
      orElse: () => _posts.isNotEmpty ? _posts.first : _demoFallbackPost(),
    );
    return ThreadEntry(post: root, replies: _mockRepliesFor(root));
  }

  List<ThreadEntry> _mockRepliesFor(PostModel root) =>
      const <ThreadEntry>[];

  PostModel _demoFallbackPost() => PostModel(
        id: 'fallback_${DateTime.now().microsecondsSinceEpoch}',
        author: '',
        handle: '',
        timeAgo: '',
        body: '',
      );

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_posts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
    await prefs.setStringList(_bookmarksStorageKey, _bookmarkedPostIds.toList());
    await prefs.setStringList(_likesStorageKey, _likedPostIds.toList());
    _emitTimeline();
  }

  // Global timeline rules:
  @override
  List<PostModel> get timelinePosts {
    // Show all posts in reverse chronological order (newest first).
    return List<PostModel>.from(_posts);
  }

  void _emitTimeline() {
    if (_timelineController.hasListener && !_timelineController.isClosed) {
      _timelineController.add(List<PostModel>.from(_posts));
    }
  }

  @override
  List<PostModel> postsForHandle(String handle) => _posts
      .where((post) => post.handle == handle || post.repostedBy == handle)
      .toList();

  @override
  List<PostModel> postsForHandles(Set<String> handles) {
    if (handles.isEmpty) return const <PostModel>[];
    final lower = handles.map((h) => h.toLowerCase()).toSet();
    return _posts
        .where(
          (post) => lower.contains(post.handle.toLowerCase()) ||
              (post.repostedBy != null &&
                  lower.contains(post.repostedBy!.toLowerCase())),
        )
        .toList();
  }

  @override
  List<PostModel> repliesForHandle(String handle, {int minLikes = 0}) {
    final lowerHandle = handle.toLowerCase();
    final Set<String> seen = <String>{};
    final List<PostModel> matches = <PostModel>[];

    void collectReplies(List<ThreadEntry> entries) {
      for (final ThreadEntry entry in entries) {
        final post = entry.post;
        if (post.handle.toLowerCase() == lowerHandle &&
            post.likes >= minLikes &&
            seen.add(post.id)) {
          matches.add(post);
        }
        if (entry.replies.isNotEmpty) {
          collectReplies(entry.replies);
        }
      }
    }

    for (final PostModel root in _posts) {
      collectReplies(_mockRepliesFor(root));
    }

    matches.sort((a, b) => b.likes.compareTo(a.likes));
    return matches;
  }

  @override
  bool hasUserBookmarked(String postId) => _bookmarkedPostIds.contains(postId);

  @override
  Future<bool> toggleBookmark(String postId) async {
    final bool nowBookmarked;
    if (_bookmarkedPostIds.contains(postId)) {
      _bookmarkedPostIds.remove(postId);
      _updateBookmarkCount(postId, -1);
      nowBookmarked = false;
    } else {
      _bookmarkedPostIds.add(postId);
      _updateBookmarkCount(postId, 1);
      nowBookmarked = true;
    }
    await _save();
    return nowBookmarked;
  }

  void _updateBookmarkCount(String postId, int delta) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    _posts[index] =
        post.copyWith(bookmarks: (post.bookmarks + delta).clamp(0, 999999));
  }

  @override
  List<PostModel> bookmarkedPosts() {
    if (_bookmarkedPostIds.isEmpty) return const <PostModel>[];
    return _posts
        .where((post) => _bookmarkedPostIds.contains(post.id))
        .toList(growable: false);
  }
}
