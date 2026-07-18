import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';
import 'package:lexmory/features/game/repository/game_repository.dart';
import 'package:lexmory/features/game/services/ad_service.dart';
import 'package:lexmory/core/services/game_audio_service.dart';
import 'package:lexmory/features/library/provider/library_provider.dart';
import 'package:lexmory/features/library/provider/collection_provider.dart';
import 'package:lexmory/features/tutorial/providers/tutorial_provider.dart';
import 'package:lexmory/features/tutorial/models/tutorial_state.dart';
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

  group('Reveal Tutorial Fix Tests', () {
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

    test('showAgain bypasses tutorialLock when forced in tutorial', () {
      fakeAsync((fa) {
        final notifier = container.read(gameProvider.notifier);
        final tutorialNotifier = container.read(tutorialProvider.notifier);
        
        tutorialNotifier.state = tutorialNotifier.state.copyWith(
          currentStep: TutorialStep.forcedReveal,
          isTutorialActive: true,
        );

        notifier.state = notifier.state.copyWith(
          tutorialLock: true,
          tokens: 0, 
          category: 'Real Games',
        );

        notifier.showAgain();
        fa.flushMicrotasks();
        
        expect(notifier.state.isInitialReveal, true, reason: 'Should have started reveal');
        
        fa.elapse(const Duration(seconds: 6));
        
        expect(notifier.state.tutorialLock, false, reason: 'tutorialLock should be cleared after forced reveal');
        expect(notifier.state.tokens, 0, reason: 'Forced reveal should cost 0 tokens');
      });
    });

    test('showAgain is blocked by tutorialLock when NOT forced', () {
      fakeAsync((fa) {
        final notifier = container.read(gameProvider.notifier);
        final tutorialNotifier = container.read(tutorialProvider.notifier);
        
        tutorialNotifier.state = tutorialNotifier.state.copyWith(
          currentStep: TutorialStep.category,
          isTutorialActive: false,
        );

        notifier.state = notifier.state.copyWith(
          tutorialLock: true,
          tokens: 100,
          isInitialReveal: false,
        );

        notifier.showAgain();
        fa.flushMicrotasks();
        
        expect(notifier.state.tutorialLock, true, reason: 'tutorialLock should STILL be true if not forced');
        expect(notifier.state.isInitialReveal, false, reason: 'Action should not have run');
      });
    });

    test('showAgain consumes no inventory ever', () {
      fakeAsync((fa) {
        final notifier = container.read(gameProvider.notifier);
        container.read(tutorialProvider.notifier).state = container.read(tutorialProvider.notifier).state.copyWith(
          freeRevealUsed: true,
        );
        notifier.state = notifier.state.copyWith(tokens: 100, category: 'Real Games');
        
        notifier.showAgain();
        fa.flushMicrotasks();
        
        expect(notifier.state.tokens, 60, reason: 'Normal showAgain costs 40');
      });
    });
  });
}
