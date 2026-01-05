import 'dart:async';

import 'package:flutter/foundation.dart';
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
    // Uses Supabase OAuth flow (browser-based) with a deep-link callback on
    // mobile and a same-origin callback on web.
    final redirectTo = kIsWeb
        // Important: drop URL fragments (e.g. `/#/`) so Supabase can append
        // `?code=...` as real query params; fragments are not reliably handled
        // by OAuth redirects and can prevent session exchange on web.
        ? Uri.base.replace(queryParameters: const {}, fragment: '').toString()
        : Uri(scheme: 'io.supabase.flutter', host: 'login-callback').toString();

    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
