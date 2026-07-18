import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/game/widgets/category_complete_overlay.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';
import 'package:lexmory/features/game/models/game_state.dart';
import 'package:lexmory/features/library/models/chest_open_result.dart';
import 'package:lexmory/features/library/models/card_reward_result.dart';
import 'package:lexmory/features/library/models/collection_card.dart';
import 'package:lexmory/features/library/models/card_rarity.dart';
import 'package:lexmory/features/game/repository/game_repository.dart';
import 'package:lexmory/features/game/services/ad_service.dart';

// Mock GameNotifier
class MockGameNotifier extends GameNotifier {
  MockGameNotifier(Ref ref, GameState initialState) : super(GameRepository(), AdService(), ref) {
    state = initialState;
  }

  @override
  Future<void> loadTokens() async {}

  @override
  Future<void> doubleRewardWithAd() async {}
}

void main() {
  testWidgets('CategoryCompleteOverlay shows reward gallery correctly', (tester) async {
    final reward1 = CardRewardResult(
      card: const CollectionCard(
        id: 'c1',
        name: 'Test Card 1',
        description: 'Desc 1',
        rarity: CardRarity.common,
        imagePath: 'assets/test1.png',
        collectionId: 'col1',
        setName: 'Collection A',
        stars: 1,
      ),
      isNew: true,
      duplicateTokenValue: 0,
    );

    final reward2 = CardRewardResult(
      card: const CollectionCard(
        id: 'c2',
        name: 'Test Card 2',
        description: 'Desc 2',
        rarity: CardRarity.legendary,
        imagePath: 'assets/test2.png',
        collectionId: 'col2',
        setName: 'Collection B',
        stars: 3,
      ),
      isNew: false,
      duplicateTokenValue: 200,
    );

    final chestResult = ChestOpenResult(
      rewards: [reward1, reward2],
      duplicateTokens: 200,
      completionRewardTokens: 0,
      totalGrantedTokens: 200,
      completedCollectionIds: {},
      unlockedCharacterIds: {},
      finalPityCounter: 0,
    );

    final initialState = GameState(
      category: 'Test',
      targetWord: 'TEST',
      gridLetters: [],
      selectedIndices: [],
      foundLetters: [],
      isInitialReveal: false,
      hasStarted: true,
      tokens: 100,
      completedCategories: [],
      currentWordIndex: 0,
      eliminatedIndices: [],
      wrongAttemptsCount: 0,
      jokersUsedCount: 0,
      streak: 0,
      showVictoryPanel: false,
      lastRewardTotal: 0,
      showCategoryCompletePanel: true,
      totalCategoryWrongCount: 5,
      totalCategoryJokersCount: 2,
      showGameFinishedPanel: false,
      totalSolvedWords: 10,
      totalEarnedTokens: 1000,
      showOutOfTokensPanel: false,
      isOutOfTokensDismissible: false,
      lastRegenTime: DateTime.now(),
      categoryRewardResult: chestResult,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameProvider.overrideWith((ref) => MockGameNotifier(ref, initialState)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CategoryCompleteOverlay(
              isVisible: true,
              categoryName: 'Test',
              totalWrong: 5,
              totalJokers: 2,
              sectionCount: 1,
              onContinue: () {},
            ),
          ),
        ),
      ),
    );

    // Pump enough to finish animations
    await tester.pump(const Duration(seconds: 2));

    // Verify Header
    expect(find.text('KATEGORİ TAMAMLANDI'), findsOneWidget);
    expect(find.text('KOLEKSİYON ÖDÜLLERİ'), findsOneWidget);
    expect(find.text('KÜTÜPHANENE EKLENDİ'), findsNothing);

    // Verify Rewards
    expect(find.text('Test Card 1'), findsOneWidget);
    expect(find.text('Collection A'), findsOneWidget);
    expect(find.text('YENİ'), findsOneWidget);

    expect(find.text('Test Card 2'), findsOneWidget);
    expect(find.text('Collection B'), findsOneWidget);
    expect(find.text('+200'), findsOneWidget);

    // Verify Stats
    expect(find.text('5'), findsOneWidget); // HATA
    expect(find.text('2'), findsOneWidget); // JOKER
    expect(find.text('1'), findsOneWidget); // BÖLÜM

    // Verify Token Reward
    expect(find.text('+150 TOKEN KAZANILDI'), findsOneWidget);
  });

  testWidgets('CategoryCompleteOverlay handles empty rewards safely', (tester) async {
    final initialState = GameState(
      category: 'Test',
      targetWord: 'TEST',
      gridLetters: [],
      selectedIndices: [],
      foundLetters: [],
      isInitialReveal: false,
      hasStarted: true,
      tokens: 100,
      completedCategories: [],
      currentWordIndex: 0,
      eliminatedIndices: [],
      wrongAttemptsCount: 0,
      jokersUsedCount: 0,
      streak: 0,
      showVictoryPanel: false,
      lastRewardTotal: 0,
      showCategoryCompletePanel: true,
      totalCategoryWrongCount: 0,
      totalCategoryJokersCount: 0,
      showGameFinishedPanel: false,
      totalSolvedWords: 0,
      totalEarnedTokens: 0,
      showOutOfTokensPanel: false,
      isOutOfTokensDismissible: false,
      lastRegenTime: DateTime.now(),
      categoryRewardResult: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameProvider.overrideWith((ref) => MockGameNotifier(ref, initialState)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CategoryCompleteOverlay(
              isVisible: true,
              categoryName: 'Test',
              totalWrong: 0,
              totalJokers: 0,
              sectionCount: 1,
              onContinue: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Koleksiyon ödülü gösterilemedi.'), findsOneWidget);
  });
}
