import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AppUser?>? _cachedStream;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    _cachedStream ??= _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return AppUser(id: user.id, email: user.email);
    }).asBroadcastStream();
    return _cachedStream!;
  }

  @override
  Future<void> initialize() async {
    // Supabase client is initialized in main(); nothing else required here.
  }

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmailPassword(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    throw UnimplementedError(
      'Google sign-in requires OAuth setup in Supabase and platform configuration.',
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

