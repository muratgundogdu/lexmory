enum CardRarity {
  common,
  rare,
  legendary;

  int get duplicateTokenValue {
    switch (this) {
      case CardRarity.common:
        return 10;
      case CardRarity.rare:
        return 50;
      case CardRarity.legendary:
        return 200;
    }
  }

  String get label {
    switch (this) {
      case CardRarity.common:
        return 'Common';
      case CardRarity.rare:
        return 'Rare';
      case CardRarity.legendary:
        return 'Legendary';
    }
  }
}
