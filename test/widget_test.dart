import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eduzio/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EduzioApp(),
      ),
    );

    // Verify that the login screen is loaded and displays app name & subtitle
    expect(find.text('Eduzio'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
