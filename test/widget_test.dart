import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/main.dart';

void main() {
  testWidgets('Game screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LexmoryApp()));

    // Verify that category is shown.
    expect(find.text('KATEGORİ'), findsOneWidget);
    expect(find.text('Kırmızı Meyveler'), findsOneWidget);
  });
}
