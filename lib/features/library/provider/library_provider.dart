import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/library_state.dart';
import '../../../data/library_rooms.dart';
import '../../game/providers/game_provider.dart';

class LibraryNotifier extends StateNotifier<LibraryState> {
  final Ref ref;
  static const String _storageKey = 'lexmory_library_stages';

  LibraryNotifier(this.ref) : super(LibraryState(roomStages: {"room_01": 0}, unlockedRoomIds: ["room_01"])) {
    _loadFromDisk(); // Uygulama açılınca yükle
  }

  // Cihazdan verileri yükle
  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedData = prefs.getStringList(_storageKey);

    if (savedData != null) {
      Map<String, int> loadedStages = {};
      List<String> loadedUnlocks = ["room_01"];

      for (var item in savedData) {
        final parts = item.split(':'); // room_01:3 formatında saklıyoruz
        if (parts.length == 2) {
          loadedStages[parts[0]] = int.parse(parts[1]);
          if (int.parse(parts[1]) > 0 && !loadedUnlocks.contains(parts[0])) {
            loadedUnlocks.add(parts[0]);
          }
        }
      }
      state = state.copyWith(roomStages: loadedStages, unlockedRoomIds: loadedUnlocks);
    }
  }

  // Veriyi kalıcı olarak kaydet
  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> dataToSave = state.roomStages.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();
    await prefs.setStringList(_storageKey, dataToSave);
  }

// lib/features/library/provider/library_provider.dart

  Future<void> upgradeRoom(String roomId) async {
    final currentStage = state.roomStages[roomId] ?? 0;
    if (currentStage >= 7) return;

    final cost = getUpgradeCost(roomId, currentStage);
    final gameState = ref.read(gameProvider);

    if (gameState.tokens >= cost) {
      // Artık spendTokens Future<void> olduğu için await hata vermeyecek
      await ref.read(gameProvider.notifier).spendTokens(cost);

      // Kütüphane gelişimini güncelle ve kaydet
      final newStages = Map<String, int>.from(state.roomStages);
      newStages[roomId] = currentStage + 1;
      state = state.copyWith(roomStages: newStages);

      await _saveToDisk(); // Kütüphane stage bilgisini kaydet

      if (newStages[roomId] == 7) {
        _unlockNextRoom(roomId);
      }
    }
  }

  int getUpgradeCost(String roomId, int currentStage) {
    final room = libraryRooms.firstWhere((r) => r['id'] == roomId);
    final List<int> baseCosts = List<int>.from(room['baseCosts']);
    final double multiplier = room['multiplier'] ?? 1.0;

    if (currentStage >= baseCosts.length) return 0;
    return (baseCosts[currentStage] * multiplier).toInt();
  }

  void _unlockNextRoom(String completedRoomId) {
    for (var room in libraryRooms) {
      if (room['unlockRequirement'] == completedRoomId) {
        final String nextId = room['id'];
        if (!state.unlockedRoomIds.contains(nextId)) {
          state = state.copyWith(unlockedRoomIds: [...state.unlockedRoomIds, nextId]);
          _saveToDisk();
        }
      }
    }
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) => LibraryNotifier(ref));
