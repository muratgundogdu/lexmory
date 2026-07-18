import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexmory/features/missions/providers/daily_mission_provider.dart';
import 'package:lexmory/features/library/provider/collection_provider.dart';
import 'package:lexmory/features/library/provider/reward_queue_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyMissionNotifier Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('Daily full completion enqueues Silver Chest immediately', () async {
      final container = createContainer();
      final notifier = container.read(dailyMissionProvider.notifier);
      await notifier.init();

      // Simulate completing all missions
      final missions = container.read(dailyMissionProvider).missions;
      for (var m in missions) {
        await notifier.updateMaxProgress(m.mission.type, m.mission.target);
        await notifier.claimMission(m.mission.id);
      }

      // Check if reward was enqueued
      final queue = container.read(rewardQueueProvider);
      expect(queue.events.length, 1);
      expect(container.read(collectionProvider).ownedCardIds, isNotEmpty);
    });
  });
}
