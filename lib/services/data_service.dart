import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostSnapshot {
  PostSnapshot({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    this.tags = const <String>[],
  });

  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
        'author': author,
        'handle': handle,
        'timeAgo': timeAgo,
        'body': body,
        'tags': tags,
      };

  factory PostSnapshot.fromJson(Map<String, dynamic> json) => PostSnapshot(
        author: json['author'] as String,
        handle: json['handle'] as String,
        timeAgo: json['timeAgo'] as String,
        body: json['body'] as String,
        tags: (json['tags'] as List?)?.cast<String>() ?? const <String>[],
      );
}

class PostModel {
  PostModel({
    required this.id,
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.body,
    this.tags = const <String>[],
    this.replies = 0,
    this.reposts = 0,
    this.likes = 0,
    this.views = 0,
    this.bookmarks = 0,
    this.quoted,
    this.repostedBy,
    this.originalId,
  });

  final String id;
  final String author;
  final String handle;
  final String timeAgo;
  final String body;
  final List<String> tags;
  final int replies;
  final int reposts;
  final int likes;
  final int views;
  final int bookmarks;
  final PostSnapshot? quoted;
  final String? repostedBy;
  final String? originalId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'handle': handle,
        'timeAgo': timeAgo,
        'body': body,
        'tags': tags,
        'replies': replies,
        'reposts': reposts,
        'likes': likes,
        'views': views,
        'bookmarks': bookmarks,
        'quoted': quoted?.toJson(),
        'repostedBy': repostedBy,
        'originalId': originalId,
      };

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String,
        author: json['author'] as String,
        handle: json['handle'] as String,
        timeAgo: json['timeAgo'] as String,
        body: json['body'] as String,
        tags: (json['tags'] as List?)?.cast<String>() ?? const <String>[],
        replies: (json['replies'] as num?)?.toInt() ?? 0,
        reposts: (json['reposts'] as num?)?.toInt() ?? 0,
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        views: (json['views'] as num?)?.toInt() ?? 0,
        bookmarks: (json['bookmarks'] as num?)?.toInt() ?? 0,
        quoted: json['quoted'] != null ? PostSnapshot.fromJson(json['quoted'] as Map<String, dynamic>) : null,
        repostedBy: json['repostedBy'] as String?,
        originalId: json['originalId'] as String?,
      );

  PostModel copyWith({
    String? id,
    String? author,
    String? handle,
    String? timeAgo,
    String? body,
    List<String>? tags,
    int? replies,
    int? reposts,
    int? likes,
    int? views,
    int? bookmarks,
    PostSnapshot? quoted,
    String? repostedBy,
    String? originalId,
  }) =>
      PostModel(
        id: id ?? this.id,
        author: author ?? this.author,
        handle: handle ?? this.handle,
        timeAgo: timeAgo ?? this.timeAgo,
        body: body ?? this.body,
        tags: tags ?? this.tags,
        replies: replies ?? this.replies,
        reposts: reposts ?? this.reposts,
        likes: likes ?? this.likes,
        views: views ?? this.views,
        bookmarks: bookmarks ?? this.bookmarks,
        quoted: quoted ?? this.quoted,
        repostedBy: repostedBy ?? this.repostedBy,
        originalId: originalId ?? this.originalId,
      );
}

class DataService extends ChangeNotifier {
  static const _storageKey = 'feed_posts';
  final Random _random = Random();

  final List<PostModel> _posts = <PostModel>[];
  List<PostModel> get posts => List.unmodifiable(_posts);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _posts
        ..clear()
        ..addAll(list.map(PostModel.fromJson));
      notifyListeners();
      return;
    }

    // Seed demo data if none persisted yet
    _seedDemoData();
    await _save();
  }

  Future<void> clearAll() async {
    _posts.clear();
    await _save();
    notifyListeners();
  }

  Future<void> addPost({
    required String author,
    required String handle,
    required String body,
    List<String> tags = const <String>[],
  }) async {
    final post = PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: author,
      handle: handle,
      timeAgo: 'just now',
      body: body,
      tags: tags,
      views: 120 + _random.nextInt(880),
      repostedBy: null,
      originalId: null,
    );
    _posts.insert(0, post);
    await _save();
    notifyListeners();
  }

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
    notifyListeners();
  }

  bool hasUserRetweeted(String postId, String userHandle) {
    final targetId = postId;
    return _posts.any((post) => post.originalId == targetId && post.repostedBy == userHandle);
  }

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
      final originIdx = _posts.indexWhere((post) => post.id == existing.originalId);
      if (originIdx != -1) {
        final origin = _posts[originIdx];
        final updated = origin.copyWith(reposts: (origin.reposts - 1).clamp(0, 1 << 30));
        _posts[originIdx] = updated;
      }
      await _save();
      notifyListeners();
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
    notifyListeners();
    return true;
  }

  void _seedDemoData() {

_posts.addAll([
  PostModel(
    id: 'seed_1',
    author: 'Charge Nurse Halima Yusuf',
    handle: '@nightshift_ng',
    timeAgo: '2h',
    body:
        'Updated crash trolley checklist posted in the sterile room. Please cross-check oxygen cylinders before change of shift and log all controlled drugs immediately after rounds.',
    tags: const ['Emergency Care', 'Ward Protocols'],
    replies: 73,
    reposts: 45,
    likes: 654,
    views: 28200,
    bookmarks: 57,
    repostedBy: null,
    originalId: null,
  ),
  PostModel(
    id: 'seed_2',
    author: 'NMCN Exam Desk',
    handle: '@nmcn_official',
    timeAgo: '5h',
    body:
        'Clinical skills reminder: practise aseptic wound dressing, medication reconciliation, and neonatal resuscitation steps ahead of next week’s OSCE review.',
    tags: const ['NMCN Key Points', 'Skills Lab'],
    replies: 112,
    reposts: 58,
    likes: 1042,
    views: 41200,
    bookmarks: 188,
    repostedBy: null,
    originalId: null,
  ),
  PostModel(
    id: 'seed_3',
    author: 'Public Health Cohort',
    handle: '@community_rounds',
    timeAgo: '1d',
    body:
        'Field posting briefing: focus on hypertension screening, maternal health counselling, and cold-chain audits. Upload daily tallies before 6 p.m.',
    tags: const ['Public Health', 'Community Posting'],
    replies: 34,
    reposts: 19,
    likes: 304,
    views: 16300,
    bookmarks: 51,
    repostedBy: null,
    originalId: null,
  ),
]);

  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_posts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
