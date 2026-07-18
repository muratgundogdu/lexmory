import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';
import 'package:lexmory/features/game/repository/game_repository.dart';
import 'package:lexmory/features/game/services/ad_service.dart';
import 'package:lexmory/core/services/game_audio_service.dart';
import 'package:lexmory/features/library/provider/library_provider.dart';
import 'package:lexmory/features/library/provider/collection_provider.dart';
import 'package:lexmory/features/tutorial/providers/tutorial_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_async/fake_async.dart';

class MockGameNotifier extends GameNotifier {
  MockGameNotifier(super.repository, super.adService, super.ref);
  @override void startRegenTimer() {}
  @override Future<void> loadTokens() async {}
  @override Future<void> persist() async {}
  @override Future<void> init() async {}
}

class ManualMockAudioService implements GameAudioService {
  @override Future<void> playBoardTransition() async {}
  @override Future<void> playCardFlip() async {}
  @override Future<void> playRemoveWrongJoker() async {}
  @override Future<void> playWrongTap() async {}
  @override void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Joker Inventory Bug Fix Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'tutorial_completed': true,
        'free_hint_used': true,
        'free_remove_used': true,
        'free_reveal_used': true,
      });
      container = ProviderContainer(
        overrides: [
          gameAudioServiceProvider.overrideWithValue(ManualMockAudioService()),
          gameProvider.overrideWith((ref) => MockGameNotifier(GameRepository(), AdService(), ref)),
        ],
      );
      await container.read(libraryProvider.notifier).initialization;
      await container.read(collectionProvider.notifier).initialization;
      await container.read(tutorialProvider.notifier).initialization;
    });

    test('hintInventory consumption logic', () {
      fakeAsync((fa) {
        final notifier = container.read(gameProvider.notifier);
        
        // Setup state for tutorial category
        notifier.state = notifier.state.copyWith(
          hintInventory: 1,
          category: 'Meyveler',
          foundLetters: List.filled(4, null),
          targetWord: 'ELMA',
          gridLetters: ['E', 'L', 'M', 'A'] + List.filled(12, 'X'),
        );

        notifier.useHint();
        fa.elapse(const Duration(seconds: 2));
        expect(container.read(gameProvider).hintInventory, 1, reason: 'Tutorial category should NOT consume inventory');

        // Setup state for real category
        notifier.state = notifier.state.copyWith(
          hintInventory: 1,
          category: 'Real Games',
          foundLetters: List.filled(4, null),
          targetWord: 'TEST',
          gridLetters: ['T', 'E', 'S', 'T'] + List.filled(12, 'X'),
        );

        container.read(tutorialProvider.notifier).state = container.read(tutorialProvider.notifier).state.copyWith(
          freeHintUsed: true,
        );
        
        notifier.useHint();
        fa.elapse(const Duration(seconds: 2));
        expect(container.read(gameProvider).hintInventory, 0, reason: 'Real game should consume inventory when tutorial freebie is used');
      });
    });

    test('removeWrongInventory consumption logic', () {
      fakeAsync((fa) {
        final notifier = container.read(gameProvider.notifier);
        
        notifier.state = notifier.state.copyWith(
          removeWrongInventory: 1,
          category: 'Real Games',
          targetWord: 'TEST',
          gridLetters: ['T', 'E', 'S', 'T', 'A', 'B', 'C'] + List.filled(9, 'D'),
          eliminatedIndices: [],
        );

        container.read(tutorialProvider.notifier).state = container.read(tutorialProvider.notifier).state.copyWith(
          freeRemoveUsed: true,
        );

        notifier.clearWrong();
        fa.elapse(const Duration(seconds: 2));
        expect(container.read(gameProvider).removeWrongInventory, 0);
      });
    });

    test('Inventory is preserved across resets', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.state = notifier.state.copyWith(hintInventory: 5, removeWrongInventory: 3);
      notifier.resetGame();
      expect(container.read(gameProvider).hintInventory, 5);
      expect(container.read(gameProvider).removeWrongInventory, 3);
    });
  });
}
