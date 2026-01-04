import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/supabase/supabase_comment_repository.dart';

import '../helpers/supabase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Comments E2E', () {
    test('can create and read a comment', () async {
      if (!SupabaseTestHelper.hasConfig) {
        return;
      }

      final client = await SupabaseTestHelper.ensureSupabaseClient();
      expect(client, isNotNull);

      // Create a lightweight post row directly for the purpose of this test.
      // This assumes the `posts` table from docs/supabase_schema.sql.
      final postRow = await client!.from('posts').insert({
        'body': 'E2E test post',
      }).select('id').single();

      final postId = postRow['id'] as String;

      final repo = SupabaseCommentRepository(client);

      // Add a comment to the post and verify it round-trips.
      final created = await repo.addComment(
        postId: postId,
        body: 'Hello from E2E test',
      );

      expect(created.postId, postId);

      final comments = await repo.getComments(postId);
      expect(
        comments.any((c) => c.id == created.id && c.body == created.body),
        isTrue,
      );

      // Clean up the test data to avoid polluting the real feed.
      await client.from('post_comments').delete().eq('post_id', postId);
      await client.from('posts').delete().eq('id', postId);
    });
  });
}
