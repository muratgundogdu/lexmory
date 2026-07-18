import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/daily_login/widgets/daily_login_dialog.dart';
import 'package:lexmory/features/daily_login/providers/daily_login_provider.dart';
import 'package:lexmory/features/daily_login/models/daily_login_state.dart';

void main() {
  Widget createDialog(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: DailyLoginDialog(),
        ),
      ),
    );
  }

  group('DailyLoginDialog Widget Tests', () {
    testWidgets('Dialog displays title and subtitle', (tester) async {
      // Set physical size to avoid overflow in tests
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      await tester.pumpWidget(createDialog(container));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('GÜNLÜK GİRİŞ ÖDÜLÜ'), findsOneWidget);
      expect(find.text('Her gün gel, ödüllerin büyüsün!'), findsOneWidget);
    });

    testWidgets('Claim button is enabled when reward is available', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          dailyLoginProvider.overrideWith((ref) => DailyLoginNotifier(ref)..state = const DailyLoginState(
            currentStreakDay: 1,
            isRewardAvailable: true,
            isLoading: false,
          )),
        ],
      );
      
      await tester.pumpWidget(createDialog(container));
      await tester.pump(const Duration(seconds: 2));
      
      final button = find.byType(ElevatedButton);
      expect(tester.widget<ElevatedButton>(button).enabled, isTrue);
    });

    testWidgets('Claim button is disabled when reward is already claimed', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          dailyLoginProvider.overrideWith((ref) => DailyLoginNotifier(ref)..state = const DailyLoginState(
            currentStreakDay: 1,
            isRewardAvailable: false,
            isLoading: false,
          )),
        ],
      );
      
      await tester.pumpWidget(createDialog(container));
      await tester.pump(const Duration(seconds: 2));
      
      final button = find.byType(ElevatedButton);
      expect(tester.widget<ElevatedButton>(button).enabled, isFalse);
    });
  });
}
