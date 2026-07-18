import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexmory/features/daily_login/providers/daily_login_provider.dart';
import 'package:lexmory/core/services/clock_provider.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';
import 'package:lexmory/features/library/provider/collection_provider.dart';
import 'package:lexmory/features/library/provider/reward_queue_provider.dart';

class MockGameNotifier extends GameNotifier {
  MockGameNotifier(super.repository, super.adService, super.ref);

  @override
  Future<void> loadTokens() async {}

  @override
  Future<void> addTokens(int amount) async {
    state = state.copyWith(tokens: state.tokens + amount);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyLoginNotifier Logic Tests', () {
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
          gameProvider.overrideWith((ref) {
            final repo = ref.watch(gameRepositoryProvider);
            final ads = ref.watch(adServiceProvider);
            return MockGameNotifier(repo, ads, ref);
          }),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('New player starts at Day 1 but needs activation', () async {
      final container = createContainer();
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      final state = container.read(dailyLoginProvider);
      expect(state.activatedOnDate, isNull);
      expect(state.isRewardAvailable, false);
      
      // Activate
      await notifier.activateAfterOnboarding();
      expect(container.read(dailyLoginProvider).activatedOnDate, '2023-10-10');
      expect(container.read(dailyLoginProvider).isRewardAvailable, false);
    });

    test('Claiming Day 1 persists and makes it unavailable for same day', () async {
      // Activated yesterday
      final container = createContainer(initialPrefs: {
         'lexmory_daily_login_state': json.encode({
          'activatedOnDate': '2023-10-09',
          'currentStreakDay': 1,
        }),
      });
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      await notifier.claimReward();
      
      final state = container.read(dailyLoginProvider);
      expect(state.isRewardAvailable, false);
      expect(state.lastClaimedDate, '2023-10-10');

      final prefs = await SharedPreferences.getInstance();
      final saved = json.decode(prefs.getString('lexmory_daily_login_state')!);
      expect(saved['lastClaimedDate'], '2023-10-10');
    });

    test('Yesterday claim advances streak to Day 2', () async {
      final container = createContainer(initialPrefs: {
        'lexmory_daily_login_state': json.encode({
          'activatedOnDate': '2023-10-08',
          'lastClaimedDate': '2023-10-09',
          'currentStreakDay': 1,
        }),
      });
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      final state = container.read(dailyLoginProvider);
      expect(state.currentStreakDay, 2);
      expect(state.isRewardAvailable, true);
    });

    test('Missing one full day resets streak to Day 1', () async {
      final container = createContainer(initialPrefs: {
        'lexmory_daily_login_state': json.encode({
          'activatedOnDate': '2023-10-05',
          'lastClaimedDate': '2023-10-08', 
          'currentStreakDay': 3,
        }),
      });
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      final state = container.read(dailyLoginProvider);
      expect(state.currentStreakDay, 1);
      expect(state.isRewardAvailable, true);
    });

    test('Day 7 followed by next day returns to Day 1', () async {
      final container = createContainer(initialPrefs: {
        'lexmory_daily_login_state': json.encode({
          'activatedOnDate': '2023-10-01',
          'lastClaimedDate': '2023-10-09',
          'currentStreakDay': 7,
        }),
      });
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;

      final state = container.read(dailyLoginProvider);
      expect(state.currentStreakDay, 1);
      expect(state.isRewardAvailable, true);
    });

    test('Day 7 grants tokens and enqueues chest', () async {
      final container = createContainer(initialPrefs: {
        'lexmory_daily_login_state': json.encode({
          'activatedOnDate': '2023-10-01',
          'lastClaimedDate': '2023-10-09',
          'currentStreakDay': 6,
        }),
      });
      final notifier = container.read(dailyLoginProvider.notifier);
      await notifier.initialization;
      
      container.read(gameProvider.notifier).addTokens(0); 
      
      final result = await notifier.claimReward();
      
      expect(result.streakDay, 7);
      expect(result.grantedTokens, 200);
      
      final queue = container.read(rewardQueueProvider);
      expect(queue.events.length, 1);
      expect(queue.events.first.title, contains('7. Gün'));
      expect(container.read(collectionProvider).ownedCardIds, isNotEmpty);
    });
  });
}
