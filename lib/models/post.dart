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
    this.mediaPaths = const <String>[],
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
  final List<String> mediaPaths;
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
        'mediaPaths': mediaPaths,
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
        mediaPaths:
            (json['mediaPaths'] as List?)?.cast<String>() ?? const <String>[],
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
    List<String>? mediaPaths,
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
        mediaPaths: mediaPaths ?? this.mediaPaths,
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

