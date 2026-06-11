import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core & Data
import '../../../core/app_constants.dart';

// Tutorial
import '../../tutorial/models/tutorial_state.dart';
import '../../tutorial/providers/tutorial_provider.dart';

// Game Feature
import '../models/game_state.dart';
import '../services/ad_service.dart';
import '../services/reward_calculator.dart';
import '../repository/game_repository.dart';

final gameRepositoryProvider = Provider((ref) => GameRepository());
final adServiceProvider = Provider((ref) => AdService());

class GameNotifier extends StateNotifier<GameState> {
  final GameRepository _repository;
  final AdService _adService;
  final Ref _ref;

  static const String _storageKey = 'lexmory_save_game';
  Timer? _regenTimer;

  GameNotifier(this._repository, this._adService, this._ref) : super(_createPlaceholderState()) {
    _init();
    loadTokens();
  }
  Future<void> _init() async {
    await _loadFromStorage();
    _checkOfflineRegeneration();
    _startRegenTimer();
  }

  // --- TOKEN REGENERATION ---
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
    if (state.tokens < 5 && !state.showOutOfTokensPanel) {
      state = state.copyWith(showOutOfTokensPanel: true, isOutOfTokensDismissible: false);
      _persist();
    }
  }

  // --- AD SERVICES ---
  Future<void> watchAdForTokens() async {
    final bool success = await _adService.showRewardedAd();

    if (success) {
      int rewardAmount = state.pendingAdReward > 0 ? state.pendingAdReward : 50;

      state = state.copyWith(
        tokens: state.tokens + rewardAmount,
        showOutOfTokensPanel: false,
        pendingAdReward: 0,
        hasClaimedDoubleReward: true,
        rewardTrigger: state.rewardTrigger + 1,
      );
      _persist();
    }
  }

  // --- STATE PERSISTENCE ---
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
        category: "Meyveler",
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
    final selectedCatData = repository.getNextCategory([]);
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

    // BULDUM butonuna bastıktan 1 saniye sonra Tekrar (Reveal) Tanıtımı başlar
    if (tut.phase == TutorialPhase.contextual &&
        tut.hintClearTutorialShown &&
        !tut.revealTutorialShown &&
        !tut.isTutorialActive &&
        state.category != "Meyveler") {
      _ref.read(tutorialProvider.notifier).startForcedRevealOnboarding();
    }
  }

  void selectLetter(int index) async {
    if (state.tutorialLock) return;
    final tutorialState = _ref.read(tutorialProvider);

    if (tutorialState.isTutorialActive) {
      final tappedLetter = state.gridLetters[index];
      final nextTargetIndex = state.foundLetters.indexOf(null);

      if (nextTargetIndex != -1) {
        final expectedLetter = state.targetWord[nextTargetIndex];

        if (tappedLetter == expectedLetter) {
          _handleCorrectSelection(index, nextTargetIndex, tappedLetter);

          if (tutorialState.currentStep == TutorialStep.findingLetters ||
              tutorialState.currentStep == TutorialStep.phase2Play) {

            final isWordFinished = !state.foundLetters.contains(null);

            if (isWordFinished) {
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) _ref.read(tutorialProvider.notifier).nextStep();
              });
            } else {
              if (tutorialState.phase != TutorialPhase.phase2) {
                _ref.read(tutorialProvider.notifier).handleLetterSuccessFlow();
              }
            }
          }
        } else {
          HapticFeedback.lightImpact();
        }
      }
      return;
    }

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

  void _handleCorrectSelection(int gridIdx, int targetIdx, String letter) {
    final newFound = List<String?>.from(state.foundLetters);
    newFound[targetIdx] = letter;

    state = state.copyWith(
      lastAttemptIndex: gridIdx,
      isLastAttemptCorrect: true,
      justFoundIndex: targetIdx,
      selectedIndices: [...state.selectedIndices, gridIdx],
      foundLetters: newFound,
    );

    _persist();

    if (!newFound.contains(null)) {
      _handleWordVictory();
    }
  }

// lib/features/game/providers/game_provider.dart

// Dönüş tipini void yerine Future<void> yapın
  Future<void> spendTokens(int amount) async {
    final int currentTokens = state.tokens;
    final int newTokens = currentTokens - amount;

    // 1. UI'ı anında güncelle
    state = state.copyWith(tokens: newTokens);

    // 2. DISKE KAYDET
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_tokens', newTokens);

    // Persist metodunu da çağırarak genel state kaydını garantiye alın
    await _persist();
  }

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final int? savedTokens = prefs.getInt('user_tokens');

    if (savedTokens != null) {
      state = state.copyWith(tokens: savedTokens);
    }
  }

  void doubleRewardWithAd() {
    // Mevcut ödül kadar (150) ekleme yap
    state = state.copyWith(
      tokens: state.tokens + 150,
      // Reklam izlendiği için butonu gizlemek adına bir flag tutabilirsiniz
      hasClaimedDoubleReward: true,
    );
  }

  void resetDoubleReward() {
    state = state.copyWith(hasClaimedDoubleReward: false);
  }

  void _handleWrongSelection(int gridIdx) async {
    final tut = _ref.read(tutorialProvider);
    // KRİTİK DEĞİŞİKLİK: Eğer token tanıtımı henüz gösterilmediyse ve
    // eğitim kategorisinde değilsek (Gerçek oyunun ilk hatasıysa) token düşme.
    final bool isFirstRealError = !tut.tokenTutorialShown && state.category != "Meyveler";
    final int tokenDeduction = isFirstRealError ? 0 : 5;

    HapticFeedback.mediumImpact();

    state = state.copyWith(
      // Sadece tanıtım yapıldıysa 5 token eksiltir
      tokens: max(0, state.tokens - tokenDeduction),
      lastAttemptIndex: gridIdx,
      isLastAttemptCorrect: false,
      wrongAttemptsCount: state.wrongAttemptsCount + 1,
      totalCategoryWrongCount: state.totalCategoryWrongCount + 1,
      streak: 0, // Hata yapınca seri her zaman bozulur
    );

    _checkTokenStatus();

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      state = state.copyWith(lastAttemptIndex: null, isLastAttemptCorrect: null);
    }

    // Token Tanıtımı: İlk yanlışta tetiklenir
    if (tut.hintJokerTutorialCompleted &&
        !tut.tokenTutorialShown &&
        state.category != "Meyveler") {

      // Oyuncunun hatayı görmesi için kısa bir bekleme
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        _ref.read(tutorialProvider.notifier).showTokenTutorial();
      }
    }
  }

  void _handleWordVictory() async {
    if (_ref.read(tutorialProvider).isTutorialActive) return;

    int currentStreak = state.streak;
    bool isPerfect = state.wrongAttemptsCount == 0 && state.jokersUsedCount == 0;
    if (isPerfect) {
      currentStreak += 1;
    } else {
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

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (isCategoryLastWord) {
      state = state.copyWith(
        tokens: state.tokens + reward.total + 150,
        showCategoryCompletePanel: true,
        lastCompletedCategory: state.category,
        streak: currentStreak,
        totalSolvedWords: newTotalSolved,
        totalEarnedTokens: newTotalEarned + 150,
        completedCategories: [...state.completedCategories, state.category],
      );
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
    }
  }

  // --- JOKERS ---
  // --- HARF AÇ JOKERİ ---
  Future<void> useHint() async {
    if (state.tutorialLock) return;
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);
    final bool isForced = tutorialState.currentStep == TutorialStep.forcedHint;

    // Koruma: Tutorial aktifse ve doğru adımda değilsek işlem yapma
    if (tutorialState.isTutorialActive && !isForced) return;

    final bool isFree = isForced || (!tutorialState.freeHintUsed && state.category != "Meyveler");
    final int cost = isFree ? 0 : 80;

    if (state.tokens < cost) {
      _showOutOfTokensForJoker(cost);
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
      if (isForced) {
        // 1. Karartmayı anında kaldır (Harf animasyonu net görünsün)
        tutorialController.completeJokerStep('hint_joker_tutorial_completed');
      }

      // 2. Harf animasyonunu başlat
      state = state.copyWith(lastAttemptIndex: gridIdx, isLastAttemptCorrect: true);
      await Future.delayed(const Duration(milliseconds: 800));

      _handleCorrectSelection(gridIdx, nextTargetIndex, char);

      // 3. Token ve Sayaç güncelle
      state = state.copyWith(
        tokens: state.tokens - cost,
        jokersUsedCount: state.jokersUsedCount + 1,
        totalCategoryJokersCount: state.totalCategoryJokersCount + 1,
      );

      if (isForced) {
        // 4. Harf yerleşti, 1.5 saniye bekle ve Yanlış Sil'e geç (Gecikme tutorial_provider'da)
        await tutorialController.nextStepWithDelay(animationDuration: Duration.zero);
      }
      _persist();
    }
  }

  Future<void> clearWrong() async {
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);
    final bool isForced = tutorialState.currentStep == TutorialStep.forcedClear;

    if (tutorialState.isTutorialActive && !isForced) return;

    final bool isFree = isForced || (!tutorialState.removeJokerTutorialCompleted && state.category != "Meyveler");
    final int cost = isFree ? 0 : 60;

    if (state.tokens < cost) {
      _showOutOfTokensForJoker(cost);
      return;
    }

    List<int> toEliminate = [];
    for (int i = 0; i < state.gridLetters.length; i++) {
      if (!state.targetWord.contains(state.gridLetters[i]) && !state.eliminatedIndices.contains(i)) {
        toEliminate.add(i);
      }
      if (toEliminate.length >= 3) break;
    }

    if (toEliminate.isNotEmpty) {
      if (isForced) {
        // Spotlight'ı kapat
        tutorialController.completeJokerStep('remove_joker_tutorial_completed');
      }

      state = state.copyWith(
        tokens: state.tokens - cost,
        eliminatedIndices: [...state.eliminatedIndices, ...toEliminate],
        jokersUsedCount: state.jokersUsedCount + 1,
        totalCategoryJokersCount: state.totalCategoryJokersCount + 1,
      );

      if (isForced) {
        // Harfler silindi, tutorial_provider 1 saniye bekleyip tutorial'ı sonlandıracak
        await tutorialController.nextStepWithDelay(animationDuration: const Duration(milliseconds: 1000));
      }
      _persist();
    }
  }

  Future<void> showAgain() async {
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);
    final bool isForced = tutorialState.currentStep == TutorialStep.forcedReveal;

    if (tutorialState.isTutorialActive && !isForced) return;

    final bool isFree = isForced || (!tutorialState.freeRevealUsed && state.category != "Meyveler");
    final int cost = isFree ? 0 : 40;

    if (state.tokens < cost) {
      _showOutOfTokensForJoker(cost);
      return;
    }

    if (isForced) {
      // Spotlight'ı kapat
      tutorialController.completeJokerStep('reveal_tutorial_shown');
    }

    state = state.copyWith(
      tokens: state.tokens - cost,
      isInitialReveal: true,
      jokersUsedCount: state.jokersUsedCount + 1,
    );
    _persist();

    // Kartlar 4 saniye açık kalır
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      state = state.copyWith(isInitialReveal: false);
      _persist();

      if (isForced) {
        // Kartlar kapandı, 1 saniye bekle ve "Artık Hazırsın"a geç
        await Future.delayed(const Duration(seconds: 1));
        tutorialController.nextStep();
      }
    }
  }

  // --- HELPERS ---
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
        solvedWords: state.totalSolvedWords,
        earnedTokens: state.totalEarnedTokens,
        lastRegen: state.lastRegenTime,
      );
    } else {
      final currentCompleted = [...state.completedCategories, state.category];
      final nextCatData = _repository.getNextCategory(currentCompleted);

      state = _buildStateForWord(
        word: (nextCatData['words'] as List)[0],
        category: nextCatData['category'] as String,
        tokens: state.tokens,
        completedCats: currentCompleted,
        wordIdx: 0,
        streak: state.streak,
        solvedWords: state.totalSolvedWords,
        earnedTokens: state.totalEarnedTokens,
        lastRegen: state.lastRegenTime,
      );
    }
    _persist();
  }

  void _showOutOfTokensForJoker(int amount) {
    state = state.copyWith(showOutOfTokensPanel: true, isOutOfTokensDismissible: true, pendingAdReward: amount);
    _persist();
  }

  void closeOutOfTokensPanel() {
    state = state.copyWith(showOutOfTokensPanel: false);
    _persist();
  }

  void startNextCategory() {
    state = state.copyWith(showCategoryCompletePanel: false, totalCategoryWrongCount: 0, totalCategoryJokersCount: 0);
    _loadNextWord();
  }

  void resetGame() {
    state = _createInitialState(_repository, existingTokens: state.tokens, lastRegen: state.lastRegenTime);
    _persist();
  }

  void resetGameForTutorial() {
    state = _buildStateForWord(word: "ELMA", category: "Meyveler", tokens: 300, completedCats: [], wordIdx: 0);
    _persist();
  }

  static GameState _buildStateForWord({
    required String word, required String category, required int tokens,
    required List<String> completedCats, required int wordIdx,
    int streak = 0, int totalWrong = 0, int totalJokers = 0,
    int rewardTrigger = 0, int solvedWords = 0, int earnedTokens = 0, DateTime? lastRegen,
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
    if (category == "Meyveler" && word.toUpperCase() == "ELMA") {
      hintIndices.addAll([0, 2]);
    } else {
      final int hintCount = word.length > 8 ? 3 : (word.length > 5 ? 2 : 1);
      while (hintIndices.length < hintCount) hintIndices.add(random.nextInt(word.length));
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
      category: category, targetWord: word.toUpperCase(), gridLetters: letters,
      selectedIndices: selectedGridIndices, foundLetters: initialFound,
      isInitialReveal: true, hasStarted: false, tokens: tokens,
      completedCategories: completedCats, currentWordIndex: wordIdx,
      eliminatedIndices: [], showVictoryPanel: false, showGameFinishedPanel: false,
      totalSolvedWords: solvedWords, lastRewardTotal: 0, wrongAttemptsCount: 0,
      jokersUsedCount: 0, streak: streak, showCategoryCompletePanel: false,
      lastCompletedCategory: null, totalCategoryWrongCount: totalWrong,
      totalCategoryJokersCount: totalJokers, rewardTrigger: rewardTrigger,
      totalEarnedTokens: earnedTokens, showOutOfTokensPanel: false,
      isOutOfTokensDismissible: false, lastRegenTime: lastRegen ?? DateTime.now(),
    );
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final repository = ref.watch(gameRepositoryProvider);
  final adService = ref.watch(adServiceProvider);
  return GameNotifier(repository, adService, ref);
});