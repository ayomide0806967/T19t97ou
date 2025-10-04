import 'dart:async';

class MockUser {
  final String email;
  final String uid;

  MockUser({required this.email, required this.uid});
}

class MockAuthService {
  MockUser? _currentUser;
  final StreamController<MockUser?> _authController = StreamController<MockUser?>.broadcast();

  MockUser? get currentUser => _currentUser;

  Stream<MockUser?> get authStateChanges => _authController.stream;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = MockUser(email: email, uid: 'mock_user_${DateTime.now().millisecondsSinceEpoch}');
      _authController.add(_currentUser);
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = MockUser(email: email, uid: 'mock_user_${DateTime.now().millisecondsSinceEpoch}');
      _authController.add(_currentUser);
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = MockUser(email: 'user@gmail.com', uid: 'google_user_${DateTime.now().millisecondsSinceEpoch}');
    _authController.add(_currentUser);
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}
