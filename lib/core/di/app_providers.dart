import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_repository.dart';
import '../auth/local_auth_repository.dart';
import '../config/app_config.dart';
import '../profile/profile_repository.dart';
import '../profile/local_profile_repository.dart';
import '../quiz/quiz_repository.dart';
import '../quiz/local_quiz_repository.dart';
import '../supabase/supabase_auth_repository.dart';
import '../supabase/supabase_post_repository.dart';
import '../supabase/supabase_profile_repository.dart';
import '../supabase/supabase_quiz_repository.dart';
import '../../services/data_service.dart';
import '../../services/profile_service.dart';
import '../../state/app_settings.dart';
import '../../services/simple_auth_service.dart';
import '../../features/feed/domain/post_repository.dart';

/// Core dependency graph wired through Riverpod.
///
/// UI will gradually migrate to read from these providers instead of
/// depending directly on `provider` / `ChangeNotifier`.

final appSettingsProvider = Provider<AppSettings>((ref) {
  throw UnimplementedError('appSettingsProvider is overridden in main.dart');
});

/// Listenable view of [AppSettings] so widgets can rebuild when the theme
/// or other settings change.
final appSettingsListenableProvider =
    Provider<AppSettings>((ref) => ref.watch(appSettingsProvider));

final dataServiceProvider = Provider<DataService>((ref) {
  throw UnimplementedError('dataServiceProvider is overridden in main.dart');
});

/// Legacy ProfileService provider (for gradual migration).
final profileServiceProvider = Provider<ProfileService>((ref) {
  throw UnimplementedError('profileServiceProvider is overridden in main.dart');
});

/// New ProfileRepository provider - use this for new code.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError('profileRepositoryProvider is overridden in main.dart');
});

/// QuizRepository provider.
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  throw UnimplementedError('quizRepositoryProvider is overridden in main.dart');
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.hasSupabaseConfig) {
    return SupabaseAuthRepository(ref.read(supabaseClientProvider));
  }
  return LocalAuthRepository(SimpleAuthService());
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  if (AppConfig.hasSupabaseConfig && AppConfig.enableSupabaseFeed) {
    return SupabasePostRepository(ref.read(supabaseClientProvider));
  }
  return ref.read(dataServiceProvider);
});
