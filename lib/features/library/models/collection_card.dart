class CollectionCard {
  final String id;
  final String name;
  final String description;
  final int stars; // 1, 2 veya 3
  final String imagePath;
  final String setName; // Örn: "Yaz Esintisi", "Antik Çağ"

  const CollectionCard({
    required this.id,
    required this.name,
    required this.description,
    required this.stars,
    required this.imagePath,
    required this.setName,
  });
}