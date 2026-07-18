import 'card_rarity.dart';

class ChestType {
  final String id;
  final String name;
  final int cardCount;
  final int guaranteedNewCardCount;
  final Map<CardRarity, double> rarityWeights;
  final double baseNewCardChance;
  final int pityIncrement;
  final String imagePath;

  const ChestType({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.guaranteedNewCardCount,
    required this.rarityWeights,
    required this.baseNewCardChance,
    required this.pityIncrement,
    required this.imagePath,
  });
}
