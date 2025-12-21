import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/auth/auth_repository.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    return StreamBuilder<AppUser?>(
      stream: auth.authStateChanges,
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data != null;
        return isLoggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
