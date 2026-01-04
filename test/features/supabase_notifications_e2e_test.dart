import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/supabase/supabase_notification_repository.dart';

import '../helpers/supabase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Notifications E2E', () {
    test('can load notifications and mark all as read', () async {
      if (!SupabaseTestHelper.hasConfig) {
        return;
      }

      final client = await SupabaseTestHelper.ensureSupabaseClient();
      expect(client, isNotNull);

      final repo = SupabaseNotificationRepository(client!);

      await repo.load();
      final initialCount = repo.unreadCount;

      final changed = await repo.markAllAsRead();

      // After marking all as read, unreadCount should be zero (or unchanged if there were none).
      expect(repo.unreadCount, 0);
      if (initialCount > 0) {
        expect(changed, greaterThan(0));
      }
    });
  });
}

