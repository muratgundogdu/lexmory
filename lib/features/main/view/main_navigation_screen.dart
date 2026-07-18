import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/game_state.dart';
import '../../game/providers/game_provider.dart';
import '../../game/view/game_screen.dart';
import '../../library/screens/library_overview_screen.dart';
import '../../store/view/store_screen.dart';
import '../../settings/view/settings_screen.dart';
import '../../tutorial/models/tutorial_state.dart' hide TutorialKeys;
import '../../tutorial/models/tutorial_keys.dart'; 
import '../providers/navigation_provider.dart';
import '../widgets/lex_bottom_nav.dart';
import '../../library/widgets/chest_reward_overlay.dart';
import '../../library/provider/reward_queue_provider.dart';
import '../../tutorial/providers/tutorial_provider.dart';
import '../../tutorial/widgets/tutorial_overlay.dart';
import '../../tutorial/widgets/tutorial_phase2_intro.dart';
import '../../tutorial/widgets/tutorial_success_overlay.dart';
import '../../daily_login/providers/daily_login_provider.dart';
import '../../daily_login/widgets/daily_login_dialog.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  bool _dailyLoginChecked = false;
  bool _isOverlayActive = false;

  void _checkAndShowNextReward() {
    if (!mounted || _isOverlayActive) return;

    final rewardQueue = ref.read(rewardQueueProvider);
    final tutorial = ref.read(tutorialProvider);

    if (rewardQueue.events.isNotEmpty && !rewardQueue.isPresenting && !tutorial.isNavigationLocked) {
      final event = rewardQueue.events.first;
      
      // Mark as presenting immediately to avoid duplicate triggers
      ref.read(rewardQueueProvider.notifier).markPresentationStarted();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        
        setState(() => _isOverlayActive = true);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ChestRewardOverlay(
            result: event.result,
            title: event.title,
            subtitle: event.subtitle,
          ),
        ).then((_) {
          if (mounted) {
            setState(() => _isOverlayActive = false);
            ref.read(rewardQueueProvider.notifier).completeCurrent();
            // Re-check for more rewards in the queue
            _checkAndShowNextReward();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final tutorial = ref.watch(tutorialProvider);
    final game = ref.watch(gameProvider);
    final dailyLogin = ref.watch(dailyLoginProvider);
    final rewardQueue = ref.watch(rewardQueueProvider);

    // Mandatory Tab Enforcement
    if (tutorial.isNavigationLocked && 
        tutorial.requiredTabIndex != null && 
        currentIndex != tutorial.requiredTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).state = tutorial.requiredTabIndex!;
      });
    }

    // Reward Presentation Listener
    ref.listen(rewardQueueProvider, (previous, next) {
      _checkAndShowNextReward();
    });

    // Daily Login Auto-Show
    if (!_dailyLoginChecked && 
        !dailyLogin.isLoading && 
        dailyLogin.isRewardAvailable && 
        tutorial.onboardingFullyCompleted && // Requirement
        !tutorial.isTutorialActive && 
        !tutorial.isNavigationLocked && // Extra safety
        !_isOverlayActive && 
        rewardQueue.events.isEmpty) {
      _dailyLoginChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _isOverlayActive = true);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const DailyLoginDialog(),
        ).then((_) {
          if (mounted) {
            setState(() => _isOverlayActive = false);
            // Trigger check after Daily Login dialog closes
            _checkAndShowNextReward();
          }
        });
      });
    }

    final List<Widget> screens = [
      const GameScreen(),
      const LibraryOverviewScreen(),
      const StoreScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: !tutorial.isNavigationLocked,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && tutorial.isNavigationLocked) {
          // Navigation is locked due to tutorial
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(index: currentIndex, children: screens),

            // Gift Icon if reward is available but dialog closed
            if (dailyLogin.isRewardAvailable && 
                tutorial.onboardingFullyCompleted && 
                !tutorial.isTutorialActive && 
                !tutorial.isNavigationLocked)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                right: 20,
                child: GestureDetector(
                  onTap: _isOverlayActive ? null : () {
                    setState(() => _isOverlayActive = true);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const DailyLoginDialog(),
                    ).then((_) {
                      if (mounted) setState(() => _isOverlayActive = false);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C078),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: Colors.black, size: 24),
                  ),
                ),
              ),

            // Alt Navigasyon Bar
            const Align(
              alignment: Alignment.bottomCenter,
              child: LexBottomNav(),
            ),

            // Interactivity Lock Barrier (Gap protection)
            if (tutorial.isNavigationLocked && !tutorial.isTutorialActive)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {}, // Block taps
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),

            // --- TUTORIAL OVERLAY (EN ÜST KATMAN) ---
            if (tutorial.isTutorialActive)
              _buildGlobalTutorialStep(ref, tutorial, game),
          ],
        ),
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
        String flowText = "Bulman gereken kelime burada yer alır.";
        bool showBtn = true;

        if (tutorialState.phase == TutorialPhase.phase1 && game.hasStarted) {
          flowText = "Harika! ✨\nHarf ait olduğu yere yerleşti. Devam edelim...";
          showBtn = false; 
        }

        return TutorialOverlay(
          targetKey: TutorialKeys.wordAreaKey,
          currentStep: step,
          isInitialPhase: true,
          text: flowText,
          showButton: showBtn,
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
        if (tutorialState.phase == TutorialPhase.phase2) return const SizedBox.shrink();

        final int nextIdx = game.foundLetters.indexOf(null);

        if (nextIdx == -1) {
          return TutorialOverlay(
            targetKey: TutorialKeys.wordAreaKey, 
            currentStep: step,
            isInitialPhase: true,
            text: "Muhteşem! ✨\nKelimenin tüm parçalarını birleştirdin.",
            showButton: false, 
            onNext: () {},
          );
        }

        GlobalKey? letterKey;
        String instructionText = "Sıradaki harfi bul ve dokun.";

        final char = game.targetWord[nextIdx];

        if (char == "L") {
          instructionText = "Hafızan çok güçlü! ✨\nŞimdi listeden **'L'** harfini bul ve dokun.";
        } else if (char == "A") {
          instructionText = "Mükemmel gidiyorsun! 🎯\nSon parça: **'A'** harfini de yerine koyalım.";
        }

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
          showButton: false, 
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
            notifier.startPhase2Practice(); 
          },
        );

      case TutorialStep.phase2Play:
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

    }
  }
}
