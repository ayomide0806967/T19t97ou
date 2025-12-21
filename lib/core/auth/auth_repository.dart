abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;

  Future<void> initialize();

  Future<void> signInWithEmailPassword(String email, String password);
  Future<void> signUpWithEmailPassword(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
  });

  final String id;
  final String? email;
}

