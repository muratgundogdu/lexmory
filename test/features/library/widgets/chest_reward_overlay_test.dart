import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexmory/features/library/models/card_rarity.dart';
import 'package:lexmory/features/library/models/chest_open_result.dart';
import 'package:lexmory/features/library/models/card_reward_result.dart';
import 'package:lexmory/features/library/models/collection_card.dart';
import 'package:lexmory/features/library/widgets/chest_reward_overlay.dart';

void main() {
  Widget createOverlay(ChestOpenResult result) {
    return MaterialApp(
      home: ChestRewardOverlay(result: result),
    );
  }

  ChestOpenResult createMockResult(CardRarity rarity, bool isNew) {
    return ChestOpenResult(
      rewards: [
        CardRewardResult(
          card: CollectionCard(
            id: 'test_id',
            name: 'Test Card',
            description: 'Test Description',
            rarity: rarity,
            imagePath: 'lib/assets/cards/bilge_amca/bilge_sapkasi.webp',
            collectionId: 'set_01',
            setName: 'Test Set',
            stars: 1,
          ),
          isNew: isNew,
          duplicateTokenValue: rarity.duplicateTokenValue,
        ),
      ],
      completedCollectionIds: {},
      unlockedCharacterIds: {},
      totalGrantedTokens: 0,
      completionRewardTokens: 0,
      duplicateTokens: isNew ? 0 : rarity.duplicateTokenValue,
      finalPityCounter: 0,
    );
  }

  group('ChestRewardOverlay Rarity Presentation Tests', () {
    testWidgets('Common reward does not render rarity text', (tester) async {
      final result = createMockResult(CardRarity.common, true);
      await tester.pumpWidget(createOverlay(result));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('COMMON'), findsNothing);
      expect(find.text('Normal'), findsNothing);
      expect(find.text('Test Card'), findsOneWidget);
      expect(find.text('Test Set'), findsOneWidget);
    });

    testWidgets('Rare reward does not render rarity text', (tester) async {
      final result = createMockResult(CardRarity.rare, true);
      await tester.pumpWidget(createOverlay(result));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('RARE'), findsNothing);
      expect(find.text('Nadir'), findsNothing);
      expect(find.text('Test Card'), findsOneWidget);
    });

    testWidgets('Legendary reward does not render rarity text and shows sparkles', (tester) async {
      final result = createMockResult(CardRarity.legendary, true);
      await tester.pumpWidget(createOverlay(result));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('LEGENDARY'), findsNothing);
      expect(find.text('Efsanevi'), findsNothing);
      expect(find.text('Test Card'), findsOneWidget);
      
      // Sparkle icons (auto_awesome_rounded)
      expect(find.byIcon(Icons.auto_awesome_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('NEW badge is visible', (tester) async {
      final result = createMockResult(CardRarity.common, true);
      await tester.pumpWidget(createOverlay(result));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('YENİ'), findsOneWidget);
    });

    testWidgets('Duplicate badge is visible with token amount', (tester) async {
      final result = createMockResult(CardRarity.rare, false);
      await tester.pumpWidget(createOverlay(result));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('KOPYA'), findsNothing);
      expect(find.textContaining('+50'), findsOneWidget);
    });
  });
}
