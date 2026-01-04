class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const enableSupabaseFeed =
      bool.fromEnvironment('SUPABASE_FEED', defaultValue: true);

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
