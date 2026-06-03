class AppConstants {
  // Animasyon Süreleri
  static const Duration victoryPanelDelay = Duration(milliseconds: 4500);
  static const Duration wordRevealDelay = Duration(seconds: 4); // Tekrar Göster süresi
  static const Duration errorEffectDuration = Duration(milliseconds: 600);
  static const Duration flyAnimationDuration = Duration(milliseconds: 650);

  // Oyun Kuralları (Ekonomi)
  static const int initialTokens = 300;
  static const int penaltyCost = 5;
  static const int hintJokerCost = 80;
  static const int showAgainJokerCost = 40;
  static const int clearWrongJokerCost = 60;

  // Ödül Değerleri
  static const int baseWinReward = 25;
  static const int memoryBonusValue = 10;
  static const int masterBonusValue = 15;

  //token kontrol
  static const int minTokenToPlay = 5;
  static const int maxRegenLimit = 100;
  static const int regenAmount = 5;
  static const Duration regenInterval = Duration(minutes: 10);
  static const int adRewardAmount = 50;

  static const String storageKeyLastRegen = 'lexmory_last_regen';
}