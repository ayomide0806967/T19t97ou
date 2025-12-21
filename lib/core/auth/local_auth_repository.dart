import 'dart:convert';

import 'auth_repository.dart';
import '../../services/simple_auth_service.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._service);

  final SimpleAuthService _service;

  @override
  AppUser? get currentUser {
    if (!_service.isLoggedIn) return null;
    final email = _service.currentUserEmail;
    return AppUser(
      id: _stableLocalId(email),
      email: email,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _service.authStateChanges.map((signedIn) => currentUser);

  @override
  Future<void> initialize() => _service.initializeAuth();

  @override
  Future<void> signInWithEmailPassword(String email, String password) =>
      _service.signIn(email, password);

  @override
  Future<void> signUpWithEmailPassword(String email, String password) =>
      _service.signUp(email, password);

  @override
  Future<void> signInWithGoogle() => _service.signInWithGoogle();

  @override
  Future<void> signOut() => _service.signOut();
}

String _stableLocalId(String? email) {
  final normalized = (email ?? '').trim().toLowerCase();
  if (normalized.isEmpty) return 'local_anonymous';
  return 'local_' + base64Url.encode(utf8.encode(normalized));
}

