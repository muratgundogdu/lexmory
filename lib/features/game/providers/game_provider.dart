import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_constants.dart';
import '../../tutorial/models/tutorial_state.dart';
import '../../tutorial/providers/tutorial_provider.dart';
import '../models/game_state.dart';
import '../../../../data/categories.dart';
import '../services/ad_service.dart';
import '../services/reward_calculator.dart';
import '../repository/game_repository.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final gameRepositoryProvider = Provider((ref) => GameRepository());
final adServiceProvider = Provider((ref) => AdService());

class GameNotifier extends StateNotifier<GameState> {
  final GameRepository _repository;
  static const String _storageKey = 'lexmory_save_game';
  final AdService _adService;
  Timer? _regenTimer;
  final Ref _ref;

  GameNotifier(this._repository, this._adService, this._ref) : super(_createPlaceholderState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadFromStorage();
    _checkOfflineRegeneration();
    _startRegenTimer();
  }

  // --- TOKEN REGENERATION LOGIC ---
  void _checkOfflineRegeneration() {
    if (state.tokens >= 100) return;
    final now = DateTime.now();
    final difference = now.difference(state.lastRegenTime);
    if (difference.inSeconds >= 600) {
      int cycles = (difference.inSeconds / 600).floor();
      int totalRegen = cycles * 5;
      int newTokens = (state.tokens + totalRegen).clamp(0, 100);
      DateTime updatedRegenTime = state.lastRegenTime.add(Duration(seconds: cycles * 600));
      state = state.copyWith(tokens: newTokens, lastRegenTime: updatedRegenTime);
      _persist();
    }
  }

  void _startRegenTimer() {
    _regenTimer?.cancel();
    _regenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.tokens < AppConstants.maxRegenLimit) {
        final now = DateTime.now();
        if (now.difference(state.lastRegenTime) >= AppConstants.regenInterval) {
          _executeRegeneration();
        }
        _checkTokenStatus();
      }
    });
  }

  void _executeRegeneration() {
    final int newTokens = (state.tokens + AppConstants.regenAmount).clamp(0, AppConstants.maxRegenLimit);
    state = state.copyWith(
      tokens: newTokens,
      lastRegenTime: DateTime.now(),
      showOutOfTokensPanel: newTokens >= 5 ? false : state.showOutOfTokensPanel,
    );
    _persist();
  }

  void _checkTokenStatus() {
    if (state.tokens < 5) {
      state = state.copyWith(showOutOfTokensPanel: true, isOutOfTokensDismissible: false);
      _persist();
    }
  }

  Future<void> watchAdForTokens() async {
    final success = await _adService.showRewardedAd();
    if (success) {
      state = state.copyWith(tokens: state.tokens + 50, showOutOfTokensPanel: false);
      _persist();
    }
  }

  // --- STATE INITIALIZATION ---
  static GameState _createPlaceholderState() {
    return GameState(
      category: "", targetWord: "", gridLetters: [], selectedIndices: [],
      foundLetters: [], isInitialReveal: true, hasStarted: false, tokens: 300,
      completedCategories: [], currentWordIndex: 0, eliminatedIndices: [],
      wrongAttemptsCount: 0, jokersUsedCount: 0, streak: 0,
      showVictoryPanel: false, lastRewardTotal: 0, showCategoryCompletePanel: false,
      totalCategoryWrongCount: 0, totalCategoryJokersCount: 0,
      showGameFinishedPanel: false, totalSolvedWords: 0, totalEarnedTokens: 0,
      showOutOfTokensPanel: false, isOutOfTokensDismissible: false,
      lastRegenTime: DateTime.now(),
    );
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);
    final isTutorialCompleted = prefs.getBool('tutorial_completed') ?? false;

    if (!isTutorialCompleted) {
      state = _buildStateForWord(
        word: "ELMA",
        category: "Meyveler", // Kategori güncellendi
        tokens: 300,
        completedCats: [],
        wordIdx: 0,
      );
      _persist();
      return;
    }

    if (savedData != null) {
      try {
        state = GameState.fromJson(jsonDecode(savedData));
        _checkOfflineRegeneration();
        _checkTokenStatus();
      } catch (e) {
        state = _createInitialState(_repository);
      }
    } else {
      state = _createInitialState(_repository);
    }
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  static GameState _createInitialState(GameRepository repository, {int? existingTokens, DateTime? lastRegen}) {
    final selectedCatData = repository.getRandomCategory();
    final String catName = selectedCatData['category'] as String;
    final List<String> words = repository.getWordsForCategory(selectedCatData);

    return _buildStateForWord(
      word: words[0],
      category: catName,
      tokens: existingTokens ?? 300,
      lastRegen: lastRegen ?? DateTime.now(),
      completedCats: [],
      wordIdx: 0,
      solvedWords: 0,
      earnedTokens: 0,
    );
  }

  // --- CORE GAME ACTIONS ---
  void startMemoryReveal() {
    if (state.hasStarted) return;

    state = state.copyWith(hasStarted: true, isInitialReveal: false);
    _persist();

    final tut = _ref.read(tutorialProvider);

    // --- KRİTİK DÜZELTME ---
    // 1. Eğer zorunlu Joker Onboarding (Harf Aç + Yanlış Sil) zaten bittiyse
    // bir daha asla bu bloğa girme.
    if (tut.hintJokerTutorialCompleted && tut.removeJokerTutorialCompleted) {
      return;
    }

    // 2. Eğer şu an halihazırda bir tutorial adımı aktifse (bekleme süresindeysek vs.)
    // BULDUM butonu tanıtımı baştan başlatmasın.
    if (tut.isTutorialActive) {
      return;
    }

    // 3. Sadece phase contextual olduğunda (ELMA bittikten sonraki ilk gerçek oyun)
    // ve daha önce hiç gösterilmediyse tetikle.
    if (tut.phase == TutorialPhase.contextual &&
        !tut.hintClearTutorialShown &&
        state.category != "Meyveler") {

      // Bu metod zaten TutorialController içinde forcedHint adımını başlatıyor.
      _ref.read(tutorialProvider.notifier).showJokerOnboarding();
    }
  }

  void closeOutOfTokensPanel() {
    state = state.copyWith(showOutOfTokensPanel: false);
    _persist();
  }

  void selectLetter(int index) {
    if (state.tutorialLock) return;

    final tutorialState = _ref.read(tutorialProvider);

    if (tutorialState.isTutorialActive) {
      // --- FAZ 2: SERBEST DENEYİM (SPOTLIGHTSIZ) ---
      if (tutorialState.phase == TutorialPhase.phase2) {
        if (state.isInitialReveal || state.selectedIndices.contains(index) || !state.hasStarted) return;

        final tappedLetter = state.gridLetters[index];
        final nextTargetIndex = state.foundLetters.indexOf(null);

        if (nextTargetIndex != -1) {
          final expectedLetter = state.targetWord[nextTargetIndex];

          if (tappedLetter == expectedLetter) {
            _handleCorrectSelection(index, nextTargetIndex, tappedLetter);

            // KRİTİK: State güncellenmeden önce listenin kopyasıyla kontrol
            final List<String?> checkList = [...state.foundLetters];
            checkList[nextTargetIndex] = tappedLetter;

            if (!checkList.contains(null)) {
              // Kelime bitti, TutorialController'a haber ver (Final ekranına geçer)
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  _ref.read(tutorialProvider.notifier).nextStep();
                }
              });
            }
          } else {
            HapticFeedback.lightImpact();
          }
        }
        return;
      }

      // --- FAZ 1: YÖNLENDİRMELİ EĞİTİM (SPOTLIGHTLI) ---
      if (tutorialState.currentStep == TutorialStep.findingLetters) {
        final tappedLetter = state.gridLetters[index];
        final nextTargetIndex = state.foundLetters.indexOf(null);

        if (nextTargetIndex != -1) {
          final expectedLetter = state.targetWord[nextTargetIndex];
          if (tappedLetter == expectedLetter) {
            _handleCorrectSelection(index, nextTargetIndex, tappedLetter);

            final List<String?> checkList = [...state.foundLetters];
            checkList[nextTargetIndex] = tappedLetter;

            if (!checkList.contains(null)) {
              Future.delayed(const Duration(milliseconds: 2000), () {
                if (mounted) {
                  _ref.read(tutorialProvider.notifier).nextStep();
                }
              });
            }
          }
        }
      }
      return;
    }

    // --- NORMAL OYUN MANTIĞI ---
    if (state.isInitialReveal || state.selectedIndices.contains(index) || !state.hasStarted) return;

    final tappedLetter = state.gridLetters[index];
    final nextTargetIndex = state.foundLetters.indexOf(null);

    if (nextTargetIndex == -1) return;

    if (tappedLetter == state.targetWord[nextTargetIndex]) {
      _handleCorrectSelection(index, nextTargetIndex, tappedLetter);
    } else {
      _handleWrongSelection(index);
    }
  }

// 1. ADIM: Bu metodu Future<void> yapın ve içindeki gecikmeyi await edin
  Future<void> _handleCorrectSelection(
      int gridIdx,
      int targetIdx,
      String letter,
      ) async {
    state = state.copyWith(
      tutorialLock: true,
      lastAttemptIndex: gridIdx,
      isLastAttemptCorrect: true,
      justFoundIndex: targetIdx,
      selectedIndices: [...state.selectedIndices, gridIdx],
    );

    // 2. Harfin uçuş süresini (WordRevealArea'daki move süresi olan 650-800ms) bekle
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // 3. Harfi kutuya yerleştir
    final newFound = List<String?>.from(state.foundLetters);
    newFound[targetIdx] = letter;

    state = state.copyWith(
      foundLetters: newFound,
      justFoundIndex: null, // Uçuş objesini kaldır
      tutorialLock: false, // Dokunma artık serbest
    );

    if (!newFound.contains(null)) {
      _handleWordVictory();
    }
  }
  void _handleWrongSelection(int gridIdx) async {
    HapticFeedback.mediumImpact();
    state = state.copyWith(
      tokens: max(0, state.tokens - 5),
      lastAttemptIndex: gridIdx,
      isLastAttemptCorrect: false,
      wrongAttemptsCount: state.wrongAttemptsCount + 1,
      totalCategoryWrongCount: state.totalCategoryWrongCount + 1,
      streak: 0,
    );

    _checkTokenStatus();

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      state = state.copyWith(lastAttemptIndex: null, isLastAttemptCorrect: null);
    }

    // Token Tanıtımı: İlk yanlışta
    final tut = _ref.read(tutorialProvider);
    if (tut.hintJokerTutorialCompleted &&
        tut.removeJokerTutorialCompleted &&
        tut.revealTutorialShown &&
        !tut.tokenTutorialShown &&
        state.category != "Meyveler") {

      // Oyuncunun hatayı görmesi için ek kısa bir bekleme
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        _ref.read(tutorialProvider.notifier).showTokenTutorial();
      }
    }
  }

  void _handleWordVictory() async {
    final tut = _ref.read(tutorialProvider);
    // Kategori ismine bakmak yerine tutorial'ın aktif olup olmadığına bakıyoruz
    if (tut.isTutorialActive) {
      return;
    }

    int currentStreak = state.streak;
    if (state.wrongAttemptsCount == 0 && state.jokersUsedCount == 0) {
      currentStreak += 1;
    } else if (state.wrongAttemptsCount > 0) {
      currentStreak = 0;
    }

    final reward = RewardCalculator.calculate(
      streak: currentStreak,
      wrongCount: state.wrongAttemptsCount,
      jokerCount: state.jokersUsedCount,
    );

    final int newTotalSolved = state.totalSolvedWords + 1;
    final int newTotalEarned = state.totalEarnedTokens + reward.total;

    final currentCatData = _repository.getCategoryByName(state.category);
    final List<String> words = _repository.getWordsForCategory(currentCatData);
    bool isCategoryLastWord = state.currentWordIndex + 1 >= words.length;

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (isCategoryLastWord) {
      final remainingCats = categories.where((c) =>
      !state.completedCategories.contains(c['category']) &&
          c['category'] != state.category).toList();

      if (remainingCats.isEmpty) {
        state = state.copyWith(
          tokens: state.tokens + reward.total + 150,
          showGameFinishedPanel: true,
          showCategoryCompletePanel: false,
          completedCategories: [...state.completedCategories, state.category],
          lastCompletedCategory: state.category,
          streak: currentStreak,
          totalSolvedWords: newTotalSolved,
          totalEarnedTokens: newTotalEarned + 150,
        );
      } else {
        state = state.copyWith(
          tokens: state.tokens + reward.total + 150,
          showCategoryCompletePanel: true,
          lastCompletedCategory: state.category,
          streak: currentStreak,
          totalSolvedWords: newTotalSolved,
          totalEarnedTokens: newTotalEarned + 150,
        );
      }
      _persist();
    } else {
      state = state.copyWith(
        showVictoryPanel: true,
        lastRewardTotal: reward.total,
        tokens: state.tokens + reward.total,
        streak: currentStreak,
        rewardTrigger: state.rewardTrigger + 1,
        totalSolvedWords: newTotalSolved,
        totalEarnedTokens: newTotalEarned,
      );
      _persist();

      await Future.delayed(const Duration(milliseconds: 4000));
      if (!mounted) return;
      state = state.copyWith(showVictoryPanel: false);
      _loadNextWord();
      _persist();
    }
  }

  void _loadNextWord() {
    final currentCatData = _repository.getCategoryByName(state.category);
    final List<String> words = _repository.getWordsForCategory(currentCatData);

    if (state.currentWordIndex + 1 < words.length) {
      state = _buildStateForWord(
        word: words[state.currentWordIndex + 1],
        category: state.category,
        tokens: state.tokens,
        completedCats: state.completedCategories,
        wordIdx: state.currentWordIndex + 1,
        streak: state.streak,
        totalWrong: state.totalCategoryWrongCount,
        totalJokers: state.totalCategoryJokersCount,
        rewardTrigger: state.rewardTrigger,
        solvedWords: state.totalSolvedWords,
        earnedTokens: state.totalEarnedTokens,
        lastRegen: state.lastRegenTime,
      );
    } else {
      final remainingCats = categories.where((c) =>
      !state.completedCategories.contains(c['category']) &&
          c['category'] != state.category).toList();

      if (remainingCats.isNotEmpty) {
        final nextCatData = remainingCats[Random().nextInt(remainingCats.length)];
        state = _buildStateForWord(
          word: (nextCatData['words'] as List)[0],
          category: nextCatData['category'] as String,
          tokens: state.tokens,
          completedCats: [...state.completedCategories, state.category],
          wordIdx: 0,
          streak: state.streak,
          rewardTrigger: state.rewardTrigger,
          solvedWords: state.totalSolvedWords,
          earnedTokens: state.totalEarnedTokens,
          lastRegen: state.lastRegenTime,
        );
      }
    }
    _persist();
  }

  void resetGame() {
    state = _createInitialState(
        _repository,
        existingTokens: state.tokens,
        lastRegen: state.lastRegenTime
    );
    _persist();
  }

  void resetGameForTutorial() {
    state = _buildStateForWord(
      word: "ELMA",
      category: "Meyveler",
      tokens: 300,
      completedCats: [],
      wordIdx: 0,
    );
    _persist();
  }

// --- HARF AÇ JOKERİ ---
// --- HARF AÇ JOKERİ ---
  Future<void> useHint() async {
    if (state.tutorialLock) return;
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);

    final bool isForcedStep = tutorialState.currentStep == TutorialStep.forcedHint;

    if (tutorialState.isTutorialActive && tutorialState.phase != TutorialPhase.contextual) return;
    if (tutorialState.isTutorialActive && !isForcedStep) return;

    final bool isFree = isForcedStep || (!tutorialState.freeHintUsed && state.category != "Meyveler");
    final int cost = isFree ? 0 : 80;

    if (state.tokens < cost) {
      _showOutOfTokensForJoker();
      return;
    }

    final nextTargetIndex = state.foundLetters.indexOf(null);
    if (nextTargetIndex == -1) return;

    final char = state.targetWord[nextTargetIndex];
    int gridIdx = -1;
    for (int i = 0; i < state.gridLetters.length; i++) {
      if (state.gridLetters[i] == char && !state.selectedIndices.contains(i)) {
        gridIdx = i;
        break;
      }
    }

    if (gridIdx != -1) {
      if (isForcedStep) {
        // 1. ADIM: Overlay'i anında kapat
        tutorialController.completeJokerStep('hint_joker_tutorial_completed');

        // 2. ADIM: Kart Dönme Animasyonu (600ms)
        state = state.copyWith(lastAttemptIndex: gridIdx, isLastAttemptCorrect: true);
        await Future.delayed(const Duration(milliseconds: 800));

        // 3. ADIM: Harf Uçuş Animasyonu (800ms)
        // Bu metodun bitmesini (harfin kutuya girmesini) bekliyoruz.
        await _handleCorrectSelection(gridIdx, nextTargetIndex, char);

        // --- DÜZELTME: Ekstra beklemeleri sildik, kontrolü tutorial metoduna devrettik ---
        // Bu metod kendi içinde 3 saniye 'Premium Bekleme' yapacak ve Yanlış Sil'e geçecek.
        await tutorialController.nextStepWithDelay(
          animationDuration: Duration.zero,
        );
      } else {
        // Normal oyun akışı...
        state = state.copyWith(lastAttemptIndex: gridIdx, isLastAttemptCorrect: true);
        await Future.delayed(const Duration(milliseconds: 800));
        await _handleCorrectSelection(gridIdx, nextTargetIndex, char);
      }

      state = state.copyWith(tokens: state.tokens - cost);
      if (isFree && !isForcedStep) {
        tutorialController.markFlag('free_hint_used');
      }
      _persist();
      _checkTokenStatus();
    }
  }

// --- YANLIŞ SİL JOKERİ ---
  Future<void> clearWrong() async {
    // State'i en güncel haliyle almak için notifier'ı okuyoruz
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);

    // Bu işlemin bir tutorial adımı olup olmadığını metodun başında mühürlüyoruz
    final bool isForcedStep = tutorialState.currentStep == TutorialStep.forcedClear;

    // Guard: Tutorial aktifse ve bu bizim beklediğimiz adım değilse işlem yapma
    if (tutorialState.removeJokerTutorialCompleted && isForcedStep) return;
    if (tutorialState.isTutorialActive && !isForcedStep) return;

    final bool isFree = isForcedStep || (!tutorialState.removeJokerTutorialCompleted && state.category != "Meyveler");
    final int cost = isFree ? 0 : 60;

    if (state.tokens < cost) {
      _showOutOfTokensForJoker();
      return;
    }

    // Silinecek yanlış harfleri bul
    List<int> toEliminate = [];
    for (int i = 0; i < state.gridLetters.length; i++) {
      if (!state.targetWord.contains(state.gridLetters[i]) &&
          !state.eliminatedIndices.contains(i)) {
        toEliminate.add(i);
      }
      if (toEliminate.length >= 3) break;
    }

    if (toEliminate.isNotEmpty) {
      if (isForcedStep) {
        // 1. Bayrağı işaretle ve spotlight'ı kapat
        tutorialController.completeJokerStep('remove_joker_tutorial_completed');

        // 2. Harfleri sil
        state = state.copyWith(
          tokens: state.tokens - 0, // Ücretsiz
          eliminatedIndices: [...state.eliminatedIndices, ...toEliminate],
          jokersUsedCount: state.jokersUsedCount + 1,
        );

        // 3. Efekti gör (Animasyon) ve 3-5 saniye bekle, sonra tamamen kapat
        await tutorialController.nextStepWithDelay(
          animationDuration: const Duration(milliseconds: 1000),
        );
      } else {
        // NORMAL OYUN AKIŞI
        state = state.copyWith(
          tokens: state.tokens - cost,
          eliminatedIndices: [...state.eliminatedIndices, ...toEliminate],
          jokersUsedCount: state.jokersUsedCount + 1,
          totalCategoryJokersCount: state.totalCategoryJokersCount + 1,
        );
      }

      _persist();
      _checkTokenStatus();
    }
  }

  Future<void> showAgain() async {
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);

    // Zorunlu adım mühürleme
    final bool isForcedStep = tutorialState.currentStep == TutorialStep.forcedReveal;

    // Koruma
    if (tutorialState.isTutorialActive && !isForcedStep) return;

    final bool isFree = isForcedStep || (!tutorialState.freeRevealUsed && state.category != "Meyveler");
    final int cost = isFree ? 0 : 40;

    if (state.tokens < cost) {
      _showOutOfTokensForJoker();
      return;
    }

    if (isForcedStep) {
      // 1. ANINDA SPOTLIGHT'I KAPAT
      // completeJokerStep metoduna 'reveal_joker_tutorial_completed' gönderin
      tutorialController.completeJokerStep('reveal_tutorial_shown');

    }

    // 2. KARTLARI AÇ (Animasyon başlar)
    state = state.copyWith(
      tokens: state.tokens - cost,
      isInitialReveal: true,
      jokersUsedCount: state.jokersUsedCount + 1,
    );

    if (isFree && !isForcedStep) {
      tutorialController.markFlag('free_reveal_used');
    }
    _persist();

    // 3. KARTLARIN AÇIK KALMA SÜRESİNİ BEKLE (4 Saniye)
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      state = state.copyWith(isInitialReveal: false);
      _persist();

      // 4. EĞİTİM ADIMINDAYSAK FİNAL EKRANINA GEÇ
      if (isForcedStep) {
        // Oyuncunun kartların kapandığını görmesi için 1 sn ek bekleme
        await Future.delayed(const Duration(seconds: 1));
        tutorialController.nextStep(); // TutorialStep.completed (Artık Hazırsın) ekranına gider
      }
    }
  }

  void _showOutOfTokensForJoker() {
    state = state.copyWith(showOutOfTokensPanel: true, isOutOfTokensDismissible: true);
    _persist();
  }

  static GameState _buildStateForWord({
    required String word,
    required String category,
    required int tokens,
    required List<String> completedCats,
    required int wordIdx,
    int streak = 0,
    int totalWrong = 0,
    int totalJokers = 0,
    int rewardTrigger = 0,
    int solvedWords = 0,
    int earnedTokens = 0,
    DateTime? lastRegen,
  }) {
    const alphabet = "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ";
    final List<String> letters = word.toUpperCase().split('');
    final random = Random();

    while (letters.length < 16) {
      String randomChar = alphabet[random.nextInt(alphabet.length)];
      if (!letters.contains(randomChar)) letters.add(randomChar);
    }
    letters.shuffle();

    final Set<int> hintIndices = {};
    final bool isTutorialWord = category == "Meyveler" && word.toUpperCase() == "ELMA";
    if (isTutorialWord) {
      // Sabit İpucu: E _ M _ (1. ve 3. harfler açık)
      hintIndices.addAll([0, 2]);
    }
    else{
      final int hintCount = word.length > 8 ? 3 : (word.length > 5 ? 2 : 1);
      while (hintIndices.length < hintCount) {
        hintIndices.add(random.nextInt(word.length));
      }
    }

    final List<String?> initialFound = List.filled(word.length, null);
    final List<int> selectedGridIndices = [];

    for (int hIdx in hintIndices) {
      final char = word[hIdx].toUpperCase();
      initialFound[hIdx] = char;
      for (int i = 0; i < letters.length; i++) {
        if (letters[i] == char && !selectedGridIndices.contains(i)) {
          selectedGridIndices.add(i);
          break;
        }
      }
    }

    return GameState(
      category: category, targetWord: word.toUpperCase(),
      gridLetters: letters, selectedIndices: selectedGridIndices,
      foundLetters: initialFound, isInitialReveal: true,
      hasStarted: false, tokens: tokens,
      completedCategories: completedCats, currentWordIndex: wordIdx,
      eliminatedIndices: [], showVictoryPanel: false,
      showGameFinishedPanel: false, totalSolvedWords: solvedWords,
      lastRewardTotal: 0, wrongAttemptsCount: 0, jokersUsedCount: 0,
      streak: streak, showCategoryCompletePanel: false,
      lastCompletedCategory: null, totalCategoryWrongCount: totalWrong,
      totalCategoryJokersCount: totalJokers, rewardTrigger: rewardTrigger,
      totalEarnedTokens: earnedTokens, showOutOfTokensPanel: false,
      isOutOfTokensDismissible: false, lastRegenTime: lastRegen ?? DateTime.now(),
    );
  }

  void startNextCategory() {
    state = state.copyWith(
      showCategoryCompletePanel: false,
      rewardTrigger: state.rewardTrigger + 1,
      totalCategoryWrongCount: 0,
      totalCategoryJokersCount: 0,
    );
    _loadNextWord();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final repository = ref.watch(gameRepositoryProvider);
  final adService = ref.watch(adServiceProvider);
  return GameNotifier(repository, adService, ref);
});