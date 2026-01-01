import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_repository.dart';
import 'core/auth/local_auth_repository.dart';
import 'core/config/app_config.dart';
import 'core/di/app_providers.dart';
import 'core/profile/profile_repository.dart';
import 'core/profile/local_profile_repository.dart';
import 'core/quiz/quiz_repository.dart' as quiz;
import 'core/quiz/local_quiz_repository.dart';
import 'core/supabase/supabase_auth_repository.dart';
import 'core/supabase/supabase_post_repository.dart';
import 'core/supabase/supabase_profile_repository.dart';
import 'core/supabase/supabase_quiz_repository.dart';
import 'features/feed/domain/post_repository.dart';
import 'screens/auth_wrapper.dart';
import 'services/data_service.dart';
import 'services/profile_service.dart';
import 'services/simple_auth_service.dart';
import 'state/app_settings.dart';
import 'theme/app_theme.dart';
import 'core/ui/theme_mode_controller.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Log any framework errors to the zone as well
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
    };

    final settings = AppSettings();
    await settings.load();

    if (AppConfig.hasSupabaseConfig) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    }

    late final AuthRepository authRepository;
    if (AppConfig.hasSupabaseConfig) {
      authRepository = SupabaseAuthRepository(Supabase.instance.client);
    } else {
      authRepository = LocalAuthRepository(SimpleAuthService());
      await authRepository.initialize();
    }

    // Prepare post repository (local by default; Supabase when enabled).
    final dataService = DataService();
    await dataService.load();
    final PostRepository postRepository;
    if (AppConfig.hasSupabaseConfig && AppConfig.enableSupabaseFeed) {
      postRepository = SupabasePostRepository(Supabase.instance.client);
      await postRepository.load();
    } else {
      postRepository = dataService;
    }

    // Legacy ProfileService (kept for backward compatibility).
    final profileService = ProfileService();
    await profileService.load();

    // New ProfileRepository abstraction.
    late final ProfileRepository profileRepository;
    if (AppConfig.hasSupabaseConfig) {
      profileRepository = SupabaseProfileRepository(Supabase.instance.client);
    } else {
      profileRepository = LocalProfileRepository();
    }
    await profileRepository.load();

    // QuizRepository abstraction.
    late final quiz.QuizRepository quizRepository;
    if (AppConfig.hasSupabaseConfig) {
      quizRepository = SupabaseQuizRepository(Supabase.instance.client);
    } else {
      quizRepository = LocalQuizRepository();
    }
    await quizRepository.load();

    runApp(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWithValue(settings),
          dataServiceProvider.overrideWithValue(dataService),
          profileServiceProvider.overrideWithValue(profileService),
          authRepositoryProvider.overrideWithValue(authRepository),
          postRepositoryProvider.overrideWithValue(postRepository),
          profileRepositoryProvider.overrideWithValue(profileRepository),
          quizRepositoryProvider.overrideWithValue(quizRepository),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // Ensure crashes are visible in logs instead of silently terminating
    debugPrint('Uncaught error: $error');
    debugPrint(stack.toString());
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp(
      title: 'IN-Institution',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthWrapper(),
    );
  }
}
