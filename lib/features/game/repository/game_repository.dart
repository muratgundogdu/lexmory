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

  Map<String, dynamic>? _getNextStarterCategory(List<String> completedCategories) {
    // Karşılaştırma hatalarını önlemek için tamamlananları temizle
    final cleanedCompleted = completedCategories.map((e) => e.trim()).toList();

    for (final categoryName in _starterCategoryOrder) {
      final nameTrimmed = categoryName.trim();

      // Eğer kategori henüz tamamlanmadıysa
      if (!cleanedCompleted.contains(nameTrimmed)) {
        // categories.dart listesinde bu ismi ara
        // orElse kullanarak hata fırlatmasını (crash) engelliyoruz
        final found = categories.cast<Map<String, dynamic>?>().firstWhere(
              (c) => c?['category'].toString().trim() == nameTrimmed,
          orElse: () => null,
        );

        if (found != null) return found;
      }
    }
    return null;
  }

  Map<String, dynamic> _getControlledRandomCategory(List<String> completedCategories) {
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