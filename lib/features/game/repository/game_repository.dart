/*import 'dart:math';
import '../../../../data/categories.dart';

class GameRepository {
  final Random _random = Random();

  /// Rastgele bir kategori verisi seçer
  Map<String, dynamic> getRandomCategory() {
    return categories[_random.nextInt(categories.length)];
  }

  /// Belirli bir kategori ismine göre kategori verisini bulur
  Map<String, dynamic> getCategoryByName(String name) {
    return categories.firstWhere((c) => c['category'] == name);
  }

  /// Henüz tamamlanmamış kategoriler arasından rastgele bir tane seçer
  Map<String, dynamic> getNextCategory(List<String> completedCategories) {
    final remainingCats = categories
        .where((c) => !completedCategories.contains(c['category']))
        .toList();

    if (remainingCats.isNotEmpty) {
      return remainingCats[_random.nextInt(remainingCats.length)];
    }

    // Eğer tüm kategoriler bittiyse, mevcut olanlardan rastgele seç (veya başa dön)
    return getRandomCategory();
  }

  /// Bir kategorideki kelimeleri List<String> olarak döndürür
  List<String> getWordsForCategory(Map<String, dynamic> categoryData) {
    return List<String>.from(categoryData['words'] as List);
  }
}*/

import 'dart:math';
import '../../../../data/categories.dart';

class GameRepository {
  final Random _random = Random();

  /// İlk 30 kategori sabit sırayla gelir.
  /// Sonrası kontrollü rastgele ilerler.
  static const List<String> _starterCategoryOrder = [
    "Hayvanlar",
    "Meyveler",
    "Sebzeler",
    "Renkler",
    "Taşıtlar",
    "Ev Eşyaları",
    "Mutfak Eşyaları",
    "Sporlar",
    "Vücut Bölümleri",
    "İçecekler",
    "Tatlılar",
    "Çiçekler",
    "Ağaçlar",
    "Kuşlar",
    "Deniz Canlıları",
    "Hava Olayları",
    "Okul Araçları",
    "Oyuncaklar",
    "Kıyafetler",
    "Takılar",
    "Market Ürünleri",
    "Kahvaltılıklar",
    "Fast Food",
    "Baharatlar",
    "Süt Ürünleri",
    "Kuruyemişler",
    "Odalar",
    "Elektronikler",
    "Telefonlar",
    "Bilgisayar Parçaları",
  ];

  Map<String, dynamic> getRandomCategory() {
    return getNextCategory([]);
  }

  Map<String, dynamic> getCategoryByName(String name) {
    return categories.firstWhere((c) => c['category'] == name);
  }

  Map<String, dynamic> getNextCategory(List<String> completedCategories) {
    final starterCategory = _getNextStarterCategory(completedCategories);

    if (starterCategory != null) {
      return starterCategory;
    }

    return _getControlledRandomCategory(completedCategories);
  }

  Map<String, dynamic>? _getNextStarterCategory(
      List<String> completedCategories,
      ) {
    for (final categoryName in _starterCategoryOrder) {
      final alreadyCompleted = completedCategories.contains(categoryName);

      if (!alreadyCompleted) {
        final exists = categories.any((c) => c['category'] == categoryName);

        if (exists) {
          return getCategoryByName(categoryName);
        }
      }
    }

    return null;
  }

  Map<String, dynamic> _getControlledRandomCategory(
      List<String> completedCategories,
      ) {
    final int completedCount = completedCategories.length;
    final int maxDifficulty = _getUnlockedDifficulty(completedCount);

    final remainingCats = categories
        .where((c) => !completedCategories.contains(c['category']))
        .toList();

    if (remainingCats.isEmpty) {
      return categories.first;
    }

    final availableCats = remainingCats.where((c) {
      final int difficulty = c['difficulty'] as int? ?? 1;
      return difficulty <= maxDifficulty;
    }).toList();

    if (availableCats.isNotEmpty) {
      availableCats.shuffle(_random);
      return availableCats.first;
    }

    remainingCats.shuffle(_random);
    return remainingCats.first;
  }

  int _getUnlockedDifficulty(int completedCount) {
    if (completedCount < 50) return 1;
    if (completedCount < 100) return 2;
    if (completedCount < 150) return 3;
    return 4;
  }

  List<String> getWordsForCategory(Map<String, dynamic> categoryData) {
    return List<String>.from(categoryData['words'] as List);
  }
}