import 'dart:async';
import 'dart:math';
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
    final bool success = await _adService.showRewardedAd();

    if (success) {
      // Eğer pasif bir durumda (joker tıklamadan) reklam izlendiyse
      // veya miktar 0 ise default olarak 50 verelim.
      int rewardAmount = state.pendingAdReward > 0 ? state.pendingAdReward : 50;

      state = state.copyWith(
        tokens: state.tokens + rewardAmount,
        showOutOfTokensPanel: false,
        pendingAdReward: 0, // Ödül alındı, sıfırla
      );
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
// getRandomCategory yerine getNextCategory([]) kullanıyoruz (Henüz tamamlanan yok)
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
    // Sadece zorunlu eğitim adımlarında kilit varsa durdur (Opsiyonel)
    if (state.tutorialLock) return;

    final tutorialState = _ref.read(tutorialProvider);

    if (tutorialState.isTutorialActive) {
      // --- FAZ 2: SERBEST DENEYİM ---
      if (tutorialState.phase == TutorialPhase.phase2) {
        if (state.isInitialReveal || state.selectedIndices.contains(index) || !state.hasStarted) return;

        final tappedLetter = state.gridLetters[index];
        final nextTargetIndex = state.foundLetters.indexOf(null);

        if (nextTargetIndex != -1) {
          final expectedLetter = state.targetWord[nextTargetIndex];

          if (tappedLetter == expectedLetter) {
            // ANINDA İŞLE
            _handleCorrectSelection(index, nextTargetIndex, tappedLetter);

            final List<String?> checkList = [...state.foundLetters];
            checkList[nextTargetIndex] = tappedLetter;

            if (!checkList.contains(null)) {
              // Kelime bittiğinde çıkan popup için makul bir bekleme (Sadece burada bekleme kalsın)
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) _ref.read(tutorialProvider.notifier).nextStep();
              });
            }
          } else {
            HapticFeedback.lightImpact();
          }
        }
        return;
      }

      // --- FAZ 1: YÖNLENDİRMELİ EĞİTİM ---
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
                if (mounted) _ref.read(tutorialProvider.notifier).nextStep();
              });
            }
          }
        }
      }
      return;
    }

    // --- NORMAL OYUN MANTIĞI (TAMAMEN ANLIK) ---
    if (state.isInitialReveal || state.selectedIndices.contains(index) || !state.hasStarted) return;

    final tappedLetter = state.gridLetters[index];
    final nextTargetIndex = state.foundLetters.indexOf(null);

    if (nextTargetIndex == -1) return;

    if (tappedLetter == state.targetWord[nextTargetIndex]) {
      // Bekleme yok, kilit yok.
      _handleCorrectSelection(index, nextTargetIndex, tappedLetter);
    } else {
      _handleWrongSelection(index);
    }
  }

// lib/features/game/providers/game_provider.dart

  void _handleCorrectSelection(int gridIdx, int targetIdx, String letter) {
    // 1. Listeyi hemen kopyala ve güncelle
    final newFound = List<String?>.from(state.foundLetters);
    newFound[targetIdx] = letter;

    // 2. State'i tek seferde, kilit koymadan güncelle
    // tutorialLock her zaman false kalıyor, böylece input hiç kesilmiyor.
    state = state.copyWith(
      tutorialLock: false,
      lastAttemptIndex: gridIdx,
      isLastAttemptCorrect: true,
      justFoundIndex: targetIdx, // UI'daki pulse efektini tetikler
      selectedIndices: [...state.selectedIndices, gridIdx],
      foundLetters: newFound,
    );

    // Veriyi kaydet
    _persist();

    // 3. Bölüm bitti mi kontrol et
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

    bool isPerfectView = state.wrongAttemptsCount == 0 && state.jokersUsedCount == 0;

    if (isPerfectView) {
      // Hiç hata yok, hiç joker yok -> Seri artar
      currentStreak += 1;
    } else {
      // Hata VEYA joker varsa -> Seri bozulur (sıfırlanır)
      // Eğer serinin sadece hatada bozulmasını istiyorsan burayı eski halinde bırakabilirsin.
      // Ama joker kullanımı "Perfect" seri mantığına aykırıdır.
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
      // AYNI KATEGORİDE SIRADAKİ KELİMEYE GEÇ
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
      final currentCompleted = [...state.completedCategories, state.category];

      final nextCatData = _repository.getNextCategory(currentCompleted);

      state = _buildStateForWord(
        word: (nextCatData['words'] as List)[0],
        category: nextCatData['category'] as String,
        tokens: state.tokens,
        completedCats: currentCompleted,
        wordIdx: 0,
        streak: state.streak,
        rewardTrigger: state.rewardTrigger,
        solvedWords: state.totalSolvedWords,
        earnedTokens: state.totalEarnedTokens,
        lastRegen: state.lastRegenTime,
      );
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
  Future<void> useHint() async {
    if (state.tutorialLock) return;
    final tutorialController = _ref.read(tutorialProvider.notifier);
    final tutorialState = _ref.read(tutorialProvider);

    final bool isForcedStep = tutorialState.currentStep == TutorialStep.forcedHint;

    // Koruma: Tutorial aktifse ve doğru adımda değilsek işlem yapma
    if (tutorialState.isTutorialActive && tutorialState.phase != TutorialPhase.contextual) return;
    if (tutorialState.isTutorialActive && !isForcedStep) return;

    final bool isFree = isForcedStep || (!tutorialState.freeHintUsed && state.category != "Meyveler");
    final int cost = isFree ? 0 : 80;

    if (state.tokens < cost) {
      _showOutOfTokensForJoker(cost); // cost burada 80'dir
      return;
    }

    final nextTargetIndex = state.foundLetters.indexOf(null);
    if (nextTargetIndex == -1) return;

    final char = state.targetWord[nextTargetIndex];
    int gridIdx = -1;

    // Grid içinde harfin yerini bul
    for (int i = 0; i < state.gridLetters.length; i++) {
      if (state.gridLetters[i] == char && !state.selectedIndices.contains(i)) {
        gridIdx = i;
        break;
      }
    }

    if (gridIdx != -1) {
      if (isForcedStep) {
        // --- TUTORIAL AKIŞI ---
        // 1. Overlay'i anında kapat
        tutorialController.completeJokerStep('hint_joker_tutorial_completed');

        // 2. Kart Dönme Animasyonu Beklemesi (Görsel feedback için)
        state = state.copyWith(lastAttemptIndex: gridIdx, isLastAttemptCorrect: true);
        await Future.delayed(const Duration(milliseconds: 800));

        // 3. Harfi anında yerleştir (HandleCorrectSelection artık void olduğu için await yok)
        _handleCorrectSelection(gridIdx, nextTargetIndex, char);

        // Tutorial bir sonraki adıma (Yanlış Sil) geçsin
        await tutorialController.nextStepWithDelay(
          animationDuration: Duration.zero,
        );
      } else {
        // --- NORMAL OYUN AKIŞI ---
        state = state.copyWith(lastAttemptIndex: gridIdx, isLastAttemptCorrect: true);
        await Future.delayed(const Duration(milliseconds: 800));

        // Harfi anında yerleştir
        _handleCorrectSelection(gridIdx, nextTargetIndex, char);
      }

      // --- KRİTİK SAYAÇ GÜNCELLEMELERİ ---
      // Bu kısım RewardCalculator'ın joker kullanıldığını anlamasını sağlar
      state = state.copyWith(
        tokens: state.tokens - cost,
        jokersUsedCount: state.jokersUsedCount + 1, // Ödül panelinde bonusu düşürür
        totalCategoryJokersCount: state.totalCategoryJokersCount + 1, // İstatistikler için
      );

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
      _showOutOfTokensForJoker(cost); // cost burada 60'tır
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
      _showOutOfTokensForJoker(cost); // cost burada 40'tır
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

  void _showOutOfTokensForJoker(int amount) {
    state = state.copyWith(
      showOutOfTokensPanel: true,
      isOutOfTokensDismissible: true,
      pendingAdReward: amount, // Hangi joker için açıldıysa o miktarı kaydet
    );
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