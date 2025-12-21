import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/main.dart';
import 'package:my_app/state/app_settings.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> get authStateChanges => const Stream<AppUser?>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUpWithEmailPassword(String email, String password) async {}
}

void main() {
  testWidgets('App builds and shows login CTA', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object?>{});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: _TestAuthRepository()),
          ChangeNotifierProvider(create: (_) => AppSettings()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Get Started'), findsOneWidget);
  });
}
