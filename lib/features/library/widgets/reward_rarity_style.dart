import 'package:flutter/material.dart';
import '../models/card_rarity.dart';

class RewardRarityStyle {
  final Color borderColor;
  final List<BoxShadow> glow;
  final bool showSparkles;
  final Color accentColor;

  const RewardRarityStyle({
    required this.borderColor,
    required this.glow,
    required this.showSparkles,
    required this.accentColor,
  });

  factory RewardRarityStyle.from(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return const RewardRarityStyle(
          borderColor: Color(0xFF8D6E63), // Bronze neutral
          accentColor: Color(0xFF8D6E63),
          showSparkles: false,
          glow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        );
      case CardRarity.rare:
        return const RewardRarityStyle(
          borderColor: Color(0xFF7E57C2), // Blue-violet
          accentColor: Color(0xFF7E57C2),
          showSparkles: false,
          glow: [
            BoxShadow(
              color: Color(0x667E57C2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black45,
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        );
      case CardRarity.legendary:
        return const RewardRarityStyle(
          borderColor: Color(0xFFFFD54F), // Polished gold
          accentColor: Color(0xFFFFD54F),
          showSparkles: true,
          glow: [
            BoxShadow(
              color: Color(0x99FFD54F),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        );
    }
  }
}
