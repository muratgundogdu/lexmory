enum DailyMissionType {
  solveWords,
  earnTokens,
  reachStreak,
  solveWithoutHint,
  solveWithoutWrong,
  completeCategories,
  upgradeLibrary,
  watchAds,
}

enum DailyMissionDifficulty {
  easy,
  medium,
  hard,
}

class DailyMission {
  final String id;
  final String title;
  final DailyMissionType type;
  final DailyMissionDifficulty difficulty;
  final int target;
  final int rewardTokens;
  final int rewardBookmarks;
  final String icon;

  const DailyMission({
    required this.id,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.target,
    required this.rewardTokens,
    this.rewardBookmarks = 1,
    required this.icon,
  });
}

class DailyMissionProgress {
  final DailyMission mission;
  final int currentProgress; // 🎯 Provider ile uyum için 'currentProgress' yapıldı
  final bool isClaimed;

  bool get isCompleted => currentProgress >= mission.target;

  const DailyMissionProgress({
    required this.mission,
    this.currentProgress = 0, // 🎯 Varsayılan değer atandı
    this.isClaimed = false,   // 🎯 Varsayılan değer atandı
  });

  // 🎯 Provider'ın SharedPreferences'a yazabilmesi için eklendi
  Map<String, dynamic> toJson() => {
    'missionId': mission.id,
    'currentProgress': currentProgress,
    'isClaimed': isClaimed,
  };

  // 🎯 Provider'ın SharedPreferences'tan okuyabilmesi için eklendi
  // Not: dailyMissionPool listesi 'daily_missions_data.dart' içinde olduğu için
  // factory metodu provider içinde bırakabiliriz veya buraya taşımak istersek pool import edilmelidir.
  // Şu anlık provider'ın factory'yi nerede aradığına bağlı olarak kalabilir.
  // Biz yine de standart factory imzamızı koyalım, provider içindekini silersin:
  factory DailyMissionProgress.fromPool(Map<String, dynamic> json, List<DailyMission> pool) {
    final missionId = json['missionId'] as String;
    final mission = pool.firstWhere(
          (m) => m.id == missionId,
      orElse: () => throw Exception('Mission ID $missionId not found in pool'),
    );
    return DailyMissionProgress(
      mission: mission,
      currentProgress: json['currentProgress'] as int? ?? 0,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }

  DailyMissionProgress copyWith({
    int? currentProgress, // 🎯 Değişken ismi güncellendi
    bool? isClaimed,
  }) {
    return DailyMissionProgress(
      mission: mission,
      currentProgress: currentProgress ?? this.currentProgress,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}