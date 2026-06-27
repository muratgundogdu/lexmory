import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core & Data
import '../../../core/app_constants.dart';

// Tutorial
import '../../missions/models/daily_mission.dart';
import '../../missions/providers/daily_mission_provider.dart';
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

  // 🎯 BUG 1 ÇÖZÜMÜ: Kelime zaferinin mükerrer tetiklenmesini engelleyen kilit (flag)
  bool _isWordVictoryProcessed = false;

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
    if (state.tokens >= AppConstants.maxRegenLimit) return;
    final now = DateTime.now();
    final difference = now.difference(state.lastRegenTime);
    if (difference.inSeconds >= AppConstants.regenInterval.inSeconds) {
      int cycles = (difference.inSeconds / AppConstants.regenInterval.inSeconds).floor();
      int totalRegen = cycles * AppConstants.regenAmount;
      int newTokens = (state.tokens + totalRegen).clamp(0, AppConstants.maxRegenLimit);
      DateTime updatedRegenTime = state.lastRegenTime.add(Duration(seconds: cycles * AppConstants.regenInterval.inSeconds));
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
        rewardTrigger: state.rewardTrigger + 1,
      );
      _persist();

      try {
        _ref.read(dailyMissionProvider.notifier).updateProgress(
          DailyMissionType.watchAds,
        );
      } catch (e) {
        debugPrint('Error updating daily mission for watchAds: $e');
      }
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
      hasClaimedDoubleReward: false,
      displayedCategoryBonus: 150,
      isClaimingDoubleReward: false,
    );
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTokens = prefs.getInt('user_tokens');
    final savedData = prefs.getString(_storageKey);
    final isTutorialCompleted = prefs.getBool('tutorial_completed') ?? false;

    if (!isTutorialCompleted) {
      state = _buildStateForWord(
        word: "ELMA",
        category: "Meyveler",
        tokens: savedTokens ?? 300,
        completedCats: [],
        wordIdx: 0,
      );
      _persist();
      return;
    }

    if (savedData != null) {
      try {
        state = GameState.fromJson(jsonDecode(savedData));

        if (savedTokens != null) {
          state = state.copyWith(tokens: savedTokens);
        }
        _checkOfflineRegeneration();
      } catch (e) {
        state = _createInitialState(_repository, existingTokens: savedTokens);
      }
    } else {
      state = _createInitialState(_repository, existingTokens: savedTokens);
    }

    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    await prefs.setInt('user_tokens', state.tokens);
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
      hasClaimedDoubleReward: false,
      displayedCategoryBonus: 150,
      isClaimingDoubleReward: false,
    );
  }

  // --- CORE GAME ACTIONS ---
  void startMemoryReveal() {
    if (state.hasStarted) return;

    state = state.copyWith(hasStarted: true, isInitialReveal: false);
    _persist();

    final tut = _ref.read(tutorialProvider);

    if (tut.phase == TutorialPhase.contextual &&
        tut.hintClearTutorialShown &&
        !tut.revealTutorialShown &&
        !tut.isTutorialActive &&
        state.category != "Meyveler") {
      state = state.copyWith(tutorialLock: true);
      _persist();
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

    // Eğer kelimede boş yer kalmadıysa ve bu kelime henüz işlenmediyse zaferi tetikle
    if (!newFound.contains(null) && !_isWordVictoryProcessed) {
      _handleWordVictory();
    }
  }

  Future<void> spendTokens(int amount) async {
    final int newTokens = state.tokens - amount;
    state = state.copyWith(tokens: newTokens);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_tokens', newTokens);
    await _persist();
  }

  Future<void> addTokens(int amount) async {
    if (amount <= 0) return;
    final int newTokens = state.tokens + amount;
    state = state.copyWith(
        tokens: newTokens,
        totalEarnedTokens: state.totalEarnedTokens + amount
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_tokens', newTokens);
    await _persist();
  }

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final int? savedTokens = prefs.getInt('user_tokens');

    if (savedTokens != null) {
      state = state.copyWith(tokens: savedTokens);
    }
  }

  Future<void> doubleRewardWithAd() async {
    if (state.hasClaimedDoubleReward || state.isClaimingDoubleReward) return;

    state = state.copyWith(isClaimingDoubleReward: true);
    _persist();

    const int adBonusAmount = 150;

    final bool success = await _adService.showRewardedAd();

    if (success) {
      state = state.copyWith(
        tokens: state.tokens + adBonusAmount,
        totalEarnedTokens: state.totalEarnedTokens + adBonusAmount,
        hasClaimedDoubleReward: true,
        displayedCategoryBonus: state.displayedCategoryBonus + adBonusAmount,
        lastRewardTotal: state.lastRewardTotal + adBonusAmount,
        isClaimingDoubleReward: false,
      );

      try {
        _ref.read(dailyMissionProvider.notifier).updateProgress(
          DailyMissionType.watchAds,
        );
      } catch (e) {
        debugPrint('Error updating daily mission for watchAds in doubleRewardWithAd: $e');
      }
    } else {
      state = state.copyWith(isClaimingDoubleReward: false);
    }
    _persist();
  }

  void resetCategoryCompletionStates() {
    state = state.copyWith(
      hasClaimedDoubleReward: false,
      displayedCategoryBonus: 150,
      isClaimingDoubleReward: false,
    );
    _persist();
  }

  void _handleWrongSelection(int gridIdx) async {
    final tut = _ref.read(tutorialProvider);
    final bool isFirstRealError = !tut.tokenTutorialShown && state.category != "Meyveler";
    final int tokenDeduction = isFirstRealError ? 0 : 5;

    HapticFeedback.mediumImpact();

    state = state.copyWith(
      tokens: max(0, state.tokens - tokenDeduction),
      lastAttemptIndex: gridIdx,
      isLastAttemptCorrect: false,
      wrongAttemptsCount: state.wrongAttemptsCount + 1,
      totalCategoryWrongCount: state.totalCategoryWrongCount + 1,
      streak: 0, // Anlık seri bozuldu
    );

    // 🎯 YENİ: Seri bozulduğu için günlük görevin iç sayacına sıfırlama sinyali yolluyoruz
    try {
      _ref.read(dailyMissionProvider.notifier).updateProgress(
        DailyMissionType.reachStreak,
        amount: -1, // 🚨 Görev sayacını sıfırla sinyali!
      );
    } catch (e) {
      debugPrint('Error resetting daily mission streak progress: $e');
    }

    // 🎯 BUG 2 ÇÖZÜMÜ: Seri bozulduğunda updateMaxProgress(..., 0) ÇIKARILDI!
    // Böylece max_streak aşağıya çekilmeyecek, mevcut rekor korunacak.

    _checkTokenStatus();

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      state = state.copyWith(lastAttemptIndex: null, isLastAttemptCorrect: null);
    }

    if (tut.hintJokerTutorialCompleted &&
        !tut.tokenTutorialShown &&
        state.category != "Meyveler") {

      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        _ref.read(tutorialProvider.notifier).showTokenTutorial();
      }
    }
  }

  void _handleWordVictory() async {
    if (_ref.read(tutorialProvider).isTutorialActive) return;

    // Kilit mekanizmasını aktif et, asenkron süreçte mükerrer tetiklenmeyi önle
    _isWordVictoryProcessed = true;

    int currentStreak = state.streak;
    bool isPerfect = state.wrongAttemptsCount == 0 && state.jokersUsedCount == 0;
    //currentStreak = isPerfect ? (currentStreak + 1).clamp(0, 5) : 0;
    currentStreak = isPerfect ? (currentStreak + 1) : 0;

    // 🎯 BUG 1 ÇÖZÜMÜ: Gerçek oyun olayında solveWords SADECE 1 kez çağrılır
    try {
      _ref.read(dailyMissionProvider.notifier).updateProgress(
        DailyMissionType.solveWords,
      );
    } catch (e) {
      debugPrint('Error updating daily mission for solveWords: $e');
    }

    // 🎯 BUG 2 ÇÖZÜMÜ: Seri rekorunu kontrol eden yeni 'updateProgress' çağrısı
    // (Metot adını 'updateProgress' yaptık ve anlık seriyi 'amount' olarak gönderdik)
    try {
      _ref.read(dailyMissionProvider.notifier).updateProgress(
        DailyMissionType.reachStreak,
        amount: currentStreak,
      );
    } catch (e) {
      debugPrint('Error updating daily mission for reachStreak: $e');
    }

    if (isPerfect) {
      try {
        _ref.read(dailyMissionProvider.notifier).updateProgress(
          DailyMissionType.solveWithoutWrong,
        );
      } catch (e) {
        debugPrint('Error updating daily mission for solveWithoutWrong: $e');
      }
    }

    if (state.jokersUsedCount == 0) {
      try {
        _ref.read(dailyMissionProvider.notifier).updateProgress(
          DailyMissionType.solveWithoutHint,
        );
      } catch (e) {
        debugPrint('Error updating daily mission for solveWithoutHint: $e');
      }
    }

    final reward = RewardCalculator.calculate(
      streak: min(currentStreak, 5),
      wrongCount: state.wrongAttemptsCount,
      jokerCount: state.jokersUsedCount,
    );

    final currentCatData = _repository.getCategoryByName(state.category);
    final List<String> words = _repository.getWordsForCategory(currentCatData);
    bool isCategoryLastWord = state.currentWordIndex + 1 >= words.length;

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) {
      _isWordVictoryProcessed = false;
      return;
    }

    if (isCategoryLastWord) {
      final int kelimeKazanci = reward.total;
      const int kategoriBonusuTaban = 150;
      final int toplamKazanc = kelimeKazanci + kategoriBonusuTaban;

      state = state.copyWith(
        tokens: state.tokens + toplamKazanc,
        showCategoryCompletePanel: true,
        lastRewardTotal: toplamKazanc,
        lastCompletedCategory: state.category,
        streak: currentStreak,
        totalSolvedWords: state.totalSolvedWords + 1,
        totalEarnedTokens: state.totalEarnedTokens + toplamKazanc,
        completedCategories: [...state.completedCategories, state.category],
        hasClaimedDoubleReward: false,
        displayedCategoryBonus: kategoriBonusuTaban,
        isClaimingDoubleReward: false,
      );
      await _persist();

      try {
        _ref.read(dailyMissionProvider.notifier).updateProgress(
          DailyMissionType.earnTokens,
          amount: toplamKazanc,
        );
      } catch (e) {
        debugPrint('Error updating daily mission for earnTokens (category complete): $e');
      }

      try {
        _ref.read(dailyMissionProvider.notifier).updateProgress(
          DailyMissionType.completeCategories,
        );
      } catch (e) {
        debugPrint('Error updating daily mission for completeCategories: $e');
      }

      // Kilidi yeni kelime döngüsünde açılmak üzere sıfırla
      _isWordVictoryProcessed = false;

    } else {
      state = state.copyWith(
        showVictoryPanel: true,
        lastRewardTotal: reward.total,
        tokens: state.tokens + reward.total,
        streak: currentStreak,
        rewardTrigger: state.rewardTrigger + 1,
        totalSolvedWords: state.totalSolvedWords + 1,
        totalEarnedTokens: state.totalEarnedTokens + reward.total,
      );
      await _persist();

      try {
        _ref.read(dailyMissionProvider.notifier).updateProgress(
          DailyMissionType.earnTokens,
          amount: reward.total,
        );
      } catch (e) {
        debugPrint('Error updating daily mission for earnTokens (word victory): $e');
      }

      await Future.delayed(const Duration(milliseconds: 4000));
      if (!mounted) {
        _isWordVictoryProcessed = false;
        return;
      }
      state = state.copyWith(showVictoryPanel: false);

      // Kilidi kaldır ve bir sonraki kelimeyi yükle
      _isWordVictoryProcessed = false;
      _loadNextWord();
    }
  }

  // --- JOKERS ---
  Future<void> useHint() async {
    if (state.tutorialLock) return;
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);
    final bool isForced = tutorialState.currentStep == TutorialStep.forcedHint;

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
        tutorialController.completeJokerStep('hint_joker_tutorial_completed');
      }

      state = state.copyWith(lastAttemptIndex: gridIdx, isLastAttemptCorrect: true);
      await Future.delayed(const Duration(milliseconds: 800));

      _handleCorrectSelection(gridIdx, nextTargetIndex, char);

      state = state.copyWith(
        tokens: state.tokens - cost,
        jokersUsedCount: state.jokersUsedCount + 1,
        totalCategoryJokersCount: state.totalCategoryJokersCount + 1,
      );

      // 🎯 BUG 1 ÇÖZÜMÜ: Joker kullanımında solveWords tetikleyen hatalı kod SİLİNDİ!

      if (isForced) {
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
        tutorialController.completeJokerStep('remove_joker_tutorial_completed');
      }

      state = state.copyWith(
        tokens: state.tokens - cost,
        eliminatedIndices: [...state.eliminatedIndices, ...toEliminate],
        jokersUsedCount: state.jokersUsedCount + 1,
        totalCategoryJokersCount: state.totalCategoryJokersCount + 1,
      );

      // 🎯 BUG 1 ÇÖZÜMÜ: Joker kullanımında solveWords tetikleyen hatalı kod SİLİNDİ!

      if (isForced) {
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
      tutorialController.completeJokerStep('reveal_tutorial_shown');
    }

    state = state.copyWith(
      tokens: state.tokens - cost,
      isInitialReveal: true,
      jokersUsedCount: state.jokersUsedCount + 1,
      totalCategoryJokersCount: state.totalCategoryJokersCount + 1,
      tutorialLock: isForced ? false : state.tutorialLock,
    );
    _persist();

    // 🎯 BUG 1 ÇÖZÜMÜ: Joker kullanımında solveWords tetikleyen hatalı kod SİLİNDİ!

    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      state = state.copyWith(isInitialReveal: false);
      _persist();

      if (isForced) {
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
        totalWrong: state.totalCategoryWrongCount,
        totalJokers: state.totalCategoryJokersCount,
        solvedWords: state.totalSolvedWords,
        earnedTokens: state.totalEarnedTokens,
        lastRegen: state.lastRegenTime,
        hasClaimedDoubleReward: state.hasClaimedDoubleReward,
        displayedCategoryBonus: state.displayedCategoryBonus,
        isClaimingDoubleReward: state.isClaimingDoubleReward,
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
        hasClaimedDoubleReward: false,
        displayedCategoryBonus: 150,
        isClaimingDoubleReward: false,
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
    state = state.copyWith(
      showCategoryCompletePanel: false,
      totalCategoryWrongCount: 0,
      totalCategoryJokersCount: 0,
    );
    resetCategoryCompletionStates();
    _loadNextWord();
  }

  void resetGame() {
    state = _createInitialState(_repository, existingTokens: state.tokens, lastRegen: state.lastRegenTime);
    resetCategoryCompletionStates();
    _persist();
  }

  void resetGameForTutorial() {
    state = _buildStateForWord(word: "ELMA", category: "Meyveler", tokens: 300, completedCats: [], wordIdx: 0);
    resetCategoryCompletionStates();
    _persist();
  }

  static GameState _buildStateForWord({
    required String word, required String category, required int tokens,
    required List<String> completedCats, required int wordIdx,
    int streak = 0, int totalWrong = 0, int totalJokers = 0,
    int rewardTrigger = 0, int solvedWords = 0, int earnedTokens = 0, DateTime? lastRegen,
    bool hasClaimedDoubleReward = false,
    int displayedCategoryBonus = 150,
    bool isClaimingDoubleReward = false,
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
      hasClaimedDoubleReward: hasClaimedDoubleReward,
      displayedCategoryBonus: displayedCategoryBonus,
      isClaimingDoubleReward: isClaimingDoubleReward,
    );
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final repository = ref.watch(gameRepositoryProvider);
  final adService = ref.watch(adServiceProvider);
  return GameNotifier(repository, adService, ref);
});