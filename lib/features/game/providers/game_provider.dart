import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Core & Data
import '../../../core/app_constants.dart';
import '../../../core/services/game_audio_service.dart';

// Tutorial
import '../../missions/models/daily_mission.dart';
import '../../missions/providers/daily_mission_provider.dart';
import '../../library/models/chest_reward_source.dart';
import '../../library/models/reward_presentation_event.dart';
import '../../library/provider/collection_provider.dart';
import '../../library/provider/reward_queue_provider.dart';
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
  bool _isJokerActionInProgress = false;

  GameNotifier(this._repository, this._adService, this._ref) : super(_createPlaceholderState()) {
    init();
  }

  @protected
  Future<void> init() async {
    await _loadFromStorage();
    await loadTokens(); // Sequence ensured

    _checkOfflineRegeneration();
    startRegenTimer();
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
      persist();
    }
  }

  @visibleForTesting
  void startRegenTimer() {
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
    persist();
  }

  void _checkTokenStatus() {
    if (state.tokens < 5 && !state.showOutOfTokensPanel) {
      state = state.copyWith(showOutOfTokensPanel: true, isOutOfTokensDismissible: false);
      persist();
    }
  }

  // --- AD SERVICES ---
  Future<void> watchAdForTokens() async {
    final bool success = await _adService.showRewardedAd();

    if (success) {
      if (!mounted) return;
      int rewardAmount = state.pendingAdReward > 0 ? state.pendingAdReward : 50;

      state = state.copyWith(
        tokens: state.tokens + rewardAmount,
        showOutOfTokensPanel: false,
        pendingAdReward: 0,
        rewardTrigger: state.rewardTrigger + 1,
      );
      persist();

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
      foundLetters: [], isInitialReveal: true, hasStarted: false, tokens: AppConstants.initialTokens,
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
      final tutorialCat = _repository.getCategoryByName("Meyveler");
      state = _buildStateForWord(
        word: "ELMA",
        category: "Meyveler",
        tokens: savedTokens ?? AppConstants.initialTokens,
        completedCats: [],
        wordIdx: 0,
        categoryWords: List<String>.from(tutorialCat['words'] as List),
      );
      persist();
      return;
    }

    if (savedData != null) {
      try {
        final loaded = GameState.fromJson(jsonDecode(savedData));
        if (!mounted) return;
        state = loaded;

        if (savedTokens != null) {
          state = state.copyWith(tokens: savedTokens);
        }
        
        _checkOfflineRegeneration();
      } catch (e) {
        if (!mounted) return;
        state = _createInitialState(_repository, existingTokens: savedTokens);
      }
    } else {
      if (!mounted) return;
      state = _createInitialState(_repository, existingTokens: savedTokens);
    }

    persist();
  }

  @protected
  Future<void> persist() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    // persist tokens separately to avoid sync issues
    await prefs.setInt('user_tokens', state.tokens);
  }

  static GameState _createInitialState(GameRepository repository, {
    int? existingTokens, 
    DateTime? lastRegen,
    int hintInventory = 0,
    int removeWrongInventory = 0,
  }) {
    final selectedCatData = repository.getNextCategory([]);
    final String catName = selectedCatData['category'] as String;
    final List<String> words = repository.getWordsForCategory(selectedCatData);

    return _buildStateForWord(
      word: words[0],
      category: catName,
      tokens: existingTokens ?? AppConstants.initialTokens,
      lastRegen: lastRegen ?? DateTime.now(),
      hintInventory: hintInventory,
      removeWrongInventory: removeWrongInventory,
      completedCats: [],
      wordIdx: 0,
      solvedWords: 0,
      earnedTokens: 0,
      hasClaimedDoubleReward: false,
      displayedCategoryBonus: 150,
      isClaimingDoubleReward: false,
      categoryWords: words,
    );
  }

  // --- CORE GAME ACTIONS ---
  void startMemoryReveal() {
    if (state.hasStarted) return;

    _ref.read(gameAudioServiceProvider).playBoardTransition();
    state = state.copyWith(hasStarted: true, isInitialReveal: false);
    persist();

    final tut = _ref.read(tutorialProvider);

    if (tut.onboardingStep == RealGameOnboardingStep.waitingForFoundButton &&
        !tut.isTutorialActive &&
        state.category != "Meyveler") {
      state = state.copyWith(tutorialLock: true);
      persist();
      _ref.read(tutorialProvider.notifier).triggerRevealJokerStep();
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
          _ref.read(gameAudioServiceProvider).playWrongTap();
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
    _ref.read(gameAudioServiceProvider).playCardFlip();
    final newFound = List<String?>.from(state.foundLetters);
    newFound[targetIdx] = letter;

    state = state.copyWith(
      lastAttemptIndex: gridIdx,
      isLastAttemptCorrect: true,
      justFoundIndex: targetIdx,
      selectedIndices: [...state.selectedIndices, gridIdx],
      foundLetters: newFound,
    );

    persist();

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
    await persist();
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
    await persist();
  }

  Future<void> addJokers({int hints = 0, int removeWrongs = 0}) async {
    state = state.copyWith(
      hintInventory: state.hintInventory + hints,
      removeWrongInventory: state.removeWrongInventory + removeWrongs,
    );
    await persist();
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
    persist();

    const int adBonusAmount = 150;

    final bool success = await _adService.showRewardedAd();

    if (success) {
      if (!mounted) return;
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
      if (!mounted) return;
      state = state.copyWith(isClaimingDoubleReward: false);
    }
    await persist();
  }

  void resetCategoryCompletionStates() {
    state = state.copyWith(
      hasClaimedDoubleReward: false,
      displayedCategoryBonus: 150,
      isClaimingDoubleReward: false,
    );
    persist();
  }

  void _handleWrongSelection(int gridIdx) async {
    _ref.read(gameAudioServiceProvider).playWrongTap();
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

    _checkTokenStatus();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    state = state.copyWith(lastAttemptIndex: null, isLastAttemptCorrect: null);

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
    currentStreak = isPerfect ? (currentStreak + 1) : 0;

    // 🎯 BUG 1 ÇÖZÜMÜ: Gerçek oyun olayında solveWords SADECE 1 kez çağrılır
    try {
      _ref.read(dailyMissionProvider.notifier).updateProgress(
        DailyMissionType.solveWords,
      );
    } catch (e) {
      debugPrint('Error updating daily mission for solveWords: $e');
    }

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

      final bool isFirstTimeCompletion = !state.completedCategories.contains(state.category);

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
      await persist();

      if (isFirstTimeCompletion) {
        try {
          final result = await _ref.read(collectionProvider.notifier).openChestReward(ChestRewardSource.categoryCompletion);
          
          _ref.read(rewardQueueProvider.notifier).enqueue(RewardPresentationEvent(
            id: 'cat_${state.category}_${DateTime.now().millisecondsSinceEpoch}',
            source: ChestRewardSource.categoryCompletion,
            result: result,
            createdAt: DateTime.now(),
            title: 'Kategori Tamamlandı!',
            subtitle: state.category,
          ));

          state = state.copyWith(categoryRewardResult: result);
          await persist();
        } catch (e) {
          debugPrint('Failed to open category chest reward: $e');
        }
      }

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
      await persist();

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
    if (_isJokerActionInProgress) return;
    
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);
    final bool isForced = tutorialState.currentStep == TutorialStep.forcedHint;

    if (state.tutorialLock && !isForced) return;
    if (tutorialState.isTutorialActive && !isForced) return;

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

    if (gridIdx == -1) return;

    _isJokerActionInProgress = true;
    try {
      if (isForced) {
        tutorialController.onHintJokerActionStarted();
      }

      // Phase 1: Visual feedback
      state = state.copyWith(lastAttemptIndex: gridIdx, isLastAttemptCorrect: true);
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Phase 2: Atomic State Update
      _ref.read(gameAudioServiceProvider).playCardFlip();
      
      final current = state; // Fresh read
      final tutorial = _ref.read(tutorialProvider); // Fresh read

      final bool isTutorialFreebie = !tutorial.freeHintUsed && current.category != "Meyveler" && current.category.isNotEmpty;
      final bool isTutorialCategory = current.category == "Meyveler";
      final bool hasInventory = current.hintInventory > 0;
      
      int nextInventory = current.hintInventory;
      int finalCost = 80;

      if (isForced || isTutorialFreebie || isTutorialCategory) {
        finalCost = 0;
      } else if (hasInventory) {
        finalCost = 0;
        nextInventory--;
      }

      if (current.tokens < finalCost) {
        _showOutOfTokensForJoker(finalCost);
        return;
      }

      final newFound = List<String?>.from(current.foundLetters);
      newFound[nextTargetIndex] = char;

      state = current.copyWith(
        lastAttemptIndex: gridIdx,
        isLastAttemptCorrect: true,
        justFoundIndex: nextTargetIndex,
        selectedIndices: [...current.selectedIndices, gridIdx],
        foundLetters: newFound,
        tokens: current.tokens - finalCost,
        hintInventory: nextInventory,
        jokersUsedCount: current.jokersUsedCount + 1,
        totalCategoryJokersCount: current.totalCategoryJokersCount + 1,
      );

      if (isTutorialFreebie) {
        tutorialController.markFlag('free_hint_used');
      }

      await persist();

      if (!newFound.contains(null) && !_isWordVictoryProcessed) {
        _handleWordVictory();
      }

      if (isForced) {
        await tutorialController.onHintJokerActionCompleted();
      }
    } finally {
      _isJokerActionInProgress = false;
    }
  }

  Future<void> clearWrong() async {
    if (_isJokerActionInProgress) return;

    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);
    final bool isForced = tutorialState.currentStep == TutorialStep.forcedClear;

    if (state.tutorialLock && !isForced) return;
    if (tutorialState.isTutorialActive && !isForced) return;

    List<int> toEliminate = [];
    for (int i = 0; i < state.gridLetters.length; i++) {
      if (!state.targetWord.contains(state.gridLetters[i]) && !state.eliminatedIndices.contains(i)) {
        toEliminate.add(i);
      }
      if (toEliminate.length >= 3) break;
    }

    if (toEliminate.isEmpty) return;

    _isJokerActionInProgress = true;
    try {
      if (isForced) {
        tutorialController.onClearJokerActionStarted();
      }

      _ref.read(gameAudioServiceProvider).playRemoveWrongJoker();
      
      final current = state; // Fresh read
      final tutorial = _ref.read(tutorialProvider); // Fresh read

      final bool isTutorialFreebie = !tutorial.freeRemoveUsed && current.category != "Meyveler" && current.category.isNotEmpty;
      final bool isTutorialCategory = current.category == "Meyveler";
      final bool hasInventory = current.removeWrongInventory > 0;

      int nextInventory = current.removeWrongInventory;
      int finalCost = 60;

      if (isForced || isTutorialFreebie || isTutorialCategory) {
        finalCost = 0;
      } else if (hasInventory) {
        finalCost = 0;
        nextInventory--;
      }

      if (current.tokens < finalCost) {
        _showOutOfTokensForJoker(finalCost);
        return;
      }

      state = current.copyWith(
        tokens: current.tokens - finalCost,
        removeWrongInventory: nextInventory,
        eliminatedIndices: [...current.eliminatedIndices, ...toEliminate],
        jokersUsedCount: current.jokersUsedCount + 1,
        totalCategoryJokersCount: current.totalCategoryJokersCount + 1,
      );

      if (isTutorialFreebie) {
        tutorialController.markFlag('free_remove_used');
      }

      await persist();

      await Future.delayed(const Duration(milliseconds: 1000));

      if (isForced) {
        await tutorialController.onClearJokerActionCompleted();
      }
    } finally {
      _isJokerActionInProgress = false;
    }
  }

  Future<void> showAgain() async {
    if (_isJokerActionInProgress) return;

    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);
    final bool isForced = tutorialState.currentStep == TutorialStep.forcedReveal;

    if (state.tutorialLock && !isForced) return;
    if (tutorialState.isTutorialActive && !isForced) return;

    final bool isTutorialFreebie = !tutorialState.freeRevealUsed && state.category != "Meyveler" && state.category.isNotEmpty;
    final bool isTutorialCategory = state.category == "Meyveler";
    final bool isFree = isForced || isTutorialFreebie || isTutorialCategory;
    final int cost = isFree ? 0 : 40;

    if (state.tokens < cost) {
      _showOutOfTokensForJoker(cost);
      return;
    }

    _isJokerActionInProgress = true;
    try {
      if (isForced) {
        tutorialController.onRevealJokerActionStarted();
      }

      _ref.read(gameAudioServiceProvider).playBoardTransition();
      
      final current = state;
      state = current.copyWith(
        tokens: current.tokens - cost,
        isInitialReveal: true,
        jokersUsedCount: current.jokersUsedCount + 1,
        totalCategoryJokersCount: current.totalCategoryJokersCount + 1,
        tutorialLock: isForced ? false : current.tutorialLock,
      );

      if (isTutorialFreebie) {
        tutorialController.markFlag('free_reveal_used');
      }

      await persist();

      await Future.delayed(const Duration(seconds: 4));

      if (!mounted) return;
      _ref.read(gameAudioServiceProvider).playBoardTransition();
      state = state.copyWith(isInitialReveal: false);
      await persist();

      if (isForced) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          await tutorialController.onRevealJokerActionCompleted();
        }
      }
    } finally {
      _isJokerActionInProgress = false;
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
        hintInventory: state.hintInventory,
        removeWrongInventory: state.removeWrongInventory,
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
        categoryWords: words,
      );
    } else {
      final currentCompleted = [...state.completedCategories, state.category];
      final nextCatData = _repository.getNextCategory(currentCompleted);
      final nextWords = _repository.getWordsForCategory(nextCatData);

      state = _buildStateForWord(
        word: nextWords[0],
        category: nextCatData['category'] as String,
        tokens: state.tokens,
        hintInventory: state.hintInventory,
        removeWrongInventory: state.removeWrongInventory,
        completedCats: currentCompleted,
        wordIdx: 0,
        streak: state.streak,
        solvedWords: state.totalSolvedWords,
        earnedTokens: state.totalEarnedTokens,
        lastRegen: state.lastRegenTime,
        hasClaimedDoubleReward: false,
        displayedCategoryBonus: 150,
        isClaimingDoubleReward: false,
        categoryWords: nextWords,
      );
    }
    persist();
  }

  void _showOutOfTokensForJoker(int amount) {
    state = state.copyWith(showOutOfTokensPanel: true, isOutOfTokensDismissible: true, pendingAdReward: amount);
    persist();
  }

  void closeOutOfTokensPanel() {
    state = state.copyWith(showOutOfTokensPanel: false);
    persist();
  }

  void startNextCategory() {
    state = state.copyWith(
      showCategoryCompletePanel: false,
      totalCategoryWrongCount: 0,
      totalCategoryJokersCount: 0,
      categoryRewardResult: null,
    );
    resetCategoryCompletionStates();
    _loadNextWord();
  }

  void resetGame() {
    state = _createInitialState(
      _repository, 
      existingTokens: state.tokens, 
      lastRegen: state.lastRegenTime,
      hintInventory: state.hintInventory,
      removeWrongInventory: state.removeWrongInventory,
    );
    resetCategoryCompletionStates();
    persist();
  }

  void resetGameForTutorial() {
    final tutorialCat = _repository.getCategoryByName("Meyveler");
    state = _buildStateForWord(
      word: "ELMA",
      category: "Meyveler",
      tokens: 300,
      hintInventory: state.hintInventory,
      removeWrongInventory: state.removeWrongInventory,
      completedCats: [],
      wordIdx: 0,
      categoryWords: List<String>.from(tutorialCat['words'] as List),
    );
    resetCategoryCompletionStates();
    persist();
  }

  static GameState _buildStateForWord({
    required String word, required String category, required int tokens,
    required List<String> completedCats, required int wordIdx,
    required List<String> categoryWords,
    int hintInventory = 0,
    int removeWrongInventory = 0,
    int streak = 0, int totalWrong = 0, int totalJokers = 0,
    int rewardTrigger = 0, int solvedWords = 0, int earnedTokens = 0, DateTime? lastRegen,
    bool hasClaimedDoubleReward = false,
    int displayedCategoryBonus = 150,
    bool isClaimingDoubleReward = false,
  }) {
    const alphabet = "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ";
    final targetUpper = word.toUpperCase();
    final targetChars = targetUpper.characters.toList();
    final int targetLen = targetChars.length;
    
    final random = Random();
    final List<String> gridLetters = [...targetChars];

    while (gridLetters.length < 16) {
      String randomChar = alphabet[random.nextInt(alphabet.length)];
      if (!gridLetters.contains(randomChar)) gridLetters.add(randomChar);
    }
    gridLetters.shuffle();

    final Set<int> hintIndices = {};
    if (category == "Meyveler" && targetUpper == "ELMA") {
      hintIndices.addAll([0, 2]);
    } else {
      final int hintCount = targetLen >= 10 ? 4 : (targetLen >= 8 ? 3 : (targetLen >= 5 ? 2 : 1));
      while (hintIndices.length < hintCount) {
        hintIndices.add(random.nextInt(targetLen));
      }
    }

    // --- Çakışma Çözümleme (Conflict Resolution) ---
    final potentialConflicts = categoryWords
        .map((w) => w.toUpperCase())
        .where((w) => w != targetUpper && w.characters.length == targetLen)
        .map((w) => w.characters.toList())
        .toList();

    if (potentialConflicts.isNotEmpty) {
      bool ambiguityResolved = false;
      int maxAttempts = 10;
      while (!ambiguityResolved && maxAttempts > 0) {
        maxAttempts--;
        ambiguityResolved = true;
        
        for (final conflict in potentialConflicts) {
          // 1. Mevcut ipuçları ile eşleşiyor mu? (Positional match)
          bool matchesHints = true;
          for (int hIdx in hintIndices) {
            if (conflict[hIdx] != targetChars[hIdx]) {
              matchesHints = false;
              break;
            }
          }

          if (matchesHints) {
            // 2. Kalan harfleri grid'den oluşturulabiliyor mu?
            // Revealed harfler grid'den tüketilir, bu yüzden kalanları kontrol etmeliyiz.
            final List<String> remainingGrid = List.from(gridLetters);
            // Revealed harfleri grid'den çıkar
            for (int hIdx in hintIndices) {
              remainingGrid.remove(targetChars[hIdx]);
            }
            
            // Conflict word'ün REVEAL EDİLMEMİŞ harflerini grid'den çıkarabiliyor muyuz?
            bool canBeFormed = true;
            for (int i = 0; i < targetLen; i++) {
              if (!hintIndices.contains(i)) {
                if (!remainingGrid.remove(conflict[i])) {
                  canBeFormed = false;
                  break;
                }
              }
            }

            if (canBeFormed) {
              // Belirsizlik var: Ayırt edici bir harf aç
              int diffIdx = -1;
              for (int i = 0; i < targetLen; i++) {
                if (!hintIndices.contains(i) && targetChars[i] != conflict[i]) {
                  diffIdx = i;
                  break;
                }
              }

              if (diffIdx != -1) {
                hintIndices.add(diffIdx);
                ambiguityResolved = false;
                break;
              }
            }
          }
        }
      }
    }
    // ----------------------------------------------

    final List<String?> initialFound = List.filled(targetLen, null);
    final List<int> selectedGridIndices = [];

    for (int hIdx in hintIndices) {
      final char = targetChars[hIdx];
      initialFound[hIdx] = char;
      for (int i = 0; i < gridLetters.length; i++) {
        if (gridLetters[i] == char && !selectedGridIndices.contains(i)) {
          selectedGridIndices.add(i);
          break;
        }
      }
    }

    return GameState(
      category: category, 
      targetWord: targetUpper, 
      gridLetters: gridLetters,
      selectedIndices: selectedGridIndices, 
      foundLetters: initialFound,
      isInitialReveal: true, 
      hasStarted: false, 
      tokens: tokens,
      hintInventory: hintInventory,
      removeWrongInventory: removeWrongInventory,
      completedCategories: completedCats, 
      currentWordIndex: wordIdx,
      eliminatedIndices: [], 
      showVictoryPanel: false, 
      showGameFinishedPanel: false,
      totalSolvedWords: solvedWords, 
      lastRewardTotal: 0, 
      wrongAttemptsCount: 0,
      jokersUsedCount: 0, 
      streak: streak, 
      showCategoryCompletePanel: false,
      lastCompletedCategory: null, 
      totalCategoryWrongCount: totalWrong,
      totalCategoryJokersCount: totalJokers, 
      rewardTrigger: rewardTrigger,
      totalEarnedTokens: earnedTokens, 
      showOutOfTokensPanel: false,
      isOutOfTokensDismissible: false, 
      lastRegenTime: lastRegen ?? DateTime.now(),
      hasClaimedDoubleReward: hasClaimedDoubleReward,
      displayedCategoryBonus: displayedCategoryBonus,
      isClaimingDoubleReward: isClaimingDoubleReward,
    );
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final repository = ref.watch(gameRepositoryProvider);
  final adService = ref.watch(adServiceProvider);
  return GameNotifier(repository, adService, ref);
});
