import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_state.dart';

final tutorialProvider = StateNotifierProvider<TutorialController, TutorialState>((ref) {
  return TutorialController();
});

class TutorialController extends StateNotifier<TutorialState> {
  TutorialController() : super(TutorialState(
      currentStep: TutorialStep.category,
      phase: TutorialPhase.phase1,
      isTutorialActive: false
  )) {
    _init();
  }

  // --- HARF SEÇİMİ SONRASI SPOTLIGHT AKIŞI ---
  Future<void> handleLetterSuccessFlow() async {
    // 1. Spotlight'ı kelime alanına (WordBoxes) kaydır
    state = state.copyWith(currentStep: TutorialStep.wordBoxes);

    // 2. Oyuncunun harfin yerine yerleştiğini görmesi için 1.5 saniye bekle
    await Future.delayed(const Duration(milliseconds: 1500));

    // 3. Eğer kelime bitmediyse tekrar "Harf Bulma" adımına dön
    if (state.currentStep == TutorialStep.wordBoxes) {
      state = state.copyWith(currentStep: TutorialStep.findingLetters);
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      isTutorialActive: !(prefs.getBool('tutorial_completed') ?? false),
      freeHintUsed: prefs.getBool('free_hint_used') ?? false,
      freeRemoveUsed: prefs.getBool('free_remove_used') ?? false,
      freeRevealUsed: prefs.getBool('free_reveal_used') ?? false,
      tokenTutorialShown: prefs.getBool('token_tutorial_shown') ?? false,
      jokerTutorialShown: prefs.getBool('joker_tutorial_shown') ?? false,
      hintClearTutorialShown: prefs.getBool('hint_clear_tutorial_shown') ?? false,
      revealTutorialShown: prefs.getBool('reveal_tutorial_shown') ?? false,
      hintJokerTutorialCompleted: prefs.getBool('hint_joker_tutorial_completed') ?? false,
      removeJokerTutorialCompleted: prefs.getBool('remove_joker_tutorial_completed') ?? false,
    );
  }

  // --- JOKER SERİSİ BAŞLATMA (HARF AÇ) ---
  void showJokerOnboarding() {
    if (state.hintClearTutorialShown || state.isTutorialActive) return;

    // --- DÜZELTME: 2 Saniye Gecikme ---
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      state = state.copyWith(
        isTutorialActive: true,
        currentStep: TutorialStep.forcedHint,
        phase: TutorialPhase.contextual,
      );
    });
  }

  // --- JOKER TANITIMINI TETİKLE (GAME SCREEN'DEN ÇAĞRILIR) ---
  void startJokerOnboarding() {
    // Eğer zaten tanıtıldıysa veya aktifse çalışma
    if (state.hintClearTutorialShown || state.isTutorialActive) return;

    // --- KRİTİK DÜZELTME: 2 Saniye Gecikme ---
    // Bu sayede oyuncu yeni gelen kategoriyi ve harfleri net bir şekilde görür
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      state = state.copyWith(
        isTutorialActive: true,
        currentStep: TutorialStep.forcedHint,
        phase: TutorialPhase.contextual,
      );
    });
  }

  // --- ADIM GEÇİŞ MANTIĞI (GECİKMELİ) ---
  Future<void> nextStepWithDelay({required Duration animationDuration}) async {
    await Future.delayed(animationDuration);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    if (state.currentStep == TutorialStep.forcedHint) {
      state = state.copyWith(
        currentStep: TutorialStep.forcedClear,
        isTutorialActive: true,
      );
    }
    else if (state.currentStep == TutorialStep.forcedClear) {
      state = state.copyWith(
        isTutorialActive: false,
        hintClearTutorialShown: true,
      );
      _saveToPrefs('hint_clear_tutorial_shown', true);
    }
  }

  // --- TEKRAR JOKERİ TANITIMI ---
  void startForcedRevealOnboarding() {
    if (state.revealTutorialShown || state.isTutorialActive) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      state = state.copyWith(
        isTutorialActive: true,
        currentStep: TutorialStep.forcedReveal,
        phase: TutorialPhase.contextual,
      );
    });
  }

  // --- JOKER ADIMINI TAMAMLA VE KAYDET ---
  void completeJokerStep(String key) {
    state = state.copyWith(isTutorialActive: false);

    if (key == 'hint_joker_tutorial_completed') {
      state = state.copyWith(hintJokerTutorialCompleted: true);
    } else if (key == 'remove_joker_tutorial_completed') {
      state = state.copyWith(removeJokerTutorialCompleted: true);
    } else if (key == 'reveal_tutorial_shown') {
      state = state.copyWith(revealTutorialShown: true);
    }

    _saveToPrefs(key, true);
  }

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
      );
    }
  }

  void startPhase2Practice() {
    state = state.copyWith(
      currentStep: TutorialStep.phase2Play,
      phase: TutorialPhase.phase2,
      isTutorialActive: true,
    );
  }

  Future<void> completeTutorial() async {
    state = state.copyWith(isTutorialActive: false, currentStep: TutorialStep.completed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  Future<void> showTokenTutorial() async {
    if (state.tokenTutorialShown) return;
    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.tokenInfo,
      phase: TutorialPhase.contextual,
      tokenTutorialShown: true,
    );
    _saveToPrefs('token_tutorial_shown', true);
  }

  void closeTokenTutorial() {
    state = state.copyWith(isTutorialActive: false);
  }

  Future<void> _saveToPrefs(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void markFlag(String key) {
    if (key == 'free_hint_used') state = state.copyWith(freeHintUsed: true);
    if (key == 'free_remove_used') state = state.copyWith(freeRemoveUsed: true);
    if (key == 'free_reveal_used') state = state.copyWith(freeRevealUsed: true);
    _saveToPrefs(key, true);
  }
}