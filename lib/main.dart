import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth_wrapper.dart';
import 'state/app_settings.dart';
import 'services/data_service.dart';
import 'services/profile_service.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/local_auth_repository.dart';
import 'services/simple_auth_service.dart';
import 'core/feed/post_repository.dart';

import 'dart:async';

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

    final authRepository = LocalAuthRepository(SimpleAuthService());
    await authRepository.initialize();

    // Prepare data services
    final dataService = DataService();
    await dataService.load();
    final profileService = ProfileService();
    await profileService.load();

    runApp(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: authRepository),
          ChangeNotifierProvider<AppSettings>.value(value: settings),
          ChangeNotifierProvider<DataService>.value(value: dataService),
          Provider<PostRepository>.value(value: dataService),
          ChangeNotifierProvider<ProfileService>.value(value: profileService),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      title: 'IN-Institution',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const AuthWrapper(),
    );
  }
}
