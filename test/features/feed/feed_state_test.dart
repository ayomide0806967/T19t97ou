import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/features/feed/domain/feed_state.dart';
import 'package:my_app/models/post.dart';

void main() {
  group('FeedState', () {
    test('default constructor creates valid state', () {
      const state = FeedState(posts: []);

      expect(state.posts, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates isLoading', () {
      const original = FeedState(posts: [], isLoading: true);
      final modified = original.copyWith(isLoading: false);

      expect(modified.isLoading, isFalse);
      expect(modified.posts, isEmpty);
    });

    test('copyWith preserves posts when not specified', () {
      final posts = [
        PostModel(
          id: 'test',
          author: 'Author',
          handle: '@handle',
          body: 'Body',
          timeAgo: 'Now',
        ),
      ];
      final original = FeedState(posts: posts, isLoading: false);
      final modified = original.copyWith(isLoading: true);

      expect(modified.isLoading, isTrue);
      expect(modified.posts.length, 1);
    });

    test('copyWith can update error message', () {
      const original = FeedState(posts: []);
      final modified = original.copyWith(errorMessage: 'Test error');

      expect(modified.errorMessage, 'Test error');
    });
  });
}
