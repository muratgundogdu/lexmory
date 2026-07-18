import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../daily_login/providers/daily_login_provider.dart';
import '../models/tutorial_state.dart';

final tutorialProvider = StateNotifierProvider<TutorialController, TutorialState>((ref) {
  return TutorialController(ref);
});

class TutorialController extends StateNotifier<TutorialState> {
  final Ref _ref;

  @visibleForTesting
  late Future<void> initialization;

  TutorialController(this._ref) : super(TutorialState(
      currentStep: TutorialStep.category,
      phase: TutorialPhase.phase1,
      isTutorialActive: false
  )) {
    initialization = _init();
  }

  // --- HARF SEÇİMİ SONRASI SPOTLIGHT AKIŞI ---
  Future<void> handleLetterSuccessFlow() async {
    state = state.copyWith(currentStep: TutorialStep.wordBoxes);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (state.currentStep == TutorialStep.wordBoxes) {
      state = state.copyWith(currentStep: TutorialStep.findingLetters);
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;
    
    // Flags
    final freeHintUsed = prefs.getBool('free_hint_used') ?? false;
    final freeRemoveUsed = prefs.getBool('free_remove_used') ?? false;
    final freeRevealUsed = prefs.getBool('free_reveal_used') ?? false;
    final tokenTutorialShown = prefs.getBool('token_tutorial_shown') ?? false;
    final jokerTutorialShown = prefs.getBool('joker_tutorial_shown') ?? false;
    final hintClearTutorialShown = prefs.getBool('hint_clear_tutorial_shown') ?? false;
    final revealTutorialShown = prefs.getBool('reveal_tutorial_shown') ?? false;
    final hintJokerTutorialCompleted = prefs.getBool('hint_joker_tutorial_completed') ?? false;
    final removeJokerTutorialCompleted = prefs.getBool('remove_joker_tutorial_completed') ?? false;

    // Determine Onboarding Step (with migration)
    RealGameOnboardingStep onboardingStep = RealGameOnboardingStep.notStarted;
    final savedStepIndex = prefs.getInt('real_game_onboarding_step');
    
    if (savedStepIndex != null) {
      onboardingStep = RealGameOnboardingStep.values[savedStepIndex];
    } else {
      // Migration logic
      if (revealTutorialShown) {
        onboardingStep = RealGameOnboardingStep.completed;
      } else if (hintClearTutorialShown) {
        onboardingStep = RealGameOnboardingStep.waitingForFoundButton;
      } else if (hintJokerTutorialCompleted) {
        onboardingStep = RealGameOnboardingStep.clearJokerPending;
      } else if (tutorialCompleted) {
        onboardingStep = RealGameOnboardingStep.hintJokerPending;
      }
    }

    // Auto-resume if in a tutorial step
    bool isTutorialActive = !tutorialCompleted;
    TutorialStep currentStep = TutorialStep.category;
    TutorialPhase phase = tutorialCompleted ? TutorialPhase.contextual : TutorialPhase.phase1;

    if (onboardingStep == RealGameOnboardingStep.revealJokerPending) {
      isTutorialActive = true;
      currentStep = TutorialStep.forcedReveal;
    } else if (onboardingStep == RealGameOnboardingStep.clearJokerPending) {
      isTutorialActive = true;
      currentStep = TutorialStep.forcedClear;
    } else if (onboardingStep == RealGameOnboardingStep.hintJokerPending) {
       if (tutorialCompleted) {
         isTutorialActive = true;
         currentStep = TutorialStep.forcedHint;
       }
    }

    final isSpotlightPending = isTutorialActive && _isSpotlightStep(currentStep);

    state = state.copyWith(
      isTutorialActive: isTutorialActive,
      currentStep: currentStep,
      tutorialCompleted: tutorialCompleted,
      onboardingStep: onboardingStep,
      phase: phase,
      freeHintUsed: freeHintUsed,
      freeRemoveUsed: freeRemoveUsed,
      freeRevealUsed: freeRevealUsed,
      tokenTutorialShown: tokenTutorialShown,
      jokerTutorialShown: jokerTutorialShown,
      hintClearTutorialShown: hintClearTutorialShown,
      revealTutorialShown: revealTutorialShown,
      hintJokerTutorialCompleted: hintJokerTutorialCompleted,
      removeJokerTutorialCompleted: removeJokerTutorialCompleted,
      isSpotlightPending: isSpotlightPending,
      requiredTabIndex: isSpotlightPending ? 0 : null,
    );
  }

  bool _isSpotlightStep(TutorialStep step) {
    switch (step) {
      case TutorialStep.category:
      case TutorialStep.wordBoxes:
      case TutorialStep.grid:
      case TutorialStep.startButton:
      case TutorialStep.forcedHint:
      case TutorialStep.forcedClear:
      case TutorialStep.forcedReveal:
      case TutorialStep.tokenInfo:
        return true;
      default:
        return false;
    }
  }

  void onSpotlightMounted(TutorialStep step) {
    if (state.currentStep != step) return;
    if (state.isSpotlightVisible && !state.isSpotlightPending) return;

    if (state.isSpotlightPending) {
      state = state.copyWith(isSpotlightPending: false, isSpotlightVisible: true);
    }
  }

  void startJokerOnboarding() {
    if (state.onboardingStep != RealGameOnboardingStep.hintJokerPending || state.isTutorialActive) return;

    state = state.copyWith(isSpotlightPending: true, requiredTabIndex: 0);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      state = state.copyWith(
        isTutorialActive: true,
        currentStep: TutorialStep.forcedHint,
        phase: TutorialPhase.contextual,
      );
    });
  }

  // --- MANDATORY JOKER TRANSITIONS ---

  void onHintJokerActionStarted() {
    state = state.copyWith(
      isTutorialActive: false, 
      isSpotlightVisible: false,
      isSpotlightTransitioning: true,
    );
  }

  Future<void> onHintJokerActionCompleted() async {
    state = state.copyWith(
      hintJokerTutorialCompleted: true,
    );
    await _saveToPrefs('hint_joker_tutorial_completed', true);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    state = state.copyWith(
      onboardingStep: RealGameOnboardingStep.clearJokerPending,
      currentStep: TutorialStep.forcedClear,
      isTutorialActive: true,
      isSpotlightPending: true,
      isSpotlightTransitioning: false,
      requiredTabIndex: 0,
    );
    await _saveStepToPrefs(RealGameOnboardingStep.clearJokerPending);
  }

  void onClearJokerActionStarted() {
    state = state.copyWith(
      isTutorialActive: false,
      isSpotlightVisible: false,
      isSpotlightTransitioning: true,
    );
  }

  Future<void> onClearJokerActionCompleted() async {
    state = state.copyWith(
      hintClearTutorialShown: true,
      removeJokerTutorialCompleted: true,
      onboardingStep: RealGameOnboardingStep.waitingForFoundButton,
      isTutorialActive: false,
      isSpotlightPending: false,
      isSpotlightVisible: false,
      isSpotlightTransitioning: false,
      requiredTabIndex: null,
    );
    await _saveToPrefs('hint_clear_tutorial_shown', true);
    await _saveToPrefs('remove_joker_tutorial_completed', true);
    await _saveStepToPrefs(RealGameOnboardingStep.waitingForFoundButton);
  }

  void triggerRevealJokerStep() {
    if (state.onboardingStep == RealGameOnboardingStep.waitingForFoundButton) {
      state = state.copyWith(
        onboardingStep: RealGameOnboardingStep.revealJokerPending,
        currentStep: TutorialStep.forcedReveal,
        isTutorialActive: true,
        isSpotlightPending: true,
        requiredTabIndex: 0,
      );
      _saveStepToPrefs(RealGameOnboardingStep.revealJokerPending);
    }
  }

  void onRevealJokerActionStarted() {
    state = state.copyWith(
      isTutorialActive: false,
      isSpotlightVisible: false,
      isSpotlightTransitioning: true,
    );
  }

  Future<void> onRevealJokerActionCompleted() async {
    state = state.copyWith(
      revealTutorialShown: true,
      onboardingStep: RealGameOnboardingStep.completed,
      isTutorialActive: false,
      isSpotlightPending: false,
      isSpotlightVisible: false,
      isSpotlightTransitioning: false,
      requiredTabIndex: null,
    );
    await _saveToPrefs('reveal_tutorial_shown', true);
    await _saveStepToPrefs(RealGameOnboardingStep.completed);
    _checkOnboardingActivation();
  }

  // --- LEGACY ADIM GEÇİŞ MANTIĞI (For Core Tutorial) ---
  void nextStep() {
    if (state.currentStep == TutorialStep.phase2Play) {
      state = state.copyWith(currentStep: TutorialStep.completed);
      return;
    }

    final steps = TutorialStep.values;
    final currentIndex = steps.indexOf(state.currentStep);

    if (currentIndex < steps.length - 1) {
      final nextStep = steps[currentIndex + 1];
      TutorialPhase nextPhase = state.phase;

      if (nextStep == TutorialStep.phase2Intro) {
        nextPhase = TutorialPhase.phase2;
      }

      state = state.copyWith(
        currentStep: nextStep,
        phase: nextPhase,
        isSpotlightPending: _isSpotlightStep(nextStep),
        isSpotlightVisible: false,
        requiredTabIndex: _isSpotlightStep(nextStep) ? 0 : null,
      );
    }
  }

  void startPhase2Practice() {
    state = state.copyWith(
      currentStep: TutorialStep.phase2Play,
      phase: TutorialPhase.phase2,
      isTutorialActive: true,
      isSpotlightPending: false,
      isSpotlightVisible: false,
      requiredTabIndex: null,
    );
  }

  Future<void> completeTutorial() async {
    state = state.copyWith(
      isTutorialActive: false, 
      currentStep: TutorialStep.completed, 
      tutorialCompleted: true,
      onboardingStep: RealGameOnboardingStep.hintJokerPending,
      phase: TutorialPhase.contextual,
      isSpotlightPending: false,
      isSpotlightVisible: false,
      isSpotlightTransitioning: false,
      requiredTabIndex: null,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    await _saveStepToPrefs(RealGameOnboardingStep.hintJokerPending);
    _checkOnboardingActivation();
  }

  Future<void> showTokenTutorial() async {
    if (state.tokenTutorialShown) return;
    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.tokenInfo,
      phase: TutorialPhase.contextual,
      tokenTutorialShown: true,
      isSpotlightPending: true,
      requiredTabIndex: 0,
    );
    await _saveToPrefs('token_tutorial_shown', true);
    _checkOnboardingActivation();
  }

  void closeTokenTutorial() {
    state = state.copyWith(
      isTutorialActive: false, 
      isSpotlightPending: false,
      isSpotlightVisible: false,
      isSpotlightTransitioning: false,
      requiredTabIndex: null,
    );
    _checkOnboardingActivation();
  }

  void _checkOnboardingActivation() {
    if (state.onboardingFullyCompleted) {
      _ref.read(dailyLoginProvider.notifier).activateAfterOnboarding();
    }
  }

  Future<void> _saveToPrefs(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStepToPrefs(RealGameOnboardingStep step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('real_game_onboarding_step', step.index);
  }

  void markFlag(String key) {
    if (key == 'free_hint_used') state = state.copyWith(freeHintUsed: true);
    if (key == 'free_remove_used') state = state.copyWith(freeRemoveUsed: true);
    if (key == 'free_reveal_used') state = state.copyWith(freeRevealUsed: true);
    _saveToPrefs(key, true);
  }
}
