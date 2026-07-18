import '../features/library/models/chest_reward_source.dart';

class ChestRewardConfig {
  final String chestTypeId;
  final int quantity;

  const ChestRewardConfig({
    required this.chestTypeId,
    this.quantity = 1,
  });
}

final Map<ChestRewardSource, ChestRewardConfig> chestRewardMapping = {
  ChestRewardSource.categoryCompletion: const ChestRewardConfig(chestTypeId: 'wooden_chest'),
  ChestRewardSource.dailyMission: const ChestRewardConfig(chestTypeId: 'silver_chest'),
  ChestRewardSource.weeklyMission: const ChestRewardConfig(chestTypeId: 'golden_chest'),
  ChestRewardSource.dailyLogin: const ChestRewardConfig(chestTypeId: 'silver_chest'),
  // Add defaults for others if needed, or handle them in the provider
  ChestRewardSource.event: const ChestRewardConfig(chestTypeId: 'silver_chest'),
  ChestRewardSource.shop: const ChestRewardConfig(chestTypeId: 'wooden_chest'),
  ChestRewardSource.debug: const ChestRewardConfig(chestTypeId: 'wooden_chest'),
};
