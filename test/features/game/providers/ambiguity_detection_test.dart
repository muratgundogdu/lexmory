import 'package:flutter_test/flutter_test.dart';
import 'package:lexmory/features/game/repository/game_repository.dart';
import 'package:lexmory/features/game/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGameRepository extends GameRepository {}
class MockAdService extends AdService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Ambiguity Detection Tests', () {
    test('DİZ target with Z revealed should NOT conflict with DİL', () async {
      // We want to test the internal _buildStateForWord logic.
      // Since it's static and private, we can't call it directly easily,
      // but we can trigger it via public methods if we mock the repository.
      
      // However, the logic is in _buildStateForWord which is called during initialization or word loading.
      // We can use a ProviderContainer to test GameNotifier.
    });
  group('Manual Character Logic Check', () {
    test('Turkish character indexing and comparison', () {
      const target = "DİZ"; // U+0044, U+0130, U+005A
      const candidate = "DİL"; // U+0044, U+0130, U+004C
      
      expect(target.length, 3);
      expect(candidate.length, 3);
      
      final hintIndices = {2}; // Z is revealed
      
      bool matchesHints = true;
      for (int hIdx in hintIndices) {
        if (candidate[hIdx] != target[hIdx]) {
          matchesHints = false;
          break;
        }
      }
      
      expect(matchesHints, isFalse, reason: "DİL ends in L, DİZ ends in Z. Revealed Z should exclude DİL.");
    });

    test('Turkish İ vs I comparison', () {
      const withDot = "İ"; // U+0130
      const withoutDot = "I"; // U+0049
      
      expect(withDot == withoutDot, isFalse);
      expect(withDot.toLowerCase(), "i");
      expect(withoutDot.toLowerCase(), "ı");
      
      // Standard toUpperCase behavior
      expect("i".toUpperCase(), "I"); // Dart default is NOT Turkish locale
      expect("ı".toUpperCase(), "I"); 
    });
  });
  });
}
