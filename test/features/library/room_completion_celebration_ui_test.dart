import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/library/screens/room_completion_celebration_screen.dart';
import 'package:lexmory/features/library/models/room_completion_reward_result.dart';
import 'package:lexmory/features/library/models/chest_open_result.dart';
import 'package:lexmory/features/library/models/card_reward_result.dart';
import 'package:lexmory/features/library/models/collection_card.dart';
import 'package:lexmory/features/library/models/card_rarity.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';
import 'package:lexmory/features/game/repository/game_repository.dart';
import 'package:lexmory/features/game/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGameNotifier extends GameNotifier {
  MockGameNotifier(super.repository, super.adService, super.ref);
  @override void startRegenTimer() {}
  @override Future<void> loadTokens() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createCelebrationScreen(RoomCompletionRewardResult result) {
    return ProviderScope(
      overrides: [
        gameProvider.overrideWith((ref) => MockGameNotifier(GameRepository(), AdService(), ref)),
      ],
      child: MaterialApp(
        home: RoomCompletionCelebrationScreen(result: result),
      ),
    );
  }

  final fakeCard = CollectionCard(
    id: 'card_1',
    name: 'Test Card',
    setName: 'Test Set',
    imagePath: 'lib/assets/images/placeholder.png',
    rarity: CardRarity.common,
    description: 'Test',
    collectionId: 'set_1',
    stars: 1,
  );

  final resultWithOneCard = RoomCompletionRewardResult(
    roomId: 'room_01',
    roomName: 'Test Room',
    tokenReward: 500,
    hintReward: 1,
    removeWrongReward: 1,
    chestTypeId: 'gold',
    chestResult: ChestOpenResult(
      rewards: [
        CardRewardResult(card: fakeCard, isNew: true, duplicateTokenValue: 0),
      ],
      duplicateTokens: 0,
      completionRewardTokens: 0,
      totalGrantedTokens: 0,
      completedCollectionIds: {},
      unlockedCharacterIds: {},
      finalPityCounter: 0,
    ),
  );

  testWidgets('Summary shows all rewards after automatic transitions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(createCelebrationScreen(resultWithOneCard));

    // Initially in roomTitle phase
    expect(find.text('ODA TAMAMLANDI'), findsOneWidget);

    // Skip all transitions
    await tester.pump(const Duration(seconds: 20));
    // Additional pumps to handle staggers and frames
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Verify Summary
    expect(find.text('TEBRİKLER!'), findsOneWidget);
    expect(find.text('TOKEN'), findsOneWidget);
    expect(find.text('+500'), findsOneWidget);
    
    // Verify collection card exists by finding the card name
    expect(find.text('Test Card'), findsOneWidget);

    // Verify Final Buttons
    expect(find.text('YENİ ODAYI AÇ'), findsOneWidget);
    expect(find.text('KÜTÜPHANEYİ İNCELE'), findsNothing);
  });

  testWidgets('Final room shows different button text', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    final finalRoomResult = RoomCompletionRewardResult(
      roomId: 'room_15', 
      roomName: 'Final Room',
      tokenReward: 1000,
      hintReward: 5,
      removeWrongReward: 5,
      chestTypeId: 'legendary',
      chestResult: ChestOpenResult(
        rewards: [],
        duplicateTokens: 0,
        completionRewardTokens: 0,
        totalGrantedTokens: 0,
        completedCollectionIds: {},
        unlockedCharacterIds: {},
        finalPityCounter: 0,
      ),
    );

    await tester.pumpWidget(createCelebrationScreen(finalRoomResult));
    await tester.pump(const Duration(seconds: 15));
    // No pumpAndSettle due to background animations
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('TÜM ODALARI TAMAMLADIN'), findsOneWidget);
    expect(find.text('KÜTÜPHANEYE DÖN'), findsOneWidget);
    expect(find.text('KÜTÜPHANEYİ İNCELE'), findsNothing);
  });

  testWidgets('Responsive grid handles 2 cards', (WidgetTester tester) async {
    final resultTwoCards = RoomCompletionRewardResult(
      roomId: 'room_01',
      roomName: 'Test Room',
      tokenReward: 500,
      hintReward: 1,
      removeWrongReward: 1,
      chestTypeId: 'gold',
      chestResult: ChestOpenResult(
        rewards: [
          CardRewardResult(card: fakeCard, isNew: true, duplicateTokenValue: 0),
          CardRewardResult(card: fakeCard.copyWith(id: 'card_2', name: 'Card 2'), isNew: false, duplicateTokenValue: 100),
        ],
        duplicateTokens: 100,
        completionRewardTokens: 0,
        totalGrantedTokens: 100,
        completedCollectionIds: {},
        unlockedCharacterIds: {},
        finalPityCounter: 0,
      ),
    );

    await tester.pumpWidget(createCelebrationScreen(resultTwoCards));
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Test Card'), findsOneWidget);
    expect(find.text('Card 2'), findsOneWidget);
    expect(find.textContaining('100'), findsOneWidget);
  });
}
