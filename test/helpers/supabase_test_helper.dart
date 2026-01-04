import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:my_app/core/config/app_config.dart';

/// Shared helper for Supabase-backed end-to-end tests.
///
/// Tests can call [ensureSupabaseClient] to lazily initialize Supabase using
/// the same `AppConfig` values that the app uses. If Supabase is not
/// configured, `null` is returned so tests can effectively no-op.
class SupabaseTestHelper {
  SupabaseTestHelper._();

  static SupabaseClient? _client;

  static bool get hasConfig => AppConfig.hasSupabaseConfig;

  static Future<SupabaseClient?> ensureSupabaseClient() async {
    if (!AppConfig.hasSupabaseConfig) {
      return null;
    }
    if (_client != null) {
      return _client;
    }
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    return _client;
  }
}

