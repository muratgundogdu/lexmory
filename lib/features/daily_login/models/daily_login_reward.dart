class DailyLoginReward {
  final int day;
  final int tokenAmount;
  final String? chestTypeId;

  const DailyLoginReward({
    required this.day,
    required this.tokenAmount,
    this.chestTypeId,
  });
}

final List<DailyLoginReward> dailyLoginRewards = [
  const DailyLoginReward(day: 1, tokenAmount: 50),
  const DailyLoginReward(day: 2, tokenAmount: 60),
  const DailyLoginReward(day: 3, tokenAmount: 75),
  const DailyLoginReward(day: 4, tokenAmount: 90),
  const DailyLoginReward(day: 5, tokenAmount: 110),
  const DailyLoginReward(day: 6, tokenAmount: 140),
  const DailyLoginReward(day: 7, tokenAmount: 200, chestTypeId: 'silver_chest'),
];
