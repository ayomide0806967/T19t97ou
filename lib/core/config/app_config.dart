class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const enableSupabaseFeed =
      bool.fromEnvironment('SUPABASE_FEED', defaultValue: true);
  static const quizShareBaseUrl =
      String.fromEnvironment('QUIZ_SHARE_BASE_URL', defaultValue: '');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String quizShareLink(String quizId) {
    final base = quizShareBaseUrl.trim();
    if (base.isEmpty) return quizId;
    return base.endsWith('/') ? '$base$quizId' : '$base/$quizId';
  }
}
