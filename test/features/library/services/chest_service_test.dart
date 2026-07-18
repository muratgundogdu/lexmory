import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexmory/features/library/models/album_set.dart';
import 'package:lexmory/features/library/models/card_rarity.dart';
import 'package:lexmory/features/library/models/chest_type.dart';
import 'package:lexmory/features/library/models/collection_card.dart';
import 'package:lexmory/features/library/models/collection_state.dart';
import 'package:lexmory/features/library/services/chest_service.dart';
import 'package:flutter/material.dart';

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

void main() {
  late ChestService chestService;
  late List<CollectionCard> mockCards;
  late List<AlbumSet> mockAlbums;
  late ChestType woodenChest;

  setUp(() {
    chestService = ChestService();
    mockAlbums = [
      const AlbumSet(
        id: 'set_01',
        name: 'Set 1',
        characterName: 'Char 1',
        characterImagePath: '',
        rewardTokens: 100,
        themeColor: Colors.blue,
      ),
    ];
    mockCards = [
      const CollectionCard(id: 'c1', name: 'C1', description: '', rarity: CardRarity.common, imagePath: '', collectionId: 'set_01', setName: 'Set 1', stars: 1),
      const CollectionCard(id: 'c2', name: 'C2', description: '', rarity: CardRarity.common, imagePath: '', collectionId: 'set_01', setName: 'Set 1', stars: 1),
      const CollectionCard(id: 'c3', name: 'C3', description: '', rarity: CardRarity.common, imagePath: '', collectionId: 'set_01', setName: 'Set 1', stars: 1),
      const CollectionCard(id: 'r1', name: 'R1', description: '', rarity: CardRarity.rare, imagePath: '', collectionId: 'set_01', setName: 'Set 1', stars: 2),
      const CollectionCard(id: 'r2', name: 'R2', description: '', rarity: CardRarity.rare, imagePath: '', collectionId: 'set_01', setName: 'Set 1', stars: 2),
      const CollectionCard(id: 'l1', name: 'L1', description: '', rarity: CardRarity.legendary, imagePath: '', collectionId: 'set_01', setName: 'Set 1', stars: 3),
    ];
    woodenChest = const ChestType(
      id: 'wooden',
      name: 'Wooden',
      cardCount: 2,
      guaranteedNewCardCount: 0,
      rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0},
      baseNewCardChance: 0.5,
      pityIncrement: 1,
      imagePath: '',
    );
  });

  group('ChestService - Basic Functionality', () {
    test('Wooden chest returns the configured number of cards', () {
      final result = chestService.openChest(
        chestType: woodenChest,
        currentState: CollectionState.initial(),
        cardRegistry: mockCards,
        collectionRegistry: mockAlbums,
        random: Random(),
      );

      expect(result.rewards.length, 2);
    });

    test('Same card ID never appears twice in one chest', () {
      final manyCardChest = const ChestType(
        id: 'big',
        name: 'Big',
        cardCount: 6,
        guaranteedNewCardCount: 6,
        rarityWeights: {CardRarity.common: 0.5, CardRarity.rare: 0.3, CardRarity.legendary: 0.2},
        baseNewCardChance: 1.0,
        pityIncrement: 1,
        imagePath: '',
      );

      final result = chestService.openChest(
        chestType: manyCardChest,
        currentState: CollectionState.initial(),
        cardRegistry: mockCards,
        collectionRegistry: mockAlbums,
        random: Random(),
      );

      final ids = result.rewards.map((r) => r.card.id).toSet();
      expect(ids.length, 6);
    });

    test('New-card pool never returns an owned card', () {
      final state = CollectionState(ownedCardIds: {'c1', 'c2', 'c3', 'r1', 'r2'}, unlockedCharacterIds: {}, pityCounter: 0);
      final result = chestService.openChest(
        chestType: const ChestType(
          id: 'test',
          name: 'Test',
          cardCount: 1,
          guaranteedNewCardCount: 1,
          rarityWeights: {CardRarity.common: 0.33, CardRarity.rare: 0.33, CardRarity.legendary: 0.33},
          baseNewCardChance: 1.0,
          pityIncrement: 1,
          imagePath: '',
        ),
        currentState: state,
        cardRegistry: mockCards,
        collectionRegistry: mockAlbums,
        random: Random(),
      );

      expect(result.rewards.first.card.id, 'l1');
      expect(result.rewards.first.isNew, true);
    });

    test('Duplicate pool never returns an unowned card', () {
      final state = CollectionState(ownedCardIds: {'c1'}, unlockedCharacterIds: {}, pityCounter: 0);
      final result = chestService.openChest(
        chestType: const ChestType(
          id: 'test',
          name: 'Test',
          cardCount: 1,
          guaranteedNewCardCount: 0,
          rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0},
          baseNewCardChance: 0.0, // Force duplicate
          pityIncrement: 1,
          imagePath: '',
        ),
        currentState: state,
        cardRegistry: mockCards,
        collectionRegistry: mockAlbums,
        random: Random(),
      );

      expect(result.rewards.first.card.id, 'c1');
      expect(result.rewards.first.isNew, false);
    });
  });

  group('ChestService - Rarity & Tokens', () {
    test('Common duplicate grants exactly 10 tokens', () {
      final state = CollectionState(ownedCardIds: {'c1'}, unlockedCharacterIds: {}, pityCounter: 0);
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 0, rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0}, baseNewCardChance: 0.0, pityIncrement: 1, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(),
      );
      expect(result.duplicateTokens, 10);
    });

    test('Rare duplicate grants exactly 50 tokens', () {
      final state = CollectionState(ownedCardIds: {'r1'}, unlockedCharacterIds: {}, pityCounter: 0);
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 0, rarityWeights: {CardRarity.common: 0.0, CardRarity.rare: 1.0, CardRarity.legendary: 0.0}, baseNewCardChance: 0.0, pityIncrement: 1, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(),
      );
      expect(result.duplicateTokens, 50);
    });

    test('Legendary duplicate grants exactly 200 tokens', () {
      final state = CollectionState(ownedCardIds: {'l1'}, unlockedCharacterIds: {}, pityCounter: 0);
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 0, rarityWeights: {CardRarity.common: 0.0, CardRarity.rare: 0.0, CardRarity.legendary: 1.0}, baseNewCardChance: 0.0, pityIncrement: 1, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(),
      );
      expect(result.duplicateTokens, 200);
    });
  });

  group('ChestService - Pity & Probability', () {
    test('Pity increases after duplicate', () {
      final fakeRandom = FakeRandom();
      fakeRandom.nextDoubleValues = [0.99, 0.5, 0.5];

      final state = CollectionState(ownedCardIds: {'c1'}, unlockedCharacterIds: {}, pityCounter: 5);
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 0, rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0}, baseNewCardChance: 0.0, pityIncrement: 2, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: fakeRandom,
      );
      expect(result.rewards.first.isNew, false);
      expect(result.finalPityCounter, 7);
    });

    test('Pity resets after new card', () {
      final fakeRandom = FakeRandom();
      fakeRandom.nextDoubleValues = [0.0, 0.5, 0.5];

      final state = CollectionState(ownedCardIds: {'c1'}, unlockedCharacterIds: {}, pityCounter: 10);
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 0, rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0}, baseNewCardChance: 1.0, pityIncrement: 1, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: fakeRandom,
      );
      expect(result.rewards.first.isNew, true);
      expect(result.finalPityCounter, 0);
    });

    test('Duplicate followed by new card resets final pity to 0', () {
      final fakeRandom = FakeRandom();
      final state = CollectionState(ownedCardIds: {'c1'}, unlockedCharacterIds: {}, pityCounter: 0);
      fakeRandom.nextDoubleValues = [0.9, 0.5, 0.5, 0.05, 0.5, 0.5]; 
      
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 2, guaranteedNewCardCount: 0, rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0}, baseNewCardChance: 0.0, pityIncrement: 2, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: fakeRandom,
      );
      
      expect(result.rewards[0].isNew, false);
      expect(result.rewards[1].isNew, true);
      expect(result.finalPityCounter, 0);
    });

    test('New-card probability is capped at 95%', () {
      final fakeRandom = FakeRandom();
      fakeRandom.nextDoubleValues = [0.94, 0.5, 0.5];

      final state = CollectionState(ownedCardIds: {'c1'}, unlockedCharacterIds: {}, pityCounter: 20);
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 0, rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0}, baseNewCardChance: 0.5, pityIncrement: 1, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: fakeRandom,
      );
      expect(result.rewards.first.isNew, true);

      fakeRandom.nextDoubleValues = [0.96, 0.5, 0.5];
      final result2 = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 0, rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0}, baseNewCardChance: 0.5, pityIncrement: 1, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: fakeRandom,
      );
      expect(result2.rewards.first.isNew, false);
    });
  });

  group('ChestService - Guarantees & Fallbacks', () {
    test('GuaranteedNewCardCount is fully satisfied when enough unowned cards exist', () {
      final state = CollectionState(ownedCardIds: {'c1'}, unlockedCharacterIds: {}, pityCounter: 0);
      final result = chestService.openChest(
        chestType: const ChestType(
          id: 'test', name: 'Test', cardCount: 3, 
          guaranteedNewCardCount: 2, 
          rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0},
          baseNewCardChance: 0.0, 
          pityIncrement: 1,
          imagePath: '',
        ),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(),
      );

      final newCount = result.rewards.where((r) => r.isNew).length;
      expect(newCount, 2);
    });

    test('Empty rolled rarity safely falls back to another rarity', () {
      final state = CollectionState(ownedCardIds: {'c1', 'c2', 'c3', 'r1', 'r2'}, unlockedCharacterIds: {}, pityCounter: 0);
      final result = chestService.openChest(
        chestType: const ChestType(
          id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 1, 
          rarityWeights: {CardRarity.common: 1.0, CardRarity.rare: 0.0, CardRarity.legendary: 0.0}, 
          baseNewCardChance: 1.0, pityIncrement: 1, imagePath: '',
        ),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(),
      );

      expect(result.rewards.first.card.id, 'l1');
    });

    test('Crystal chest fallback when every card is already owned', () {
      final state = CollectionState(
        ownedCardIds: mockCards.map((c) => c.id).toSet(), 
        unlockedCharacterIds: {'set_01'}, 
        pityCounter: 0,
      );
      
      final result = chestService.openChest(
        chestType: const ChestType(id: 'crystal', name: '', cardCount: 3, guaranteedNewCardCount: 1, rarityWeights: {CardRarity.common: 0.0, CardRarity.rare: 0.5, CardRarity.legendary: 0.5}, baseNewCardChance: 1.0, pityIncrement: 0, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(),
      );

      expect(result.rewards.length, 3);
      expect(result.rewards.every((r) => r.isNew == false), true);
    });
  });

  group('ChestService - Collections & Determinism', () {
    test('Completing a collection unlocks character and grants reward once', () {
      final state = CollectionState(ownedCardIds: {'c1', 'c2', 'c3', 'r1', 'r2'}, unlockedCharacterIds: {}, pityCounter: 0);
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 1, rarityWeights: {CardRarity.common: 0.0, CardRarity.rare: 0.0, CardRarity.legendary: 1.0}, baseNewCardChance: 1.0, pityIncrement: 1, imagePath: ''),
        currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(),
      );

      expect(result.completedCollectionIds, {'set_01'});
      expect(result.unlockedCharacterIds, {'set_01'});
      expect(result.completionRewardTokens, 100);
    });

    test('Same seed and same inputs produce exactly same ChestOpenResult', () {
      final state = CollectionState.initial();
      final result1 = chestService.openChest(
        chestType: woodenChest, currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(42),
      );
      final result2 = chestService.openChest(
        chestType: woodenChest, currentState: state, cardRegistry: mockCards, collectionRegistry: mockAlbums, random: Random(42),
      );

      expect(result1.rewards.map((r) => r.card.id).toList(), result2.rewards.map((r) => r.card.id).toList());
      expect(result1.totalGrantedTokens, result2.totalGrantedTokens);
      expect(result1.finalPityCounter, result2.finalPityCounter);
    });

    test('5/6 collection cards have measurably higher selection priority', () {
      final s1 = const AlbumSet(id: 's1', name: 'S1', characterName: '', characterImagePath: '', rewardTokens: 0, themeColor: Colors.red);
      final s2 = const AlbumSet(id: 's2', name: 'S2', characterName: '', characterImagePath: '', rewardTokens: 0, themeColor: Colors.blue);
      
      final l1 = const CollectionCard(id: 'l1', name: 'L1', description: '', rarity: CardRarity.legendary, imagePath: '', collectionId: 's1', setName: 'S1', stars: 3);
      final l2 = const CollectionCard(id: 'l2', name: 'L2', description: '', rarity: CardRarity.legendary, imagePath: '', collectionId: 's2', setName: 'S2', stars: 3);
      
      final albums = [s1, s2];
      
      final state = CollectionState(
        ownedCardIds: {'c1', 'c2', 'c3', 'r1', 'r2'}, 
        unlockedCharacterIds: {},
        pityCounter: 0,
      );
      
      final testCards = [
        const CollectionCard(id: 'c1', name: '', description: '', rarity: CardRarity.common, imagePath: '', collectionId: 's1', setName: '', stars: 1),
        const CollectionCard(id: 'c2', name: '', description: '', rarity: CardRarity.common, imagePath: '', collectionId: 's1', setName: '', stars: 1),
        const CollectionCard(id: 'c3', name: '', description: '', rarity: CardRarity.common, imagePath: '', collectionId: 's1', setName: '', stars: 1),
        const CollectionCard(id: 'r1', name: '', description: '', rarity: CardRarity.rare, imagePath: '', collectionId: 's1', setName: '', stars: 2),
        const CollectionCard(id: 'r2', name: '', description: '', rarity: CardRarity.rare, imagePath: '', collectionId: 's1', setName: '', stars: 2),
        l1,
        l2,
        const CollectionCard(id: 'c4', name: '', description: '', rarity: CardRarity.common, imagePath: '', collectionId: 's2', setName: '', stars: 1),
      ];

      final fakeRandom = FakeRandom();
      fakeRandom.nextDoubleValues = [0.55, 0.5, 0.5]; 
      
      final result = chestService.openChest(
        chestType: const ChestType(id: 't', name: '', cardCount: 1, guaranteedNewCardCount: 1, rarityWeights: {CardRarity.legendary: 1.0}, baseNewCardChance: 1.0, pityIncrement: 1, imagePath: ''),
        currentState: state, cardRegistry: testCards, collectionRegistry: albums, random: fakeRandom,
      );
      
      expect(result.rewards.first.card.id, 'l1');
    });
  });
}
