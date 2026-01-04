import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/supabase/supabase_post_repository.dart';
import '../helpers/supabase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase E2E', () {
    test('can fetch posts from Supabase', () async {
      if (!SupabaseTestHelper.hasConfig) {
        return;
      }

      final client = await SupabaseTestHelper.ensureSupabaseClient();
      expect(client, isNotNull);

      final repo = SupabasePostRepository(client!);
      await repo.load();

      // Basic sanity: call timeline API and ensure it completes without error.
      final postsStream = repo.watchTimeline();

      // Collect a single emission with a timeout to avoid hanging.
      final completer = Completer<void>();
      final sub = postsStream.listen(
        (_) => completer.complete(),
        onError: (Object error, StackTrace stack) {
          if (!completer.isCompleted) {
            completer.completeError(error, stack);
          }
        },
      );

      await completer.future.timeout(const Duration(seconds: 10));
      await sub.cancel();
    });
  });
}
