import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  bool _isLoggedIn = false;
  String? _currentUserEmail;

  final StreamController<bool> _authController = StreamController<bool>.broadcast();

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserEmail => _currentUserEmail;
  Stream<bool> get authStateChanges => _authController.stream;

  Future<void> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _currentUserEmail = prefs.getString('user_email');
      _authController.add(_isLoggedIn);
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      _currentUserEmail = email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', email);

      _authController.add(_isLoggedIn);
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signUp(String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      _currentUserEmail = email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', email);

      _authController.add(_isLoggedIn);
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signInWithGoogle() async {
    // Simulate Google sign-in delay
    await Future.delayed(const Duration(seconds: 1));

    _isLoggedIn = true;
    _currentUserEmail = 'user@gmail.com';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', 'user@gmail.com');

    _authController.add(_isLoggedIn);
  }

  Future<void> signOut() async {
    _isLoggedIn = false;
    _currentUserEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_email');

    _authController.add(_isLoggedIn);
  }

  void dispose() {
    _authController.close();
  }
}
