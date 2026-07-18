import 'card_rarity.dart';

class CollectionCard {
  final String id;
  final String name;
  final String description;
  final CardRarity rarity;
  final String imagePath;
  final String collectionId;
  final String setName; // Added back for compatibility with UI
  final int stars;      // Added back for compatibility with UI

  const CollectionCard({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.imagePath,
    required this.collectionId,
    required this.setName,
    required this.stars,
  });

  CollectionCard copyWith({
    String? id,
    String? name,
    String? description,
    CardRarity? rarity,
    String? imagePath,
    String? collectionId,
    String? setName,
    int? stars,
  }) {
    return CollectionCard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      imagePath: imagePath ?? this.imagePath,
      collectionId: collectionId ?? this.collectionId,
      setName: setName ?? this.setName,
      stars: stars ?? this.stars,
    );
  }

  factory CollectionCard.fromJson(Map<String, dynamic> json) {
    return CollectionCard(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rarity: CardRarity.values.byName(json['rarity'] as String),
      imagePath: json['imagePath'] as String,
      collectionId: json['collectionId'] as String,
      setName: json['setName'] as String? ?? '',
      stars: json['stars'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rarity': rarity.name,
      'imagePath': imagePath,
      'collectionId': collectionId,
      'setName': setName,
      'stars': stars,
    };
  }
}
