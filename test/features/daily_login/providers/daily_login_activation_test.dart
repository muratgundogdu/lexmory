import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexmory/features/daily_login/providers/daily_login_provider.dart';
import 'package:lexmory/core/services/clock_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyLogin Activation Logic Tests', () {
    late DateTime mockNow;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockNow = DateTime(2023, 10, 10);
    });

    ProviderContainer createContainer({Map<String, Object>? initialPrefs}) {
      if (initialPrefs != null) {
        SharedPreferences.setMockInitialValues(initialPrefs);
      }
      
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => mockNow),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('Fresh install with no activation cannot claim', () async {
      final container = createContainer();
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      final state = container.read(dailyLoginProvider);
      expect(state.activatedOnDate, isNull);
      expect(state.isRewardAvailable, false);
    });

    test('Activation day cannot claim', () async {
      final container = createContainer();
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      await notifier.activateAfterOnboarding();
      
      final state = container.read(dailyLoginProvider);
      expect(state.activatedOnDate, '2023-10-10');
      expect(state.isRewardAvailable, false);
    });

    test('Day after activation offers Day 1', () async {
      // Activated yesterday
      final container = createContainer(initialPrefs: {
        'lexmory_daily_login_state': json.encode({
          'activatedOnDate': '2023-10-09',
          'currentStreakDay': 1,
        }),
      });
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      final state = container.read(dailyLoginProvider);
      expect(state.activatedOnDate, '2023-10-09');
      expect(state.isRewardAvailable, true);
      expect(state.currentStreakDay, 1);
    });

    test('Existing user with lastClaimedDate migrates as activated', () async {
      final container = createContainer(initialPrefs: {
        'lexmory_daily_login_state': json.encode({
          'lastClaimedDate': '2023-10-08',
          'currentStreakDay': 3,
        }),
      });
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      final state = container.read(dailyLoginProvider);
      expect(state.activatedOnDate, '2023-10-08'); 
      expect(state.isRewardAvailable, true);
    });

    test('Existing onboarded user (without token tutorial) gets no reward on migration day', () async {
      final container = createContainer(initialPrefs: {
        'tutorial_completed': true,
        'hint_clear_tutorial_shown': true,
        'reveal_tutorial_shown': true,
        // token_tutorial_shown is FALSE
      });
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      final state = container.read(dailyLoginProvider);
      expect(state.activatedOnDate, '2023-10-10');
      expect(state.isRewardAvailable, false);
    });

    test('Perfect player with no token tutorial activates after mandatory onboarding', () async {
      final container = createContainer();
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      // Simulate mandatory onboarding completion without token tutorial
      await notifier.activateAfterOnboarding();
      
      expect(container.read(dailyLoginProvider).activatedOnDate, '2023-10-10');
    });
  });
}
