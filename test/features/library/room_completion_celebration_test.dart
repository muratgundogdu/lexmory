import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/library/provider/library_provider.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';
import 'package:lexmory/features/library/provider/collection_provider.dart';
import 'package:lexmory/features/game/repository/game_repository.dart';
import 'package:lexmory/features/game/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGameNotifier extends GameNotifier {
  MockGameNotifier(super.repository, super.adService, super.ref);

  @override
  void startRegenTimer() {}

  @override
  Future<void> loadTokens() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Room Completion Celebration Hardening Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          gameProvider.overrideWith((ref) {
            return MockGameNotifier(GameRepository(), AdService(), ref);
          }),
        ],
      );
      
      // Ensure providers are initialized
      await container.read(libraryProvider.notifier).initialization;
      await container.read(collectionProvider.notifier).initialization;
      
      // Give some tokens to test upgrade
      await container.read(gameProvider.notifier).addTokens(1000000);
    });

    tearDown(() {
      container.dispose();
    });

    test('Transition to 100% grants reward exactly once and sets pendingCelebration', () async {
      final notifier = container.read(libraryProvider.notifier);
      final room01Id = 'room_01';
      
      // Initially no rewards claimed
      expect(container.read(libraryProvider).claimedRoomRewardIds, isEmpty);
      expect(container.read(libraryProvider).pendingCelebration, isNull);

      // Perform all upgrades for Room 1
      for (int i = 0; i < 7; i++) {
        await notifier.upgradeRoom(room01Id);
      }

      final state = container.read(libraryProvider);
      expect(state.roomStages[room01Id], 7);
      expect(state.claimedRoomRewardIds, contains(room01Id));
      expect(state.pendingCelebration, isNotNull);
      expect(state.pendingCelebration!.roomId, room01Id);

      // Verify specific rewards (based on roomRewards config for room_01)
      // tokens: 500, hints: 1, removeWrongs: 1
      expect(state.pendingCelebration!.tokenReward, 500);

      // Try to upgrade again - should not trigger reward again (idempotency)
      final prevResult = state.pendingCelebration;
      await notifier.upgradeRoom(room01Id);
      
      expect(container.read(libraryProvider).pendingCelebration, prevResult, reason: 'Reward should not be granted again');
    });

    test('consumeCelebration clears the pending state correctly', () async {
      final notifier = container.read(libraryProvider.notifier);
      final room01Id = 'room_01';

      for (int i = 0; i < 7; i++) {
        await notifier.upgradeRoom(room01Id);
      }

      expect(container.read(libraryProvider).pendingCelebration, isNotNull);
      
      notifier.consumeCelebration();
      expect(container.read(libraryProvider).pendingCelebration, isNull);
    });

    test('Rewards are persisted and restored after "restart"', () async {
      final notifier = container.read(libraryProvider.notifier);
      final room01Id = 'room_01';

      for (int i = 0; i < 7; i++) {
        await notifier.upgradeRoom(room01Id);
      }
      
      expect(container.read(libraryProvider).claimedRoomRewardIds, contains(room01Id));
      
      // Simulate "restart" by creating new container with same SharedPreferences mock
      final container2 = ProviderContainer(
         overrides: [
          gameProvider.overrideWith((ref) => MockGameNotifier(GameRepository(), AdService(), ref)),
        ],
      );
      await container2.read(libraryProvider.notifier).initialization;
      
      expect(container2.read(libraryProvider).claimedRoomRewardIds, contains(room01Id));
      expect(container2.read(libraryProvider).roomStages[room01Id], 7);
      
      container2.dispose();
    });
  });
}
