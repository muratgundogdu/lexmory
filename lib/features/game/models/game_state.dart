
/// Ödül detaylarını tutan veri modeli
class RewardData {
  final int base;
  final int memoryBonus;
  final int masterBonus;
  final double multiplier;
  final int total;

  const RewardData({
    required this.base,
    required this.memoryBonus,
    required this.masterBonus,
    required this.multiplier,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
    'base': base,
    'memoryBonus': memoryBonus,
    'masterBonus': masterBonus,
    'multiplier': multiplier,
    'total': total,
  };

  factory RewardData.fromJson(Map<String, dynamic> json) => RewardData(
    base: json['base'],
    memoryBonus: json['memoryBonus'],
    masterBonus: json['masterBonus'],
    multiplier: (json['multiplier'] as num).toDouble(),
    total: json['total'],
  );
}

/// Oyunun tüm anlık durumunu temsil eden ana sınıf
class GameState {
  // Temel Oyun Verileri
  final String category;
  final String targetWord;
  final List<String> gridLetters;
  final List<int> selectedIndices;
  final List<String?> foundLetters;

  // Durum Bayrakları
  final bool isInitialReveal;
  final bool hasStarted;
  final bool showVictoryPanel;
  final bool showCategoryCompletePanel;
  final bool showOutOfTokensPanel;
  final bool showGameFinishedPanel;
  final bool isOutOfTokensDismissible;
  final bool letterJustSettled;
  final bool tutorialLock;

  // Ekonomi ve Puanlama
  final int tokens;
  final int streak;
  final int lastRewardTotal;
  final int wrongAttemptsCount;
  final int jokersUsedCount;
  final RewardData? lastReward;
  final DateTime lastRegenTime;

  // Etkileşim ve Animasyon Tetikleyicileri
  final int? lastAttemptIndex;
  final bool? isLastAttemptCorrect;
  final int? justFoundIndex;
  final int rewardTrigger;

  // İlerleme ve Jokerler
  final List<String> completedCategories;
  final int currentWordIndex;
  final List<int> eliminatedIndices;
  final String? lastCompletedCategory;
  final int totalCategoryWrongCount;
  final int totalCategoryJokersCount;
  final int totalSolvedWords;
  final int totalEarnedTokens;

  // Reklam ve Ödül Durumları
  final bool hasClaimedDoubleReward; // Mevcut
  final int pendingAdReward;

  // YENİ EKLENEN ALANLAR
  final int displayedCategoryBonus; // UI'da gösterilen kategori bonusu (150 veya 300)
  final bool isClaimingDoubleReward; // x2 reklamın şu anda izlenip izlenmediğini belirtir (loading UI)

  const GameState({
    required this.category,
    required this.targetWord,
    required this.gridLetters,
    required this.selectedIndices,
    required this.foundLetters,
    required this.isInitialReveal,
    required this.hasStarted,
    required this.tokens,
    required this.completedCategories,
    required this.currentWordIndex,
    required this.eliminatedIndices,
    required this.wrongAttemptsCount,
    required this.jokersUsedCount,
    required this.streak,
    required this.showVictoryPanel,
    required this.lastRewardTotal,
    required this.showCategoryCompletePanel,
    required this.totalCategoryWrongCount,
    required this.totalCategoryJokersCount,
    required this.showGameFinishedPanel,
    required this.totalSolvedWords,
    required this.totalEarnedTokens,
    required this.showOutOfTokensPanel,
    required this.isOutOfTokensDismissible,
    required this.lastRegenTime,
    this.letterJustSettled = false,
    this.tutorialLock = false,
    this.lastAttemptIndex,
    this.isLastAttemptCorrect,
    this.justFoundIndex,
    this.rewardTrigger = 0,
    this.lastReward,
    this.lastCompletedCategory,
    this.pendingAdReward = 0,
    this.hasClaimedDoubleReward = false, // Mevcut
    // YENİ ALANLAR İÇİN BAŞLANGIÇ DEĞERLERİ
    this.displayedCategoryBonus = 150, // Varsayılan olarak 150
    this.isClaimingDoubleReward = false,
  });

  GameState copyWith({
    String? category,
    String? targetWord,
    List<String>? gridLetters,
    List<int>? selectedIndices,
    List<String?>? foundLetters,
    bool? isInitialReveal,
    bool? hasStarted,
    int? tokens,
    int? lastAttemptIndex,
    bool? isLastAttemptCorrect,
    int? justFoundIndex,
    List<String>? completedCategories,
    int? currentWordIndex,
    int? rewardTrigger,
    List<int>? eliminatedIndices,
    int? wrongAttemptsCount,
    int? jokersUsedCount,
    int? streak,
    int? lastRewardTotal,
    bool? showVictoryPanel,
    RewardData? lastReward,
    bool? showCategoryCompletePanel,
    String? lastCompletedCategory,
    int? totalCategoryWrongCount,
    int? totalCategoryJokersCount,
    bool? showGameFinishedPanel,
    int? totalEarnedTokens,
    int? totalSolvedWords,
    bool? showOutOfTokensPanel,
    bool? isOutOfTokensDismissible,
    DateTime? lastRegenTime,
    bool? letterJustSettled,
    bool? tutorialLock,
    int? pendingAdReward,
    bool? hasClaimedDoubleReward,
    // YENİ ALANLAR İÇİN copyWith PARAMETRELERİ
    int? displayedCategoryBonus,
    bool? isClaimingDoubleReward,
  }) {
    return GameState(
      category: category ?? this.category,
      targetWord: targetWord ?? this.targetWord,
      gridLetters: gridLetters ?? this.gridLetters,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      foundLetters: foundLetters ?? this.foundLetters,
      isInitialReveal: isInitialReveal ?? this.isInitialReveal,
      hasStarted: hasStarted ?? this.hasStarted,
      tokens: tokens ?? this.tokens,
      completedCategories: completedCategories ?? this.completedCategories,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      eliminatedIndices: eliminatedIndices ?? this.eliminatedIndices,
      wrongAttemptsCount: wrongAttemptsCount ?? this.wrongAttemptsCount,
      jokersUsedCount: jokersUsedCount ?? this.jokersUsedCount,
      streak: streak ?? this.streak,
      lastRewardTotal: lastRewardTotal ?? this.lastRewardTotal,
      showVictoryPanel: showVictoryPanel ?? this.showVictoryPanel,
      rewardTrigger: rewardTrigger ?? this.rewardTrigger,
      showCategoryCompletePanel: showCategoryCompletePanel ?? this.showCategoryCompletePanel,
      lastCompletedCategory: lastCompletedCategory ?? this.lastCompletedCategory,
      totalCategoryWrongCount: totalCategoryWrongCount ?? this.totalCategoryWrongCount,
      totalCategoryJokersCount: totalCategoryJokersCount ?? this.totalCategoryJokersCount,
      showGameFinishedPanel: showGameFinishedPanel ?? this.showGameFinishedPanel,
      totalEarnedTokens: totalEarnedTokens ?? this.totalEarnedTokens,
      totalSolvedWords: totalSolvedWords ?? this.totalSolvedWords,
      showOutOfTokensPanel: showOutOfTokensPanel ?? this.showOutOfTokensPanel,
      isOutOfTokensDismissible: isOutOfTokensDismissible ?? this.isOutOfTokensDismissible,
      lastRegenTime: lastRegenTime ?? this.lastRegenTime,
      lastAttemptIndex: lastAttemptIndex,
      isLastAttemptCorrect: isLastAttemptCorrect,
      justFoundIndex: justFoundIndex,
      lastReward: lastReward ?? this.lastReward,
      letterJustSettled: letterJustSettled ?? this.letterJustSettled,
      tutorialLock: tutorialLock ?? this.tutorialLock,
      pendingAdReward: pendingAdReward ?? this.pendingAdReward,
      hasClaimedDoubleReward: hasClaimedDoubleReward ?? this.hasClaimedDoubleReward,
      // YENİ ALANLARIN copyWith ATAMALARI
      displayedCategoryBonus: displayedCategoryBonus ?? this.displayedCategoryBonus,
      isClaimingDoubleReward: isClaimingDoubleReward ?? this.isClaimingDoubleReward,
    );
  }

  // --- PERSISTENCE İÇİN JSON METODLARI ---

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'targetWord': targetWord,
      'gridLetters': gridLetters,
      'selectedIndices': selectedIndices,
      'foundLetters': foundLetters,
      'isInitialReveal': isInitialReveal,
      'hasStarted': hasStarted,
      'tokens': tokens,
      'completedCategories': completedCategories,
      'currentWordIndex': currentWordIndex,
      'eliminatedIndices': eliminatedIndices,
      'wrongAttemptsCount': wrongAttemptsCount,
      'jokersUsedCount': jokersUsedCount,
      'streak': streak,
      'showVictoryPanel': showVictoryPanel,
      'lastRewardTotal': lastRewardTotal,
      'showCategoryCompletePanel': showCategoryCompletePanel,
      'totalCategoryWrongCount': totalCategoryWrongCount,
      'totalCategoryJokersCount': totalCategoryJokersCount,
      'rewardTrigger': rewardTrigger,
      'lastCompletedCategory': lastCompletedCategory,
      'showGameFinishedPanel': showGameFinishedPanel,
      'totalSolvedWords': totalSolvedWords,
      'totalEarnedTokens': totalEarnedTokens,
      'showOutOfTokensPanel': showOutOfTokensPanel,
      'lastRegenTime': lastRegenTime.toIso8601String(),
      'isOutOfTokensDismissible': isOutOfTokensDismissible,
      'letterJustSettled': letterJustSettled,
      'tutorialLock': tutorialLock,
      'lastReward': lastReward?.toJson(),
      'pendingAdReward': pendingAdReward,
      'hasClaimedDoubleReward': hasClaimedDoubleReward,
      // YENİ ALANLARIN toJson ATAMALARI
      'displayedCategoryBonus': displayedCategoryBonus,
      'isClaimingDoubleReward': isClaimingDoubleReward,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      category: json['category'] as String,
      targetWord: json['targetWord'] as String,
      gridLetters: List<String>.from(json['gridLetters']),
      selectedIndices: List<int>.from(json['selectedIndices']),
      foundLetters: List<String?>.from(json['foundLetters']),
      isInitialReveal: json['isInitialReveal'] as bool,
      hasStarted: json['hasStarted'] as bool,
      tokens: json['tokens'] as int,
      completedCategories: List<String>.from(json['completedCategories']),
      currentWordIndex: json['currentWordIndex'] as int,
      eliminatedIndices: List<int>.from(json['eliminatedIndices']),
      wrongAttemptsCount: json['wrongAttemptsCount'] as int,
      jokersUsedCount: json['jokersUsedCount'] as int,
      streak: json['streak'] as int,
      showVictoryPanel: json['showVictoryPanel'] as bool,
      lastRewardTotal: json['lastRewardTotal'] as int,
      showCategoryCompletePanel: json['showCategoryCompletePanel'] as bool,
      totalCategoryWrongCount: json['totalCategoryWrongCount'] as int,
      totalCategoryJokersCount: json['totalCategoryJokersCount'] as int,
      rewardTrigger: json['rewardTrigger'] as int,
      lastCompletedCategory: json['lastCompletedCategory'] as String?,
      showGameFinishedPanel: json['showGameFinishedPanel'] as bool,
      totalSolvedWords: json['totalSolvedWords'] as int,
      totalEarnedTokens: json['totalEarnedTokens'] as int,
      showOutOfTokensPanel: json['showOutOfTokensPanel'] as bool,
      isOutOfTokensDismissible: json['isOutOfTokensDismissible'] as bool,
      letterJustSettled: json['letterJustSettled'] as bool? ?? false,
      tutorialLock: json['tutorialLock'] as bool? ?? false,
      lastRegenTime: DateTime.parse(json['lastRegenTime'] as String),
      lastReward: json['lastReward'] != null ? RewardData.fromJson(json['lastReward']) : null,
      pendingAdReward: json['pendingAdReward'] ?? 0,
      hasClaimedDoubleReward: json['hasClaimedDoubleReward'] as bool? ?? false,
      // YENİ ALANLARIN fromJson ATAMALARI (eski kayıtlarda olmayabileceği için null check)
      displayedCategoryBonus: json['displayedCategoryBonus'] as int? ?? 150,
      isClaimingDoubleReward: json['isClaimingDoubleReward'] as bool? ?? false,
    );
  }
}