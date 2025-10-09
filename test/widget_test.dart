import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/main.dart';
import 'package:my_app/state/app_settings.dart';

void main() {
  testWidgets('App builds and shows login CTA', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettings(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Campus conversations, reimagined.'), findsOneWidget);
  });
}
