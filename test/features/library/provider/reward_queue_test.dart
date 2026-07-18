import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/library/provider/reward_queue_provider.dart';
import 'package:lexmory/features/library/models/reward_presentation_event.dart';
import 'package:lexmory/features/library/models/chest_reward_source.dart';
import 'package:lexmory/features/library/models/chest_open_result.dart';

void main() {
  group('RewardQueueNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    RewardPresentationEvent createEvent(String id) {
      return RewardPresentationEvent(
        id: id,
        source: ChestRewardSource.categoryCompletion,
        result: ChestOpenResult(
          rewards: [],
          completedCollectionIds: {},
          unlockedCharacterIds: {},
          totalGrantedTokens: 0,
          completionRewardTokens: 0,
          duplicateTokens: 0,
          finalPityCounter: 0,
        ),
        createdAt: DateTime.now(),
      );
    }

    test('Enqueue one event', () {
      final notifier = container.read(rewardQueueProvider.notifier);
      final event = createEvent('1');
      
      notifier.enqueue(event);
      
      final state = container.read(rewardQueueProvider);
      expect(state.events.length, 1);
      expect(state.events.first.id, '1');
    });

    test('Enqueue preserves FIFO order', () {
      final notifier = container.read(rewardQueueProvider.notifier);
      notifier.enqueue(createEvent('1'));
      notifier.enqueue(createEvent('2'));
      
      final state = container.read(rewardQueueProvider);
      expect(state.events[0].id, '1');
      expect(state.events[1].id, '2');
    });

    test('completeCurrent removes only the first event', () {
      final notifier = container.read(rewardQueueProvider.notifier);
      notifier.enqueue(createEvent('1'));
      notifier.enqueue(createEvent('2'));
      
      notifier.completeCurrent();
      
      final state = container.read(rewardQueueProvider);
      expect(state.events.length, 1);
      expect(state.events.first.id, '2');
    });

    test('isPresenting prevents duplicate starts in UI logic (verified via flag)', () {
      final notifier = container.read(rewardQueueProvider.notifier);
      notifier.enqueue(createEvent('1'));
      
      expect(container.read(rewardQueueProvider).isPresenting, false);
      
      notifier.markPresentationStarted();
      expect(container.read(rewardQueueProvider).isPresenting, true);
      
      notifier.completeCurrent();
      expect(container.read(rewardQueueProvider).isPresenting, false);
    });

    test('clear empties the queue', () {
      final notifier = container.read(rewardQueueProvider.notifier);
      notifier.enqueue(createEvent('1'));
      notifier.clear();
      
      expect(container.read(rewardQueueProvider).events, isEmpty);
    });
  });
}
