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

  Future<void> markFlag(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);

    if (key == 'reveal_tutorial_shown') {
      state = state.copyWith(revealTutorialShown: true, isTutorialActive: false);
    } else if (key == 'token_tutorial_shown') {
      state = state.copyWith(tokenTutorialShown: true);
    } else if (key.startsWith('free_')) {
      if (key == 'free_hint_used') state = state.copyWith(freeHintUsed: true);
      if (key == 'free_remove_used') state = state.copyWith(freeRemoveUsed: true);
      if (key == 'free_reveal_used') state = state.copyWith(freeRevealUsed: true);
    }
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

  // --- PREMIUM JOKER GEÇİŞİ ---
  // Bu metod GameNotifier içindeki animasyon tamamlandığında çağrılmalıdır.
  // lib/features/tutorial/providers/tutorial_provider.dart

// lib/features/tutorial/providers/tutorial_provider.dart

  Future<void> nextStepWithDelay({required Duration animationDuration}) async {
    // 1. Spotlight'ı kapat (Animasyon net görünsün)
    state = state.copyWith(isTutorialActive: false);

    // 2. Önce animasyonun bitmesini bekle
    await Future.delayed(animationDuration);

    // 3. İSTEDİĞİN BEKLEME SÜRESİ (1 dakika demişsin ama oyun akışı için
    // şimdilik 5 saniye koyuyorum, istersen 'seconds: 60' yapabilirsin)
    // Bu sürede currentStep hala 'forcedHint' kaldığı için sistem başa sarmaz.
    await Future.delayed(const Duration(milliseconds: 2000)); // <--- Burayı güncelledik
    final steps = TutorialStep.values;
    final currentIndex = steps.indexOf(state.currentStep);

    if (currentIndex < steps.length - 1) {
      final nextStep = steps[currentIndex + 1];

      // 4. EĞER YANLIŞ SİL BİTTİYSE (forcedClear adımı bittiyse)
      if (state.currentStep == TutorialStep.forcedClear) {
        state = state.copyWith(
          isTutorialActive: false,
          currentStep: TutorialStep.completed,
        );
        // Kalıcı olarak bitirildiğini diske yaz
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('tutorial_completed', true);
        return;
      }

      // 5. ŞİMDİ adımı ilerlet ve yeni spotlight'ı aç
      state = state.copyWith(
        currentStep: nextStep,
        isTutorialActive: true,
      );
    }
  }

  void showJokerOnboarding() {
    showHintClearOnboarding();
  }

  void startForcedRevealOnboarding() {
    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.forcedReveal,
      phase: TutorialPhase.contextual,
    );
  }

  Future<void> showHintClearOnboarding() async {
    if (state.hintClearTutorialShown ||
        state.currentStep == TutorialStep.forcedHint ||
        state.currentStep == TutorialStep.forcedClear) {
      return;
    }

    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.forcedHint,
      phase: TutorialPhase.contextual,
      hintClearTutorialShown: true, // <--- Burası çok önemli
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hint_clear_tutorial_shown', true);
  }

  Future<void> startHintJokerTutorial() async {
    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.forcedHint,
      phase: TutorialPhase.contextual,
    );
  }

  Future<void> startJokerOnboarding() async {
    if (state.currentStep == TutorialStep.forcedHint ||
        state.currentStep == TutorialStep.forcedClear) {return;}

    if (state.hintJokerTutorialCompleted &&
        state.removeJokerTutorialCompleted) {return;}

    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.forcedHint,
      phase: TutorialPhase.contextual,
    );
  }


  void completeJokerStep(String key) {
    // 1. ADIM: Arayüzü ANINDA kapat
    state = state.copyWith(isTutorialActive: false);

    if (key == 'hint_joker_tutorial_completed') {
      state = state.copyWith(hintJokerTutorialCompleted: true);
    }
    // YENİ: Tekrar jokeri bayrağını state üzerinde güncelle
    else if (key == 'reveal_tutorial_shown') {
      state = state.copyWith(revealTutorialShown: true);
    }
    else {
      state = state.copyWith(removeJokerTutorialCompleted: true);
    }

    // 2. ADIM: Kalıcı olarak diske kaydet (Burası bir daha çıkmamasını sağlar)
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(key, true);
    });
  }

  void showRevealOnboarding() {
    // Eğer zaten gösterildiyse VEYA şu an zorunlu bir adım aktifse çalışma
    if (state.revealTutorialShown || state.isTutorialActive) {
      return;
    }

    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.forcedReveal,
      phase: TutorialPhase.contextual,
    );
  }

  void startForcedJokerTutorial() {
    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.forcedHint,
      phase: TutorialPhase.contextual,
    );
  }

  void startPhase2Practice() {
    state = state.copyWith(
      currentStep: TutorialStep.phase2Play,
      phase: TutorialPhase.phase2,
    );
  }

  void setTutorialActive(bool active) {
    state = state.copyWith(isTutorialActive: active);
  }

  Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    state = state.copyWith(isTutorialActive: false, currentStep: TutorialStep.completed);

    Future.delayed(const Duration(milliseconds: 1000), () {
      startJokerOnboarding();
    });
  }


  Future<void> showTokenTutorial() async {
    if (state.tokenTutorialShown) return;

    state = state.copyWith(
      isTutorialActive: true,
      currentStep: TutorialStep.tokenInfo,
      phase: TutorialPhase.contextual,
    );

    // Kalıcı olarak kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('token_tutorial_shown', true);
    state = state.copyWith(tokenTutorialShown: true);
  }

  // Tutorial'ı kapat ve oyuna dön
  void closeTokenTutorial() {
    state = state.copyWith(isTutorialActive: false);
  }

}
