import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/di/app_providers.dart';
import 'core/supabase/supabase_auth_repository.dart';
import 'core/supabase/supabase_post_repository.dart';
import 'core/supabase/supabase_profile_repository.dart';
import 'core/supabase/supabase_quiz_repository.dart';
import 'features/feed/domain/post_repository.dart';
import 'screens/auth_wrapper.dart';
import 'screens/missing_config_screen.dart';
import 'theme/app_theme.dart';
import 'core/ui/theme_mode_controller.dart';
import 'core/ui/app_preferences_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Log any framework errors to the zone as well.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.empty,
    );
  };

  runZonedGuarded(() async {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Initialize Supabase if configured. Show UI immediately to avoid a blank
    // screen while async initialization is in progress.
    if (!AppConfig.hasSupabaseConfig) {
      runApp(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MissingConfigScreen(),
        ),
      );
      return;
    }

    runApp(const _InitLoadingApp());

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );

      final authRepository = SupabaseAuthRepository(Supabase.instance.client);

      final PostRepository postRepository = SupabasePostRepository(
        Supabase.instance.client,
      );
      await postRepository.load();

      final profileRepository =
          SupabaseProfileRepository(Supabase.instance.client);
      await profileRepository.load();

      final quizRepository = SupabaseQuizRepository(Supabase.instance.client);
      await quizRepository.load();

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
    } catch (e) {
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: _InitErrorScreen(error: e),
        ),
      );
    }
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint(stack.toString());
  });
}

class _InitLoadingApp extends StatelessWidget {
  const _InitLoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        title: const Text('Startup Error'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The app failed to start.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
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
      home: const AuthWrapper(),
    );
  }
}
