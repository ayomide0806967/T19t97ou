import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/main.dart';
import 'package:my_app/state/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App builds and shows login CTA', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object?>{});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettings(),
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Get Started'), findsOneWidget);
  });
}
