import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexmory/features/tutorial/providers/tutorial_provider.dart';
import 'package:lexmory/features/tutorial/models/tutorial_state.dart';
import 'package:lexmory/features/daily_login/providers/daily_login_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TutorialController Onboarding State Machine Tests (Real Async)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('Fresh mandatory onboarding sequence with proper action separation', () async {
      final container = createContainer();
      final tutorialNotifier = container.read(tutorialProvider.notifier);
      
      // Wait for _init to finish
      await tutorialNotifier.initialization;
      
      // Ensure state is clean
      tutorialNotifier.state = tutorialNotifier.state.copyWith(
        isTutorialActive: false,
        isSpotlightPending: false,
        isSpotlightVisible: false,
        isSpotlightTransitioning: false,
        onboardingStep: RealGameOnboardingStep.notStarted,
        tutorialCompleted: false,
      );

      expect(container.read(tutorialProvider).onboardingStep, RealGameOnboardingStep.notStarted);
      expect(container.read(tutorialProvider).isNavigationLocked, false);

      // 1. Complete core tutorial (Gerçek Oyuna Başla)
      await tutorialNotifier.completeTutorial();
      
      expect(container.read(tutorialProvider).onboardingStep, RealGameOnboardingStep.hintJokerPending);
      expect(container.read(tutorialProvider).isNavigationLocked, false); 

      // 2. Start Joker Onboarding (Harf Aç)
      tutorialNotifier.startJokerOnboarding();
      expect(container.read(tutorialProvider).isNavigationLocked, true); // Spotlight pending
      expect(container.read(tutorialProvider).isSpotlightPending, true);

      // Advance 2s for delay in startJokerOnboarding
      await Future.delayed(const Duration(milliseconds: 2100));
      expect(container.read(tutorialProvider).isTutorialActive, true);
      expect(container.read(tutorialProvider).currentStep, TutorialStep.forcedHint);

      // Simulate spotlight mounting
      // Line 59: Pass the required TutorialStep argument
      tutorialNotifier.onSpotlightMounted(TutorialStep.forcedHint);
      expect(container.read(tutorialProvider).isSpotlightVisible, true);
      expect(container.read(tutorialProvider).isNavigationLocked, true);

      // Use Harf Aç Joker
      tutorialNotifier.onHintJokerActionStarted();
      expect(container.read(tutorialProvider).isTutorialActive, false); 
      expect(container.read(tutorialProvider).isSpotlightVisible, false);
      expect(container.read(tutorialProvider).isNavigationLocked, true); // Transition lock

      await tutorialNotifier.onHintJokerActionCompleted();
      await Future.delayed(const Duration(milliseconds: 1600)); // Delay in onHintJokerActionCompleted
      
      // Should advance to next step
      expect(container.read(tutorialProvider).onboardingStep, RealGameOnboardingStep.clearJokerPending);
      expect(container.read(tutorialProvider).isTutorialActive, true);
      expect(container.read(tutorialProvider).isSpotlightPending, true);
      expect(container.read(tutorialProvider).isNavigationLocked, true); 
      expect(container.read(tutorialProvider).currentStep, TutorialStep.forcedClear);

      // 3. Use Yanlışı Sil Joker
      tutorialNotifier.onClearJokerActionStarted();
      expect(container.read(tutorialProvider).isNavigationLocked, true);

      await tutorialNotifier.onClearJokerActionCompleted();
      
      expect(container.read(tutorialProvider).onboardingStep, RealGameOnboardingStep.waitingForFoundButton);
      expect(container.read(tutorialProvider).isNavigationLocked, false); // Unlocked!

      // 4. Trigger Reveal step (Player presses Buldum)
      tutorialNotifier.triggerRevealJokerStep();
      expect(container.read(tutorialProvider).onboardingStep, RealGameOnboardingStep.revealJokerPending);
      expect(container.read(tutorialProvider).isNavigationLocked, true);
      
      // 5. Complete Reveal tutorial
      tutorialNotifier.onRevealJokerActionStarted();
      await tutorialNotifier.onRevealJokerActionCompleted();
      
      expect(container.read(tutorialProvider).onboardingStep, RealGameOnboardingStep.completed);
      expect(container.read(tutorialProvider).onboardingFullyCompleted, true);
      expect(container.read(dailyLoginProvider).activatedOnDate, isNotNull);
    });

    test('Onboarding resumes correctly after restart', () async {
      SharedPreferences.setMockInitialValues({
        'tutorial_completed': true,
        'hint_joker_tutorial_completed': true,
        'real_game_onboarding_step': RealGameOnboardingStep.clearJokerPending.index,
      });

      final container = createContainer();
      final tutorialNotifier = container.read(tutorialProvider.notifier);
      
      await tutorialNotifier.initialization;

      expect(container.read(tutorialProvider).onboardingStep, RealGameOnboardingStep.clearJokerPending);
      expect(container.read(tutorialProvider).isTutorialActive, true);
      expect(container.read(tutorialProvider).currentStep, TutorialStep.forcedClear);
      expect(container.read(tutorialProvider).isNavigationLocked, true);
    });
  });
}
