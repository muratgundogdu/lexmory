import '../features/library/models/chest_type.dart';
import '../features/library/models/card_rarity.dart';

final Map<String, ChestType> chestConfigs = {
  'wooden_chest': const ChestType(
    id: 'wooden_chest',
    name: 'Wooden Chest',
    cardCount: 2,
    guaranteedNewCardCount: 0,
    rarityWeights: {
      CardRarity.common: 0.90,
      CardRarity.rare: 0.09,
      CardRarity.legendary: 0.01,
    },
    baseNewCardChance: 0.35,
    pityIncrement: 1,
    imagePath: 'lib/assets/chests/wooden_chest.webp',
  ),
  'silver_chest': const ChestType(
    id: 'silver_chest',
    name: 'Silver Chest',
    cardCount: 3,
    guaranteedNewCardCount: 0,
    rarityWeights: {
      CardRarity.common: 0.60,
      CardRarity.rare: 0.35,
      CardRarity.legendary: 0.05,
    },
    baseNewCardChance: 0.45,
    pityIncrement: 2,
    imagePath: 'lib/assets/chests/silver_chest.webp',
  ),
  'golden_chest': const ChestType(
    id: 'golden_chest',
    name: 'Golden Chest',
    cardCount: 4,
    guaranteedNewCardCount: 0,
    rarityWeights: {
      CardRarity.common: 0.20,
      CardRarity.rare: 0.60,
      CardRarity.legendary: 0.20,
    },
    baseNewCardChance: 0.60,
    pityIncrement: 3,
    imagePath: 'lib/assets/chests/golden_chest.webp',
  ),
  'crystal_chest': const ChestType(
    id: 'crystal_chest',
    name: 'Crystal Chest',
    cardCount: 5,
    guaranteedNewCardCount: 1,
    rarityWeights: {
      CardRarity.common: 0.00,
      CardRarity.rare: 0.50,
      CardRarity.legendary: 0.50,
    },
    baseNewCardChance: 1.0,
    pityIncrement: 0,
    imagePath: 'lib/assets/chests/golden_chest.webp', // Fallback to golden if crystal is missing
  ),
};
