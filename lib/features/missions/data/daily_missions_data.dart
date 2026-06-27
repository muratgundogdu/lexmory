import '../models/daily_mission.dart';

/// İlk 7 gün için gün bazlı sabit görev ID listeleri.
/// Her gün oyuncuya atanacak 3 benzersiz görevin ID'lerini tutar.
final Map<int, List<String>> onboardingDailyMissionIds = {
  1: ['solve_5_words', 'streak_3', 'use_1_hint'],
  2: ['solve_8_words', 'earn_100_tokens', 'no_hint_2_words'],
  3: ['solve_10_words', 'streak_5', 'watch_1_ad'],
  4: ['solve_12_words', 'no_wrong_3_words', 'upgrade_library_once'],
  5: ['solve_15_words', 'earn_250_tokens', 'no_hint_3_words'],
  6: ['complete_1_category', 'streak_7', 'watch_1_ad'],
  7: ['solve_20_words', 'no_wrong_5_words', 'upgrade_library_once'],
};

/// Lexmory görev havuzu. Zorluk seviyelerine göre gruplanmış,
/// tüm tekil görev şablonlarını barındırır.
final List<DailyMission> dailyMissionPool = [
  // ==========================================
  // EASY GÖREVLER
  // ==========================================
  const DailyMission(
    id: 'solve_5_words',
    title: '5 Kelime Çöz',
    type: DailyMissionType.solveWords,
    difficulty: DailyMissionDifficulty.easy,
    target: 5,
    rewardTokens: 50,
    icon: '📝',
  ),
  const DailyMission(
    id: 'solve_8_words',
    title: '8 Kelime Çöz',
    type: DailyMissionType.solveWords,
    difficulty: DailyMissionDifficulty.easy,
    target: 8,
    rewardTokens: 75,
    icon: '📖',
  ),
  const DailyMission(
    id: 'earn_100_tokens',
    title: '100 Token Kazan',
    type: DailyMissionType.earnTokens,
    difficulty: DailyMissionDifficulty.easy,
    target: 100,
    rewardTokens: 40,
    icon: '🪙',
  ),
  const DailyMission(
    id: 'use_1_hint',
    title: '1 Kez İpucu Kullan',
    type: DailyMissionType.solveWords, // 🎯 game_provider'daki ipucu tetikleyicisi ile tam eşitlendi!
    difficulty: DailyMissionDifficulty.easy,
    target: 1,
    rewardTokens: 30,
    icon: '💡',
  ),
  const DailyMission(
    id: 'streak_3',
    title: '3 Seri Yakala',
    type: DailyMissionType.reachStreak,
    difficulty: DailyMissionDifficulty.easy,
    target: 3,
    rewardTokens: 60,
    icon: '🔥',
  ),

  // ==========================================
  // MEDIUM GÖREVLER
  // ==========================================
  const DailyMission(
    id: 'solve_10_words',
    title: '10 Kelime Çöz',
    type: DailyMissionType.solveWords,
    difficulty: DailyMissionDifficulty.medium,
    target: 10,
    rewardTokens: 120,
    icon: '📚',
  ),
  const DailyMission(
    id: 'solve_12_words',
    title: '12 Kelime Çöz',
    type: DailyMissionType.solveWords,
    difficulty: DailyMissionDifficulty.medium,
    target: 12,
    rewardTokens: 150,
    icon: '🧐',
  ),
  const DailyMission(
    id: 'solve_15_words', // 🎯 İşte aranan ve eksik olan ID!
    title: '15 Kelime Çöz',
    type: DailyMissionType.solveWords,
    difficulty: DailyMissionDifficulty.medium,
    target: 15,
    rewardTokens: 180, // Ödülü tasarımına göre ayarlarsın
    icon: '📝',
  ),
  const DailyMission(
    id: 'earn_250_tokens',
    title: '250 Token Kazan',
    type: DailyMissionType.earnTokens,
    difficulty: DailyMissionDifficulty.medium,
    target: 250,
    rewardTokens: 100,
    icon: '💰',
  ),
  const DailyMission(
    id: 'streak_5',
    title: '5 Seri Yakala',
    type: DailyMissionType.reachStreak,
    difficulty: DailyMissionDifficulty.medium,
    target: 5,
    rewardTokens: 140,
    icon: '⚡',
  ),
  const DailyMission(
    id: 'no_hint_2_words',
    title: 'İpucu Kullanmadan 2 Kelime Çöz',
    type: DailyMissionType.solveWithoutHint,
    difficulty: DailyMissionDifficulty.medium,
    target: 2,
    rewardTokens: 130,
    icon: '🧠',
  ),
  const DailyMission(
    id: 'no_hint_3_words',
    title: 'İpucu Kullanmadan 3 Kelime Çöz',
    type: DailyMissionType.solveWithoutHint,
    difficulty: DailyMissionDifficulty.medium,
    target: 3,
    rewardTokens: 160,
    icon: '🎯',
  ),
  const DailyMission(
    id: 'no_wrong_3_words',
    title: 'Hata Yapmadan 3 Kelime Çöz',
    type: DailyMissionType.solveWithoutWrong,
    difficulty: DailyMissionDifficulty.medium,
    target: 3,
    rewardTokens: 170,
    icon: '🛡️',
  ),
  const DailyMission(
    id: 'watch_1_ad',
    title: '1 Reklam İzle',
    type: DailyMissionType.watchAds,
    difficulty: DailyMissionDifficulty.medium,
    target: 1,
    rewardTokens: 80,
    icon: '📺',
  ),

  // ==========================================
  // HARD GÖREVLER
  // ==========================================
  const DailyMission(
    id: 'solve_20_words',
    title: '20 Kelime Çöz',
    type: DailyMissionType.solveWords,
    difficulty: DailyMissionDifficulty.hard,
    target: 20,
    rewardTokens: 250,
    icon: '🎓',
  ),
  const DailyMission(
    id: 'streak_7',
    title: '7 Seri Yakala',
    type: DailyMissionType.reachStreak,
    difficulty: DailyMissionDifficulty.hard,
    target: 7,
    rewardTokens: 220,
    icon: '👑',
  ),
  const DailyMission(
    id: 'no_wrong_5_words',
    title: 'Hata Yapmadan 5 Kelime Çöz',
    type: DailyMissionType.solveWithoutWrong,
    difficulty: DailyMissionDifficulty.hard,
    target: 5,
    rewardTokens: 300,
    icon: '🏆',
  ),
  const DailyMission(
    id: 'complete_1_category',
    title: '1 Kategoriyi Tamamen Bitir',
    type: DailyMissionType.completeCategories,
    difficulty: DailyMissionDifficulty.hard,
    target: 1,
    rewardTokens: 240,
    icon: '🏛️',
  ),
  const DailyMission(
    id: 'upgrade_library_once',
    title: 'Kütüphanede 1 Geliştirme Yap',
    type: DailyMissionType.upgradeLibrary,
    difficulty: DailyMissionDifficulty.hard,
    target: 1,
    rewardTokens: 260,
    icon: '✨',
  ),
];