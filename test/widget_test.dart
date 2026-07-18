import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/main.dart';
import 'package:lexmory/features/game/view/splash_screen.dart';

void main() {
  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We use runAsync to allow the splash screen timers to exist without failing the test immediately
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: LexmoryApp()));
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}
