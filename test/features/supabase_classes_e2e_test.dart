import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/class/class_repository.dart';
import 'package:my_app/core/supabase/supabase_class_repository.dart';

import '../helpers/supabase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Classes E2E', () {
    test('can create and read a class', () async {
      if (!SupabaseTestHelper.hasConfig) {
        return;
      }

      final client = await SupabaseTestHelper.ensureSupabaseClient();
      expect(client, isNotNull);

      final repo = SupabaseClassRepository(client!);

      final created = await repo.createClass(
        const CreateClassRequest(
          code: 'E2ECLASS',
          name: 'E2E Test Class',
          description: 'Created by automated test',
          deliveryMode: 'online',
          isPublic: true,
        ),
      );

      final fetched = await repo.getClassByCode('E2ECLASS');
      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);

      // Basic membership sanity: creator should be a member.
      final members = await repo.getMembers(created.id);
      expect(members, isNotEmpty);

      // Clean up test data.
      await client.from('class_members').delete().eq('class_id', created.id);
      await client.from('classes').delete().eq('id', created.id);
    });
  });
}
