import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/supabase/supabase_messaging_repository.dart';

import '../helpers/supabase_test_helper.dart';

// Optional: a second user ID to message, provided via --dart-define.
const _otherUserId = String.fromEnvironment('SUPABASE_TEST_OTHER_USER_ID');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Messaging E2E', () {
    test('can create or fetch a direct conversation and send a message',
        () async {
      if (!SupabaseTestHelper.hasConfig || _otherUserId.isEmpty) {
        return;
      }

      final client = await SupabaseTestHelper.ensureSupabaseClient();
      expect(client, isNotNull);

      final repo = SupabaseMessagingRepository(client!);

      final conversationId =
          await repo.getOrCreateDirectConversation(_otherUserId);

      final beforeMessages = await repo.getMessages(conversationId);

      final sent = await repo.sendMessage(
        conversationId: conversationId,
        body: 'Hello from E2E test',
      );

      expect(sent.conversationId, conversationId);

      final afterMessages = await repo.getMessages(conversationId);
      expect(afterMessages.length, greaterThanOrEqualTo(beforeMessages.length));
    });
  });
}

