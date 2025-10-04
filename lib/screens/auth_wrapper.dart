import 'package:flutter/material.dart';

import '../services/simple_auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SimpleAuthService _authService = SimpleAuthService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();

    // Add timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isInitialized) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  Future<void> _initializeAuth() async {
    try {
      await _authService.initializeAuth();
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _authService.authStateChanges,
      initialData: _authService.isLoggedIn,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
