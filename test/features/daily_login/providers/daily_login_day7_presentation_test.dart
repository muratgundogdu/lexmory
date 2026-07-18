import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexmory/features/main/view/main_navigation_screen.dart';
import 'package:lexmory/features/daily_login/providers/daily_login_provider.dart';
import 'package:lexmory/features/daily_login/widgets/daily_login_dialog.dart';
import 'package:lexmory/features/library/widgets/chest_reward_overlay.dart';
import 'package:lexmory/features/library/provider/reward_queue_provider.dart';
import 'package:lexmory/core/services/clock_provider.dart';
import 'package:lexmory/features/tutorial/providers/tutorial_provider.dart';
import 'package:lexmory/features/tutorial/models/tutorial_state.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';

class MockGameNotifier extends GameNotifier {
  MockGameNotifier(super.repository, super.adService, super.ref);

  @override
  void startRegenTimer() {
    // Disable timer for tests
  }

  @override
  Future<void> loadTokens() async {}

  @override
  Future<void> addTokens(int amount) async {
    state = state.copyWith(tokens: state.tokens + amount);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Login Day 7 Presentation Coordination Tests', () {
    late DateTime mockNow;

    setUp(() {
      mockNow = DateTime(2023, 10, 10);
    });

    testWidgets('Day 7 claim enqueues reward and shows it after dialog closes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Pre-set state: Day 7 ready to claim
      SharedPreferences.setMockInitialValues({
        'tutorial_completed': true,
        'hint_clear_tutorial_shown': true,
        'reveal_tutorial_shown': true,
        'lexmory_daily_login_state': json.encode({
          'activatedOnDate': '2023-10-01',
          'lastClaimedDate': '2023-10-09',
          'currentStreakDay': 6,
        }),
      });

      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => mockNow),
          gameProvider.overrideWith((ref) {
            final repo = ref.watch(gameRepositoryProvider);
            final ads = ref.watch(adServiceProvider);
            return MockGameNotifier(repo, ads, ref);
          }),
          tutorialProvider.overrideWith((ref) => TutorialController(ref)..state = TutorialState(
            currentStep: TutorialStep.completed,
            phase: TutorialPhase.phase1,
            isTutorialActive: false,
            tutorialCompleted: true,
          )),
        ],
      );
      addTearDown(container.dispose);

      // Wait for provider to load from mock prefs
      await container.read(dailyLoginProvider.notifier).initialization;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      // Wait for Daily Login to auto-show
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DailyLoginDialog), findsOneWidget);
      expect(find.text('AL'), findsOneWidget);

      // Tap AL
      await tester.tap(find.text('AL'));
      
      // Wait for claim logic (async)
      await tester.pump(); 
      
      // Verify event is in queue
      final queue = container.read(rewardQueueProvider);
      expect(queue.events.length, 1, reason: 'Reward should be enqueued');

      // Finish closing DailyLoginDialog
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailyLoginDialog), findsNothing);

      // Now coordination logic should kick in and show ChestRewardOverlay
      await tester.pump(); // Coordination frame
      await tester.pump(const Duration(milliseconds: 500)); // Entrance animation

      expect(find.byType(ChestRewardOverlay), findsOneWidget, reason: 'ChestRewardOverlay should appear after DailyLoginDialog closes');
      expect(container.read(rewardQueueProvider).isPresenting, true);
    });
  });
}
