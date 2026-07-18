import '../../../../data/categories.dart';

class GameRepository {
  Map<String, dynamic> getRandomCategory() {
    return getNextCategory([]);
  }

  Map<String, dynamic> getCategoryByName(String name) {
    return categories.firstWhere((c) => c['category'] == name);
  }

  Map<String, dynamic> getNextCategory(List<String> completedCategories) {
    // Return the first category from categories.dart that hasn't been completed yet.
    // This strictly follows the order in categories.dart.
    final remaining = categories.where((c) => !completedCategories.contains(c['category'])).toList();

    if (remaining.isNotEmpty) {
      return remaining.first;
    }

    // Fallback: If all categories are completed, restart from the beginning (or handle as end game)
    return categories.first;
  }

  List<String> getWordsForCategory(Map<String, dynamic> categoryData) {
    return List<String>.from(categoryData['words'] as List);
  }
}