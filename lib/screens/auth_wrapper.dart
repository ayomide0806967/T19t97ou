import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAuth = ref.watch(authStateProvider);

    return asyncAuth.when(
      data: (user) =>
          user != null ? const HomeScreen() : const LoginScreen(),
      loading: () => const LoginScreen(),
      error: (_, __) => const LoginScreen(),
    );
  }
}
