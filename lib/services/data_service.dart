import 'dart:convert';

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
      );
}

class DataService extends ChangeNotifier {
  static const _storageKey = 'feed_posts';

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
    );
    _posts.insert(0, post);
    await _save();
    notifyListeners();
  }

  void _seedDemoData() {
    _posts.addAll([
      PostModel(
        id: 'seed_1',
        author: 'Dr. Maya Chen',
        handle: '@dean_creative',
        timeAgo: '2h',
        body:
            'Excited to announce the new Innovation Studio. A collaborative environment designed for prototyping, creative coding, and rapid experimentation.',
        tags: const ['Innovation', 'Design Labs'],
        replies: 91,
        reposts: 51,
        likes: 968,
        views: 46100,
        bookmarks: 18,
      ),
      PostModel(
        id: 'seed_2',
        author: 'Student Affairs',
        handle: '@life_at_in',
        timeAgo: '4h',
        body:
            'This Friday we host our minimalist mixer on the West Terrace. Expect acoustic sets, local roasters, and plenty of space to breathe.',
        tags: const ['Events', 'Community'],
        replies: 42,
        reposts: 27,
        likes: 312,
        views: 18600,
        bookmarks: 23,
      ),
      PostModel(
        id: 'seed_3',
        author: 'Research Collective',
        handle: '@insights',
        timeAgo: '1d',
        body:
            'We just published our annual state of campus innovation report. Streamlined briefs, interactive prototypes, and open data sets are available now.',
        tags: const ['Research', 'Open Data'],
        replies: 58,
        reposts: 36,
        likes: 742,
        views: 32900,
        bookmarks: 41,
      ),
    ]);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_posts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}