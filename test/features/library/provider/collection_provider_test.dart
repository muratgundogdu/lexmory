import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexmory/features/library/provider/collection_provider.dart';
import 'package:lexmory/features/library/models/chest_reward_source.dart';
import 'package:lexmory/core/services/random_provider.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';
import 'package:lexmory/data/collection_pool.dart';
import 'package:lexmory/features/library/models/chest_type.dart';
import 'package:lexmory/features/library/models/card_rarity.dart';

class FakeRandom implements Random {
  List<double> nextDoubleValues = [];
  int nextIntValue = 0;

  set nextDoubleValue(double v) => nextDoubleValues = [v];

  @override
  double nextDouble() => nextDoubleValues.isNotEmpty ? nextDoubleValues.removeAt(0) : 0.0;

  @override
  int nextInt(int max) => nextIntValue;

  @override
  bool nextBool() => nextDouble() > 0.5;
}

class FailingGameNotifier extends GameNotifier {
  FailingGameNotifier(super.repository, super.adService, super.ref);

  @override
  Future<void> loadTokens() async {}

  @override
  Future<void> addTokens(int amount) async {
    if (amount > 0) {
      throw Exception('Economy system failure');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CollectionProvider Integration Tests (Immediate Opening)', () {
    late FakeRandom fakeRandom;

    setUp(() {
      fakeRandom = FakeRandom();
    });

    ProviderContainer createContainer({bool failEconomy = false}) {
      final container = ProviderContainer(
        overrides: [
          randomProvider.overrideWithValue(fakeRandom),
          if (failEconomy)
            gameProvider.overrideWith((ref) {
              final repository = ref.watch(gameRepositoryProvider);
              final adService = ref.watch(adServiceProvider);
              return FailingGameNotifier(repository, adService, ref);
            }),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('Initial state is empty and has no inventory', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();
      await container.read(collectionProvider.notifier).initialization;
      
      final state = container.read(collectionProvider);
      expect(state.ownedCardIds, isEmpty);
      expect(state.pityCounter, 0);
      // unopenedChestCounts is gone from state
    });

    test('Legacy JSON containing unopenedChestCounts still loads safely', () async {
      final legacyJson = json.encode({
        'ownedCardIds': ['ba_01'],
        'unlockedCharacterIds': [],
        'pityCounter': 5,
        'unopenedChestCounts': {'wooden_chest': 3},
      });
      SharedPreferences.setMockInitialValues({
        'lexmory_collection_state': legacyJson,
      });

      final container = createContainer();
      await container.read(collectionProvider.notifier).initialization;

      final state = container.read(collectionProvider);
      expect(state.ownedCardIds, contains('ba_01'));
      expect(state.pityCounter, 5);
      // No crash, and unopenedChestCounts is simply ignored
    });

    test('openChestReward immediately updates state and economy', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();
      final notifier = container.read(collectionProvider.notifier);
      await notifier.initialization;

      // Force a specific card (ba_01)
      // WantsNew=true(0.0), Rarity=Common(0.0), Selection=First(0.0)
      fakeRandom.nextDoubleValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

      final result = await notifier.openChestReward(ChestRewardSource.categoryCompletion);
      
      expect(result.rewards.isNotEmpty, true);
      final state = container.read(collectionProvider);
      expect(state.ownedCardIds, contains(result.rewards.first.card.id));
      
      final prefs = await SharedPreferences.getInstance();
      final saved = json.decode(prefs.getString('lexmory_collection_state')!);
      expect(saved['ownedCardIds'], contains(result.rewards.first.card.id));
    });

    test('openChestReward rollbacks on economy failure', () async {
      final cardId = collectionPool.first.id;
      SharedPreferences.setMockInitialValues({
        'lexmory_collection_state': json.encode({
          'ownedCardIds': [cardId],
          'unlockedCharacterIds': [],
          'pityCounter': 0,
        }),
      });

      final container = createContainer(failEconomy: true);
      final notifier = container.read(collectionProvider.notifier);
      await notifier.initialization;

      // Force duplicates to trigger addTokens
      fakeRandom.nextDoubleValues = [0.9, 0.5, 0.5, 0.9, 0.5, 0.5];

      await expectLater(notifier.openChestReward(ChestRewardSource.categoryCompletion), throwsA(isA<Exception>()));
      
      final state = container.read(collectionProvider);
      expect(state.ownedCardIds.length, 1); // Restored

      final prefs = await SharedPreferences.getInstance();
      final saved = json.decode(prefs.getString('lexmory_collection_state')!);
      expect(saved['ownedCardIds'].length, 1);
    });

    test('Direct openChest remains safely compatible (testing only)', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();
      final notifier = container.read(collectionProvider.notifier);
      await notifier.initialization;

      const testChest = ChestType(
        id: 'test',
        name: 'Test Chest',
        cardCount: 1,
        guaranteedNewCardCount: 1,
        rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0},
        baseNewCardChance: 1.0,
        pityIncrement: 1,
        imagePath: '',
      );

      final result = await notifier.openChest(testChest);
      expect(result.rewards.length, 1);
      expect(container.read(collectionProvider).ownedCardIds, contains(result.rewards.first.card.id));
    });
  });
}
