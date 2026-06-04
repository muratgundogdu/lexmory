import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../tutorial/models/tutorial_state.dart';
import '../../tutorial/providers/tutorial_provider.dart';
import '../../tutorial/widgets/tutorial_overlay.dart';
import '../../tutorial/widgets/tutorial_phase2_intro.dart';
import '../../tutorial/widgets/tutorial_success_overlay.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

import '../services/reward_calculator.dart';
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
  // --- GLOBAL KEYS ---
  final GlobalKey _tokenKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _wordAreaKey = GlobalKey(); // Tüm kelime alanı için
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _startButtonKey = GlobalKey();
  final GlobalKey _jokerKey = GlobalKey();

  // Yeni Key'ler
  final GlobalKey _hintKey = GlobalKey();
  final GlobalKey _clearKey = GlobalKey();
  final GlobalKey _revealKey = GlobalKey();

  // Her bir harf kutusu için ayrı anahtarlar (Tutorial 5. Adım için)
  final List<GlobalKey> _boxKeys = List.generate(12, (_) => GlobalKey());

  final List<GlobalKey> _gridTileKeys = List.generate(16, (_) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialProvider);
    final game = ref.watch(gameProvider);

    // --- TETİKLEYİCİ: TOKEN TANITIMI (Gerçek Oyun İçin) ---
    /*ref.listen<int>(gameProvider.select((s) => s.tokens), (previous, next) {
      if (previous != null &&
          next < previous &&
          // KRİTİK: Zorunlu eğitim adımlarında değilsek göster
          tutorial.currentStep != TutorialStep.forcedHint &&
          tutorial.currentStep != TutorialStep.forcedClear &&
          tutorial.phase == TutorialPhase.contextual &&
          !tutorial.tokenTutorialShown) {

        ref.read(tutorialProvider.notifier).markFlag('token_tutorial_shown');
        _showTokenTutorialDialog(context);
      }
    });*/

    // Yükleme kontrolü
    if (game.category.isEmpty || game.gridLetters.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFBF360C))),
      );
    }

    // --- TETİKLEYİCİ: JOKER TANITIMI (Gerçek Oyun Başında) ---


    final isOutOfTokens = game.tokens < 5;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF2D1B18)],
          ),
        ),
        child: Stack(
          children: [
            // 1. ANA OYUN KATMANI
            AbsorbPointer(
              // ÖNEMLİ: tutorial.isTutorialActive burada olmamalı!
              // Dokunma kontrolünü TutorialOverlay (4 bloklu yapı) halleder.
              absorbing: isOutOfTokens || game.showGameFinishedPanel || game.showCategoryCompletePanel,
              child: _buildMainLayout(game),
            ),

            // 2. TUTORIAL OVERLAY (Sadece aktifse)
            if (tutorial.isTutorialActive)
              _buildTutorialStep(tutorial.currentStep, game),

            // 3. OYUN SONU/ZAFER PANELLERİ
            PremiumRewardOverlay(
              isVisible: game.showVictoryPanel,
              baseReward: 25,

              // Memory Bonus Gösterimi (Hesaplayıcı ile aynı mantık)
              memoryBonus: game.wrongAttemptsCount == 0 ? 15 :
              game.wrongAttemptsCount == 1 ? 10 :
              game.wrongAttemptsCount == 2 ? 5 : 0,

              // Master (No Hint) Bonus Gösterimi
              masterBonus: game.jokersUsedCount == 0 ? 15 :
              game.jokersUsedCount == 1 ? 10 :
              game.jokersUsedCount == 2 ? 5 : 0,

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
              onWatchAd: () => ref.read(gameProvider.notifier).watchAdForTokens(),
              onClose: () => ref.read(gameProvider.notifier).closeOutOfTokensPanel(),
              onStore: () {},
            ),
          ],
        ),
      ),
    );
  }

  // Ana oyun düzeni
  Widget _buildMainLayout(GameState game) {
    // Ekran genişliğini alıyoruz
    final double screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // 1. ÜST BÖLÜM: Kategori ve Token (Sabit)
            GameHeader(game: game, tokenKey: _tokenKey, categoryKey: _categoryKey),

            // 2. ORTA BÖLÜM: Oyun Alanı (Ölçeklenen Bölüm)
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    // KRİTİK DÜZELTME: FittedBox içindeki yapıya genişlik veriyoruz
                    width: screenWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          key: _wordAreaKey,
                          child: WordRevealArea(game: game, boxKeys: _boxKeys),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          key: _gridKey,
                          child: LetterGrid(game: game, tileKeys: _gridTileKeys),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. ALT BÖLÜM: Butonlar ve Jokerler
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!game.hasStarted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildStartButton(game),
                  ),

                Container(
                  key: _jokerKey,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    // Joker barı için de genişliği kısıtlıyoruz
                    child: SizedBox(
                      width: screenWidth,
                      child: JokerBar(
                        game: game,
                        hintKey: _hintKey,
                        clearKey: _clearKey,
                        revealKey: _revealKey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tutorial adımlarını oluşturan yardımcı metod
  Widget _buildTutorialStep(TutorialStep step, GameState game) {
    // Not: Tüm adımlar return ile bittiği için artık değişken tanımlamaya gerek yok.

    switch (step) {
    // --- PHASE 1: YÖNLENDİRMELİ (ALTTA SABİT) ---
      case TutorialStep.category:
        return TutorialOverlay(
          targetKey: _categoryKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Her bölümde bir kategori görürsün.\nKategori sana kelime hakkında ipucu verir.",
          onNext: () => ref.read(tutorialProvider.notifier).nextStep(),
        );

      case TutorialStep.wordBoxes:
        return TutorialOverlay(
          targetKey: _wordAreaKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Bulman gereken kelime burada yer alır.",
          onNext: () => ref.read(tutorialProvider.notifier).nextStep(),
        );

      case TutorialStep.grid:
        return TutorialOverlay(
          targetKey: _gridKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Harfleri dikkatlice incele.\nBirazdan kapanacaklar.",
          onNext: () => ref.read(tutorialProvider.notifier).nextStep(),
        );

      case TutorialStep.startButton:
        return TutorialOverlay(
          targetKey: _startButtonKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Kelimeyi gördüğünde BULDUM butonuna bas.",
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.findingLetters:
        final int nextEmptyIndex = game.foundLetters.indexOf(null);
        GlobalKey? targetKey;
        String text = "";

        if (nextEmptyIndex != -1) {
          final String targetChar = game.targetWord[nextEmptyIndex];
          int tileIndexInGrid = -1;
          for (int i = 0; i < game.gridLetters.length; i++) {
            if (game.gridLetters[i] == targetChar && !game.selectedIndices.contains(i)) {
              tileIndexInGrid = i;
              break;
            }
          }
          if (tileIndexInGrid != -1) {
            targetKey = _gridTileKeys[tileIndexInGrid];
          }
          text = targetChar == "L"
              ? "Harika! Şimdi harfler kapandı.\nHafızandan 'L' harfini bul ve bas."
              : "Çok iyi! Şimdi son harf olan 'A' harfine bas.";
        }
        return TutorialOverlay(
          targetKey: targetKey ?? _gridKey,
          currentStep: step,
          isInitialPhase: true,
          text: text,
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.success:
        return TutorialOverlay(
          targetKey: _wordAreaKey,
          currentStep: step,
          isInitialPhase: true,
          text: "Tebrikler!\nTemel mekaniği başarıyla tamamladın.",
          onNext: () => ref.read(tutorialProvider.notifier).nextStep(),
        );

    // --- PHASE 2: SERBEST DENEYİM ---
      case TutorialStep.phase2Intro:
        return TutorialPhase2Intro(
          onStart: () {
            ref.read(gameProvider.notifier).resetGameForTutorial();
            ref.read(tutorialProvider.notifier).startPhase2Practice();
          },
        );

      case TutorialStep.phase2Play:
        return const SizedBox.shrink();

    // --- PHASE 3: CONTEXTUAL (DİNAMİK KONUM) ---
      case TutorialStep.forcedHint:
        return TutorialOverlay(
          targetKey: _hintKey,
          currentStep: step,
          isInitialPhase: false,
          text: "💡 Harf Aç Jokeri\n\nBu joker senin için doğru bir harf ekler.\nDenemek için şimdi butona dokun.",
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.forcedClear:
        return TutorialOverlay(
          targetKey: _clearKey,
          currentStep: step,
          isInitialPhase: false,
          text: "❌ Yanlış Sil Jokeri\n\nGriddeki yanlış harfleri eler.\nDenemek için şimdi butona dokun.",
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.forcedReveal:
        return TutorialOverlay(
          targetKey: _revealKey,
          currentStep: step,
          isInitialPhase: false,
          text: "👁 Tekrar Butonu\n\nHarfleri unuttuğunda buna basarak kısa süreliğine tekrar görebilirsin.\n\nBu kullanım ücretsizdir.",
          showButton: false,
          onNext: () {},
        );

      case TutorialStep.tokenInfo:
        return TutorialOverlay(
          targetKey: _tokenKey, // Token göstergesini hedef alalım
          currentStep: step,
          isInitialPhase: false,
          text: "TOKENLAR\n\nYanlış harf seçimleri 5 token kaybettirir.\n"
              "Joker kullanımları da token harcar.\n\n"
              "Tokenların azaldığında zamanla yenilenir veya "
              "reklam izleyerek kazanabilirsin.",
          buttonText: "Anladım",
          onNext: () => ref.read(tutorialProvider.notifier).closeTokenTutorial(),
        );

      case TutorialStep.completed:
        return TutorialSuccessOverlay(
          title: "Artık Hazırsın!",
          message: "Gerçek kategoriler ve kelimeler seni bekliyor.",
          buttonText: "Gerçek Oyuna Başla",
          onStartGame: () async {
            await ref.read(tutorialProvider.notifier).completeTutorial();
            ref.read(gameProvider.notifier).resetGame();
            await Future.delayed(const Duration(milliseconds: 1000));
            ref.read(tutorialProvider.notifier).startJokerOnboarding();
          },
        );
    }
  }

  Widget _buildStartButton(GameState game) {
    return Padding(
      key: _startButtonKey,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: () async { // async eklendi
          // 1. Kartları kapat ve hafıza modunu başlat
          ref.read(gameProvider.notifier).startMemoryReveal();

          final tutorialState = ref.read(tutorialProvider);

          // DURUM 1: Eğer şu an Phase 1'de (ELMA bölümü) "BULDUM Butonu" adımındaysak
          if (tutorialState.isTutorialActive &&
              tutorialState.currentStep == TutorialStep.startButton) {
            ref.read(tutorialProvider.notifier).nextStep();
          }

          // DURUM 2: Yanlış Sil jokeri tanıtıldıktan sonra ilk kez Buldum'a basıldığında
          // Tekrar butonunun (Reveal) tanıtımını yap
          else if (tutorialState.phase == TutorialPhase.contextual &&
              !tutorialState.isTutorialActive && // Başka spotlight açık değilse
              !tutorialState.revealTutorialShown && // Daha önce gösterilmediyse
              game.category != "Meyveler") { // Eğitim kategorisi değilse

            // --- KRİTİK GECİKMELİ AKIŞ ---
            // Kartların dönüp kapanma animasyonunu (flip) izlemek için 2 saniye bekliyoruz.
            // Bu süre, oyuncunun "hafıza moduna" geçtiğini anlamasını sağlar.
            await Future.delayed(const Duration(milliseconds: 2000));

            // Eğer oyuncu hala bu ekrandaysa tanıtımı başlat
            if (mounted) {
              ref.read(tutorialProvider.notifier).startForcedRevealOnboarding();            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBF360C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 6,
        ),
        child: const Text("BULDUM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1200.ms),
    );
  }

}