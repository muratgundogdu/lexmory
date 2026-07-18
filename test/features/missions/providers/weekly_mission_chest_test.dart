import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexmory/features/missions/providers/daily_mission_provider.dart';
import 'package:lexmory/features/library/provider/reward_queue_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Weekly Milestone Chest Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('Claiming 7 bookmarks opens one Wooden Chest', () async {
      SharedPreferences.setMockInitialValues({
        'weeklyBookmarks': 7,
      });
      final container = createContainer();
      final notifier = container.read(dailyMissionProvider.notifier);
      await notifier.init();

      final success = await notifier.claimWeeklyChest(7);
      expect(success, isTrue);

      final queue = container.read(rewardQueueProvider);
      expect(queue.events.length, 1);
      expect(queue.events.first.title, contains('Bronz'));
      expect(queue.events.first.result.rewards.length, 2);
    });

    test('Claiming 14 bookmarks opens one Silver Chest', () async {
      SharedPreferences.setMockInitialValues({
        'weeklyBookmarks': 14,
        'claimedChestValues': ['7'],
      });
      final container = createContainer();
      final notifier = container.read(dailyMissionProvider.notifier);
      await notifier.init();

      final success = await notifier.claimWeeklyChest(14);
      expect(success, isTrue);

      final queue = container.read(rewardQueueProvider);
      expect(queue.events.any((e) => e.title!.contains('Gümüş')), isTrue);
      expect(queue.events.last.result.rewards.length, 3);
    });

    test('Claiming 21 bookmarks opens one Golden Chest', () async {
      SharedPreferences.setMockInitialValues({
        'weeklyBookmarks': 21,
        'claimedChestValues': ['7', '14'],
      });
      final container = createContainer();
      final notifier = container.read(dailyMissionProvider.notifier);
      await notifier.init();

      final success = await notifier.claimWeeklyChest(21);
      expect(success, isTrue);

      final queue = container.read(rewardQueueProvider);
      expect(queue.events.any((e) => e.title!.contains('Altın')), isTrue);
      expect(queue.events.last.result.rewards.length, 4);
    });

    test('Each milestone can only be claimed once per week', () async {
      SharedPreferences.setMockInitialValues({
        'weeklyBookmarks': 7,
      });
      final container = createContainer();
      final notifier = container.read(dailyMissionProvider.notifier);
      await notifier.init();

      await notifier.claimWeeklyChest(7);
      final secondTry = await notifier.claimWeeklyChest(7);
      
      expect(secondTry, isFalse);
      expect(container.read(rewardQueueProvider).events.length, 1);
    });

    test('Claiming 14 after 7 does not reopen the 7 reward', () async {
      SharedPreferences.setMockInitialValues({
        'weeklyBookmarks': 14,
      });
      final container = createContainer();
      final notifier = container.read(dailyMissionProvider.notifier);
      await notifier.init();

      await notifier.claimWeeklyChest(7);
      expect(container.read(rewardQueueProvider).events.length, 1);
      
      await notifier.claimWeeklyChest(14);
      expect(container.read(rewardQueueProvider).events.length, 2);
      expect(container.read(rewardQueueProvider).events.last.title, contains('Gümüş'));
    });
  });
}
