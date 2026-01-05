import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/di/app_providers.dart';
import 'core/auth/web_oauth_callback.dart';
import 'core/supabase/supabase_auth_repository.dart';
import 'core/supabase/supabase_post_repository.dart';
import 'core/supabase/supabase_profile_repository.dart';
import 'core/supabase/supabase_quiz_repository.dart';
import 'features/feed/domain/post_repository.dart';
import 'screens/auth_wrapper.dart';
import 'screens/app_bootstrapper.dart';
import 'screens/missing_config_screen.dart';
import 'theme/app_theme.dart';
import 'core/ui/theme_mode_controller.dart';
import 'core/ui/app_preferences_controller.dart';

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

    // Initialize Supabase if configured
    if (!AppConfig.hasSupabaseConfig) {
      runApp(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MissingConfigScreen(),
        ),
      );
      return;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    // On web, complete OAuth PKCE sign-in after redirect back with `?code=...`.
    // Do not block app startup on this network exchange; otherwise Flutter Web
    // can remain stuck on the HTML splash if the request hangs.
    unawaited(completeWebOAuthSignIn(Supabase.instance.client));

    final authRepository = SupabaseAuthRepository(Supabase.instance.client);

    final PostRepository postRepository = SupabasePostRepository(
      Supabase.instance.client,
    );

    final profileRepository =
        SupabaseProfileRepository(Supabase.instance.client);

    final quizRepository = SupabaseQuizRepository(Supabase.instance.client);

    runApp(
      ProviderScope(
        overrides: [
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
    final prefs = ref.watch(appPreferencesControllerProvider);

    return MaterialApp(
      title: 'In Institution',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme:
          prefs.blackoutTheme ? AppTheme.blackoutDarkTheme : AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppBootstrapper(child: AuthWrapper()),
    );
  }
}
