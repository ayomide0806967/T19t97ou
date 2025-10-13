import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/thread_entry.dart';

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
    quoted: json['quoted'] != null
        ? PostSnapshot.fromJson(json['quoted'] as Map<String, dynamic>)
        : null,
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
  }) => PostModel(
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
    return _posts.any(
      (post) => post.originalId == targetId && post.repostedBy == userHandle,
    );
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

  ThreadEntry buildThreadForPost(String postId) {
    final root = _posts.firstWhere(
      (post) => post.id == postId,
      orElse: () => _posts.isNotEmpty ? _posts.first : _demoFallbackPost(),
    );
    return ThreadEntry(post: root, replies: _mockRepliesFor(root));
  }

  List<ThreadEntry> _mockRepliesFor(PostModel root) {
    final int seed = root.id.hashCode.abs();
    PostModel reply({
      required String idSuffix,
      required String author,
      required String handle,
      required String body,
      String timeAgo = '1h',
      int replies = 0,
      int likes = 0,
      int reposts = 0,
      int bookmarks = 0,
      PostSnapshot? quoted,
      String? repostedBy,
      String? originalId,
      List<String> tags = const <String>[],
    }) {
      return root.copyWith(
        id: '${root.id}_$idSuffix',
        author: author,
        handle: handle,
        body: body,
        timeAgo: timeAgo,
        replies: replies,
        likes: likes,
        reposts: reposts,
        bookmarks: bookmarks,
        quoted: quoted,
        originalId: originalId,
        repostedBy: repostedBy,
        tags: tags,
        views: 140 + ((seed + idSuffix.hashCode) % 400),
      );
    }

    final ThreadEntry first = ThreadEntry(
      post: reply(
        idSuffix: 'r1',
        author: 'Clinical Coach Amaka',
        handle: '@coach_amaka',
        body:
            'Great update! We\'ll cascade this tonight so the surgical floor stays in sync.',
        timeAgo: '58m',
        replies: 3,
        likes: 24,
      ),
      replyToHandle: root.handle,
      replies: [
        ThreadEntry(
          post: reply(
            idSuffix: 'r1a',
            author: 'Resident Timi',
            handle: '@timi_resident',
            body:
                'Replying to ${root.handle}: thanks Coach! We just re-balanced the meds trolley, works like a charm.',
            timeAgo: '42m',
            likes: 11,
          ),
          replyToHandle: '@coach_amaka',
          replies: [
            ThreadEntry(
              post: reply(
                idSuffix: 'r1a1',
                author: 'Lab Liaison Kemi',
                handle: '@kemi_lab',
                body:
                    'Adding labs to this thread—set the reagent restock reminders for 6 p.m.',
                timeAgo: '25m',
                likes: 5,
                quoted: PostSnapshot(
                  author: root.author,
                  handle: root.handle,
                  timeAgo: root.timeAgo,
                  body: root.body.length > 120
                      ? '${root.body.substring(0, 120)}…'
                      : root.body,
                  tags: root.tags,
                ),
              ),
              replyToHandle: '@timi_resident',
            ),
          ],
        ),
      ],
    );

    final ThreadEntry second = ThreadEntry(
      post: reply(
        idSuffix: 'r2',
        author: 'Matron Funke',
        handle: '@matron_funke',
        body:
            'Re-in so the night matron sees this immediately. Please double-check emergency tray seals before handoff.',
        timeAgo: '50m',
        reposts: 1,
        likes: 38,
        repostedBy: '@matron_funke',
        originalId: root.id,
      ),
      replyToHandle: root.handle,
    );

    final ThreadEntry third = ThreadEntry(
      post: reply(
        idSuffix: 'r3',
        author: 'Nursing Cohort Year3',
        handle: '@year3_shift',
        body:
            'Noted! We\'ll pair this with our vitals observation checklist for quicker rounds.',
        timeAgo: '36m',
        likes: 17,
        replies: 2,
      ),
      replyToHandle: root.handle,
      replies: [
        ThreadEntry(
          post: reply(
            idSuffix: 'r3a',
            author: 'Student Sola',
            handle: '@sola_practice',
            body:
                'Replying to @year3_shift: can we pin this in the unit notice board?',
            timeAgo: '28m',
            likes: 4,
          ),
          replyToHandle: '@year3_shift',
        ),
        ThreadEntry(
          post: reply(
            idSuffix: 'r3b',
            author: 'OSCE Prep Team',
            handle: '@osce_ready',
            body:
                'Quote this into the OSCE channel so everyone resets the trolley layout.',
            timeAgo: '22m',
            likes: 9,
            quoted: PostSnapshot(
              author: 'Skills Lab Announcements',
              handle: '@skillslab',
              timeAgo: '1d',
              body:
                  'Remember to log simulation outcomes right after each station to avoid data loss.',
            ),
          ),
          replyToHandle: '@year3_shift',
        ),
      ],
    );

    return [first, second, third];
  }

  PostModel _demoFallbackPost() => PostModel(
    id: 'fallback_${DateTime.now().microsecondsSinceEpoch}',
    author: 'Community Lead',
    handle: '@campus_updates',
    timeAgo: 'just now',
    body: 'Thread preview unavailable.',
  );

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_posts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
