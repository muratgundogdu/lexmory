class RewardResult {
  final int base;
  final int memoryBonus;
  final int masterBonus; // No Hint Bonus
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
  static RewardResult calculate({
    required int streak,
    required int wrongCount,
    required int jokerCount,
  }) {
    const int baseReward = 25;

    // 1. Memory Bonus (Hata sayısına göre)
    int memory;
    if (wrongCount == 0) {memory = 15;}
    else if (wrongCount == 1) {memory = 10;}
    else if (wrongCount == 2) {memory = 5;}
    else {memory = 0;}

    // 2. No Hint Bonus (Joker sayısına göre)
    int noHint;
    if (jokerCount == 0) {noHint = 15;}
    else if (jokerCount == 1) {noHint = 10;}
    else if (jokerCount == 2) {noHint = 5;}
    else {noHint = 0;}

    // 3. Multiplier (Streak değerine göre)
    final double multiplier = getMultiplierValue(streak);

    // 4. Formül: total = base + ((memory + noHint) * multiplier)
    final int total = baseReward + ((memory + noHint) * multiplier).round();

    return RewardResult(
      base: baseReward,
      memoryBonus: memory,
      masterBonus: noHint,
      multiplier: multiplier,
      total: total,
    );
  }

  static double getMultiplierValue(int streak) {
    if (streak <= 1) return 1.0;
    if (streak == 2) return 1.1;
    if (streak == 3) return 1.2;
    if (streak == 4) return 1.3;
    return 1.5; // 5 ve üzeri
  }
}