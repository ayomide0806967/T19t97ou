import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/models/post.dart';

void main() {
  group('PostSnapshot', () {
    test('fromJson creates correct instance', () {
      final json = {
        'author': 'Test Author',
        'handle': '@testhandle',
        'timeAgo': '2h',
        'body': 'Test body content',
        'tags': ['tag1', 'tag2'],
      };

      final snapshot = PostSnapshot.fromJson(json);

      expect(snapshot.author, 'Test Author');
      expect(snapshot.handle, '@testhandle');
      expect(snapshot.timeAgo, '2h');
      expect(snapshot.body, 'Test body content');
      expect(snapshot.tags, ['tag1', 'tag2']);
    });

    test('fromJson handles missing tags', () {
      final json = {
        'author': 'Test Author',
        'handle': '@testhandle',
        'timeAgo': '2h',
        'body': 'Test body content',
      };

      final snapshot = PostSnapshot.fromJson(json);

      expect(snapshot.tags, isEmpty);
    });

    test('toJson returns correct map', () {
      final snapshot = PostSnapshot(
        author: 'Test Author',
        handle: '@testhandle',
        timeAgo: '2h',
        body: 'Test body content',
        tags: ['tag1', 'tag2'],
      );

      final json = snapshot.toJson();

      expect(json['author'], 'Test Author');
      expect(json['handle'], '@testhandle');
      expect(json['timeAgo'], '2h');
      expect(json['body'], 'Test body content');
      expect(json['tags'], ['tag1', 'tag2']);
    });

    test('roundtrip serialization preserves data', () {
      final original = PostSnapshot(
        author: 'Test Author',
        handle: '@testhandle',
        timeAgo: '3h',
        body: 'Some body text',
        tags: ['nursing', 'education'],
      );

      final json = original.toJson();
      final restored = PostSnapshot.fromJson(json);

      expect(restored.author, original.author);
      expect(restored.handle, original.handle);
      expect(restored.timeAgo, original.timeAgo);
      expect(restored.body, original.body);
      expect(restored.tags, original.tags);
    });
  });

  group('PostModel', () {
    test('fromJson creates correct instance with all fields', () {
      final json = {
        'id': 'post_123',
        'author': 'Test Author',
        'handle': '@testhandle',
        'timeAgo': '1h',
        'body': 'This is a test post',
        'tags': ['tag1'],
        'mediaPaths': ['/path/to/image.jpg'],
        'replies': 5,
        'reposts': 10,
        'likes': 100,
        'views': 1000,
        'bookmarks': 25,
        'repostedBy': '@reposting_user',
        'originalId': 'original_post_id',
      };

      final post = PostModel.fromJson(json);

      expect(post.id, 'post_123');
      expect(post.author, 'Test Author');
      expect(post.handle, '@testhandle');
      expect(post.timeAgo, '1h');
      expect(post.body, 'This is a test post');
      expect(post.tags, ['tag1']);
      expect(post.mediaPaths, ['/path/to/image.jpg']);
      expect(post.replies, 5);
      expect(post.reposts, 10);
      expect(post.likes, 100);
      expect(post.views, 1000);
      expect(post.bookmarks, 25);
      expect(post.repostedBy, '@reposting_user');
      expect(post.originalId, 'original_post_id');
    });

    test('fromJson handles minimal required fields', () {
      final json = {
        'id': 'post_minimal',
        'author': 'Author',
        'handle': '@handle',
        'timeAgo': 'now',
        'body': 'Content',
      };

      final post = PostModel.fromJson(json);

      expect(post.id, 'post_minimal');
      expect(post.tags, isEmpty);
      expect(post.mediaPaths, isEmpty);
      expect(post.replies, 0);
      expect(post.reposts, 0);
      expect(post.likes, 0);
      expect(post.views, 0);
      expect(post.bookmarks, 0);
      expect(post.quoted, isNull);
      expect(post.repostedBy, isNull);
      expect(post.originalId, isNull);
    });

    test('fromJson handles quoted post', () {
      final json = {
        'id': 'post_with_quote',
        'author': 'Quoter',
        'handle': '@quoter',
        'timeAgo': '5m',
        'body': 'Check this out!',
        'quoted': {
          'author': 'Original Author',
          'handle': '@original',
          'timeAgo': '1d',
          'body': 'Original content',
          'tags': ['original'],
        },
      };

      final post = PostModel.fromJson(json);

      expect(post.quoted, isNotNull);
      expect(post.quoted!.author, 'Original Author');
      expect(post.quoted!.handle, '@original');
      expect(post.quoted!.body, 'Original content');
    });

    test('toJson returns correct map', () {
      final post = PostModel(
        id: 'test_id',
        author: 'Test Author',
        handle: '@test',
        timeAgo: '2h',
        body: 'Test content',
        tags: ['test'],
        likes: 50,
        views: 200,
      );

      final json = post.toJson();

      expect(json['id'], 'test_id');
      expect(json['author'], 'Test Author');
      expect(json['handle'], '@test');
      expect(json['likes'], 50);
      expect(json['views'], 200);
    });

    test('copyWith preserves unchanged fields', () {
      final original = PostModel(
        id: 'original_id',
        author: 'Original Author',
        handle: '@original',
        timeAgo: '1h',
        body: 'Original body',
        likes: 100,
        views: 500,
      );

      final modified = original.copyWith(likes: 101);

      expect(modified.id, original.id);
      expect(modified.author, original.author);
      expect(modified.handle, original.handle);
      expect(modified.body, original.body);
      expect(modified.views, original.views);
      expect(modified.likes, 101); // Only this changed
    });

    test('copyWith can update all fields', () {
      final original = PostModel(
        id: 'orig',
        author: 'A',
        handle: '@a',
        timeAgo: '1s',
        body: 'B',
      );

      final modified = original.copyWith(
        id: 'new_id',
        author: 'New Author',
        handle: '@new',
        timeAgo: '5m',
        body: 'New body',
        tags: ['new_tag'],
        replies: 10,
        reposts: 20,
        likes: 30,
        views: 40,
        bookmarks: 5,
        repostedBy: '@reposter',
        originalId: 'orig_post',
      );

      expect(modified.id, 'new_id');
      expect(modified.author, 'New Author');
      expect(modified.handle, '@new');
      expect(modified.timeAgo, '5m');
      expect(modified.body, 'New body');
      expect(modified.tags, ['new_tag']);
      expect(modified.replies, 10);
      expect(modified.reposts, 20);
      expect(modified.likes, 30);
      expect(modified.views, 40);
      expect(modified.bookmarks, 5);
      expect(modified.repostedBy, '@reposter');
      expect(modified.originalId, 'orig_post');
    });

    test('roundtrip serialization preserves all data', () {
      final original = PostModel(
        id: 'roundtrip_test',
        author: 'Roundtrip Author',
        handle: '@roundtrip',
        timeAgo: '30m',
        body: 'Testing roundtrip serialization',
        tags: ['test', 'serialization'],
        mediaPaths: ['/media/1.jpg', '/media/2.jpg'],
        replies: 7,
        reposts: 14,
        likes: 256,
        views: 2048,
        bookmarks: 32,
        quoted: PostSnapshot(
          author: 'Quoted Author',
          handle: '@quoted',
          timeAgo: '2d',
          body: 'Quoted content',
        ),
        repostedBy: '@reposter_handle',
        originalId: 'the_original_id',
      );

      final json = original.toJson();
      final restored = PostModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.author, original.author);
      expect(restored.handle, original.handle);
      expect(restored.timeAgo, original.timeAgo);
      expect(restored.body, original.body);
      expect(restored.tags, original.tags);
      expect(restored.mediaPaths, original.mediaPaths);
      expect(restored.replies, original.replies);
      expect(restored.reposts, original.reposts);
      expect(restored.likes, original.likes);
      expect(restored.views, original.views);
      expect(restored.bookmarks, original.bookmarks);
      expect(restored.quoted?.author, original.quoted?.author);
      expect(restored.quoted?.body, original.quoted?.body);
      expect(restored.repostedBy, original.repostedBy);
      expect(restored.originalId, original.originalId);
    });
  });
}
