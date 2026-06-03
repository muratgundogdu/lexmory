/// Ödül hesaplama sonucunu taşıyan veri modeli
class RewardResult {
  final int base;
  final int memoryBonus;
  final int masterBonus;
  final double multiplier;
  final int total;

  const RewardResult({
    required this.base,
    required this.memoryBonus,
    required this.masterBonus,
    required this.multiplier,
    required this.total,
  });
}

class RewardCalculator {
  /// Mevcut oyun verilerine göre kazanılan ödülleri hesaplar
  static RewardResult calculate({
    required int streak,
    required int wrongCount,
    required int jokerCount,
  }) {
    // Sabit Değerler
    const int baseReward = 25;
    const int memoryBonusValue = 10;
    const int masterBonusValue = 15;

    // 1. Bonusları Şartlara Göre Belirle
    final int memory = (wrongCount == 0) ? memoryBonusValue : 0;
    final int master = (jokerCount == 0) ? masterBonusValue : 0;

    // 2. Çarpanı (Multiplier) Streak Değerine Göre Belirle
    // Not: Provider tarafında streak artırıldıktan sonra buraya gönderilmelidir.
    final double multiplier = getMultiplierValue(streak);

    // 3. Toplamı Hesapla: Base + ((Bonuslar) * Çarpan)
    // .round() ile en yakın tam sayıya yuvarlayarak int'e çeviriyoruz
    final int total = baseReward + ((memory + master) * multiplier).round();

    return RewardResult(
      base: baseReward,
      memoryBonus: memory,
      masterBonus: master,
      multiplier: multiplier,
      total: total,
    );
  }

  /// Streak değerini çarpan oranına dönüştüren yardımcı metod
  /// UI tarafında da çarpanı göstermek için kullanılabilir
  static double getMultiplierValue(int streak) {
    if (streak <= 1) return 1.0;
    if (streak == 2) return 1.1;
    if (streak == 3) return 1.2;
    if (streak == 4) return 1.3;
    return 1.5; // Streak 5 ve üzeri için maksimum çarpan
  }
}