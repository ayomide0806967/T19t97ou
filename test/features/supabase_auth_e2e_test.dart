import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/supabase/supabase_auth_repository.dart';

import '../helpers/supabase_test_helper.dart';

// These are optional and only used if provided via --dart-define.
const _testEmail = String.fromEnvironment('SUPABASE_TEST_EMAIL');
const _testPassword = String.fromEnvironment('SUPABASE_TEST_PASSWORD');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Auth E2E', () {
    test('can sign in with email/password', () async {
      if (!SupabaseTestHelper.hasConfig ||
          _testEmail.isEmpty ||
          _testPassword.isEmpty) {
        // Environment not configured for auth E2E; skip.
        return;
      }

      final client = await SupabaseTestHelper.ensureSupabaseClient();
      expect(client, isNotNull);

      final AuthRepository repo = SupabaseAuthRepository(client!);

      await repo.signInWithEmailPassword(_testEmail, _testPassword);
      final user = repo.currentUser;

      expect(user, isNotNull);
      expect(user!.email, _testEmail);
    });
  });
}

