import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/game_state.dart';
import '../../game/providers/game_provider.dart';
import '../../game/view/game_screen.dart';
import '../../library/view/library_screen.dart';
import '../../store/view/store_screen.dart';
import '../../settings/view/settings_screen.dart';
import '../../tutorial/models/tutorial_state.dart' hide TutorialKeys;
import '../../tutorial/models/tutorial_keys.dart'; // Merkezi Key dosyası eklendi
import '../providers/navigation_provider.dart';
import '../widgets/lex_bottom_nav.dart';
import '../../tutorial/providers/tutorial_provider.dart';
import '../../tutorial/widgets/tutorial_overlay.dart';
import '../../tutorial/widgets/tutorial_phase2_intro.dart';
import '../../tutorial/widgets/tutorial_success_overlay.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final tutorial = ref.watch(tutorialProvider);
    final game = ref.watch(gameProvider);

    final List<Widget> screens = [
      const GameScreen(),
      const LibraryScreen(),
      const StoreScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: currentIndex, children: screens),

          // Alt Navigasyon Bar
          const Align(
            alignment: Alignment.bottomCenter,
            child: LexBottomNav(),
          ),

          // --- TUTORIAL OVERLAY (EN ÜST KATMAN) ---
          if (tutorial.isTutorialActive)
            _buildGlobalTutorialStep(ref, tutorial, game),
        ],
      ),
    );
  }

  Widget _buildGlobalTutorialStep(WidgetRef ref, TutorialState tutorialState, GameState game) {
    final notifier = ref.read(tutorialProvider.notifier);
    final step = tutorialState.currentStep;

    switch (step) {
      case TutorialStep.category:
        return TutorialOverlay(
          targetKey: TutorialKeys.categoryKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Her bölümde bir kategori görürsün.\nKategori sana kelime hakkında ipucu verir.",
          onNext: () => notifier.nextStep(),
        );

      case TutorialStep.wordBoxes:
      // Eğer harf seçiminden sonra buraya kaydıysak (handleLetterSuccessFlow çalıştıysa)
        String flowText = "Bulman gereken kelime burada yer alır.";

        if (tutorialState.phase == TutorialPhase.phase1 && game.hasStarted) {
          flowText = "Harika! ✨\nHarf ait olduğu yere yerleşti. Devam edelim...";
        }

        return TutorialOverlay(
          targetKey: TutorialKeys.wordAreaKey,
          currentStep: step,
          isInitialPhase: true,
          text: flowText,
          onNext: () => notifier.nextStep(),
        );

      case TutorialStep.grid:
        return TutorialOverlay(
          targetKey: TutorialKeys.gridKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Harfleri dikkatlice incele.\nBirazdan hepsi kapanacak.",
          onNext: () => notifier.nextStep(),
        );

      case TutorialStep.startButton:
        return TutorialOverlay(
          targetKey: TutorialKeys.startButtonKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Hazırsan BULDUM butonuna bas ve başla!",
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.findingLetters:
      // Eğer Phase 2'deysek (Sıra Sende) overlay gösterme
        if (tutorialState.phase == TutorialPhase.phase2) return const SizedBox.shrink();

        final int nextIdx = game.foundLetters.indexOf(null);

        // --- KRİTİK DÜZELTME: Eğer bulunacak harf kalmadıysa (Son harf seçildiyse) ---
        if (nextIdx == -1) {
          return TutorialOverlay(
            targetKey: TutorialKeys.wordAreaKey, // Odak kelime alanına kayar
            currentStep: step,
            isInitialPhase: true,
            text: "Muhteşem! ✨\nKelimenin tüm parçalarını birleştirdin.",
            showButton: false, // 1.5 sn sonra zaten otomatik 'success' adımına geçecek
            onNext: () {},
          );
        }

        GlobalKey? letterKey;
        String instructionText = "Sıradaki harfi bul ve dokun.";

        final char = game.targetWord[nextIdx];

        // Dinamik Mesajlar
        if (char == "L") {
          instructionText = "Hafızan çok güçlü! ✨\nŞimdi listeden **'L'** harfini bul ve dokun.";
        } else if (char == "A") {
          instructionText = "Mükemmel gidiyorsun! 🎯\nSon parça: **'A'** harfini de yerine koyalım.";
        }

        // Grid içinden harf anahtarını bulma
        int gridIdx = -1;
        for (int i = 0; i < game.gridLetters.length; i++) {
          if (game.gridLetters[i] == char && !game.selectedIndices.contains(i)) {
            gridIdx = i;
            break;
          }
        }

        if (gridIdx != -1 && gridIdx < TutorialKeys.gridTileKeys.length) {
          letterKey = TutorialKeys.gridTileKeys[gridIdx];
        }

        return TutorialOverlay(
          targetKey: letterKey ?? TutorialKeys.gridKey,
          currentStep: step,
          isInitialPhase: true,
          text: instructionText,
          showButton: false, // Kullanıcının harfe basmasını bekliyoruz
          onNext: () {},
        );

      case TutorialStep.success:
        return TutorialOverlay(
          targetKey: TutorialKeys.wordAreaKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Mükemmel! Temel mekaniği öğrendin.",
          onNext: () => notifier.nextStep(),
        );

      case TutorialStep.phase2Intro:
        return TutorialPhase2Intro(
          onStart: () {
            ref.read(gameProvider.notifier).resetGameForTutorial();
            notifier.startPhase2Practice(); // step -> phase2Play yapar
          },
        );

      case TutorialStep.phase2Play:
      // "Sıra sende" oynanış aşaması. Ekranda hiçbir overlay olmamalı.
        return const SizedBox.shrink();

      case TutorialStep.completed:
        return TutorialSuccessOverlay(
          title: "Artık Hazırsın!",
          message: "Gerçek kategoriler ve kelimeler seni bekliyor.",
          buttonText: "Gerçek Oyuna Başla",
          onStartGame: () async {
            await notifier.completeTutorial();
            ref.read(gameProvider.notifier).resetGame();
            notifier.startJokerOnboarding();
          },
        );

    // --- JOKER TANITIMLARI ---
      case TutorialStep.forcedHint:
        return TutorialOverlay(
          targetKey: TutorialKeys.hintKey,
          currentStep: step,
          isInitialPhase: false,
          text: "💡 Harf Aç Jokeri\n\nBu joker senin için doğru bir harf ekler.",
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.forcedClear:
        return TutorialOverlay(
          targetKey: TutorialKeys.clearKey,
          currentStep: step,
          isInitialPhase: false,
          text: "❌ Yanlış Sil Jokeri\n\nGriddeki yanlış harfleri eler.",
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.forcedReveal:
        return TutorialOverlay(
          targetKey: TutorialKeys.revealKey,
          currentStep: step,
          isInitialPhase: false,
          text: "👁 Tekrar Butonu\n\nHarfleri unuttuğunda tekrar görebilirsin.",
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.tokenInfo:
        return TutorialOverlay(
          targetKey: TutorialKeys.tokenKey,
          currentStep: step,
          isInitialPhase: false,
          text: "TOKENLAR\n\nHatalı seçimler ve jokerler token harcar.",
          buttonText: "Anladım",
          onNext: () => notifier.closeTokenTutorial(),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}