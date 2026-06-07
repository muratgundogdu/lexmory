import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Core
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';

// Tutorial
import '../../tutorial/models/tutorial_state.dart' hide TutorialKeys;
import '../../tutorial/providers/tutorial_provider.dart';
import '../../tutorial/models/tutorial_keys.dart';
import '../../tutorial/widgets/tutorial_overlay.dart';
import '../../tutorial/widgets/tutorial_phase2_intro.dart';
import '../../tutorial/widgets/tutorial_success_overlay.dart';

// Game Logic & Models
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../services/reward_calculator.dart';

// Widgets & Overlays
import '../widgets/category_complete_overlay.dart';
import '../widgets/game_finished_overlay.dart';
import '../widgets/game_header.dart';
import '../widgets/out_of_tokens_overlay.dart';
import '../widgets/word_reveal_area.dart';
import '../widgets/joker_bar.dart';
import '../widgets/letter_grid.dart';
import '../../../widgets/victory_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // Kelime harf kutuları için yerel key listesi (Kelime uzunluğuna göre dinamik)
  final List<GlobalKey> _boxKeys = List.generate(12, (_) => GlobalKey());

  // Sabitler
  static const double _bottomNavSpace = 104.0;

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialProvider);
    final game = ref.watch(gameProvider);

    // Veri kontrolü
    if (game.category.isEmpty || game.gridLetters.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final bool isOutOfTokens = game.tokens < 5;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: Stack(
          children: [
            // 1. ANA OYUN KATMANI
            AbsorbPointer(
              absorbing: isOutOfTokens ||
                  game.showGameFinishedPanel ||
                  game.showCategoryCompletePanel,
              child: _buildMainLayout(game),
            ),

            // 3. OYUN SONU PANELLERİ
            _buildOverlays(game, isOutOfTokens),
          ],
        ),
      ),
    );
  }

  /// Ana Oyun Layout Yapısı
  Widget _buildMainLayout(GameState game) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // ÜST: Header (Token, Streak, Kategori Başlığı merkezi keyler ile)
            GameHeader(
              game: game,
              tokenKey: TutorialKeys.tokenKey,
              categoryKey: TutorialKeys.categoryKey,
            ),

            const SizedBox(height: 16),

            // KELİME ALANI
            WordRevealArea(
              key: TutorialKeys.wordAreaKey,
              game: game,
              boxKeys: _boxKeys,
            ),

            // ORTA: ESNEK GRID
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.s16),
                  child: Container(
                    key: TutorialKeys.gridKey,
                    child: LetterGrid(
                      game: game,
                      tileKeys: TutorialKeys.gridTileKeys,
                    ),
                  ),
                ),
              ),
            ),

            // ALT: AKSİYON ALANI
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!game.hasStarted) ...[
                  _buildStartButton(game),
                  const SizedBox(height: 16),
                ],

                JokerBar(
                  game: game,
                  hintKey: TutorialKeys.hintKey,
                  clearKey: TutorialKeys.clearKey,
                  revealKey: TutorialKeys.revealKey,
                ),

                const SizedBox(height: _bottomNavSpace),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tüm Overlay (Popup) bileşenlerini barındırır
  Widget _buildOverlays(GameState game, bool isOutOfTokens) {
    return Stack(
      children: [
        PremiumRewardOverlay(
          isVisible: game.showVictoryPanel,
          baseReward: 25,
          memoryBonus: _calculateBonus(game.wrongAttemptsCount),
          masterBonus: _calculateBonus(game.jokersUsedCount),
          multiplier: RewardCalculator.getMultiplierValue(game.streak),
          totalReward: game.lastRewardTotal,
        ),
        CategoryCompleteOverlay(
          isVisible: game.showCategoryCompletePanel,
          categoryName: game.lastCompletedCategory ?? "",
          sectionCount: game.currentWordIndex + 1,
          totalWrong: game.totalCategoryWrongCount,
          totalJokers: game.totalCategoryJokersCount,
          onContinue: () => ref.read(gameProvider.notifier).startNextCategory(),
        ),
        GameFinishedOverlay(
          isVisible: game.showGameFinishedPanel,
          totalCategories: game.completedCategories.length,
          totalWords: game.totalSolvedWords,
          totalTokens: game.tokens,
          onReset: () => ref.read(gameProvider.notifier).resetGame(),
        ),
        OutOfTokensOverlay(
          isVisible: game.showOutOfTokensPanel || isOutOfTokens,
          isDismissible: game.isOutOfTokensDismissible,
          currentTokens: game.tokens,
          lastRegen: game.lastRegenTime,
          rewardAmount: game.pendingAdReward > 0 ? game.pendingAdReward : 50,
          onWatchAd: () => ref.read(gameProvider.notifier).watchAdForTokens(),
          onClose: () => ref.read(gameProvider.notifier).closeOutOfTokensPanel(),
          onStore: () {},
        ),
      ],
    );
  }

  int _calculateBonus(int count) {
    if (count == 0) return 15;
    if (count == 1) return 10;
    if (count == 2) return 5;
    return 0;
  }

  /// BULDUM Pill Button
  Widget _buildStartButton(GameState game) {
    return Center(
      child: GestureDetector(
        key: TutorialKeys.startButtonKey,
        onTap: () async {
          ref.read(gameProvider.notifier).startMemoryReveal();
          final tutorialState = ref.read(tutorialProvider);

          if (tutorialState.isTutorialActive &&
              tutorialState.currentStep == TutorialStep.startButton) {
            ref.read(tutorialProvider.notifier).nextStep();
          }
          // 1.5 saniye sonra Tekrar (Reveal) Tanıtımı başlasın (Talebe göre 1500ms)
          else if (tutorialState.phase == TutorialPhase.contextual &&
              !tutorialState.isTutorialActive &&
              !tutorialState.revealTutorialShown &&
              game.category != "Meyveler") {
            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
              ref.read(tutorialProvider.notifier).startForcedRevealOnboarding();
            }
          }
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // 3. KRİTİK: Sadece metin kadar yer kaplar
            children: [ Text(
              "BULDUM!",
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
           ],
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1000.ms, curve: Curves.easeInOut)
        .shimmer(delay: 3.seconds, duration: 1500.ms, color: Colors.white30);
  }
}