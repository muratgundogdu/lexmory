import 'collection_card.dart';

class CardRewardResult {
  final CollectionCard card;
  final bool isNew;
  final int duplicateTokenValue;
  final String? completedCollectionId;

  const CardRewardResult({
    required this.card,
    required this.isNew,
    required this.duplicateTokenValue,
    this.completedCollectionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'card': card.toJson(),
      'isNew': isNew,
      'duplicateTokenValue': duplicateTokenValue,
      'completedCollectionId': completedCollectionId,
    };
  }

  factory CardRewardResult.fromJson(Map<String, dynamic> json) {
    return CardRewardResult(
      card: CollectionCard.fromJson(json['card']),
      isNew: json['isNew'],
      duplicateTokenValue: json['duplicateTokenValue'],
      completedCollectionId: json['completedCollectionId'],
    );
  }
}
