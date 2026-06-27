import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/library_state.dart';
import '../../../data/library_rooms.dart';
import '../../game/providers/game_provider.dart';

class LibraryNotifier extends StateNotifier<LibraryState> {
  final Ref ref;
  static const String _storageKey = 'lexmory_library_stages';
  static const String _unlockKey = 'lexmory_library_unlocks'; // Kilitli odalar için yeni key

  LibraryNotifier(this.ref) : super(LibraryState.initial()) {
    _loadFromDisk();
  }

  // Cihazdan verileri yükle
  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedStages = prefs.getStringList(_storageKey);
    final List<String>? savedUnlocks = prefs.getStringList(_unlockKey);

    Map<String, int> loadedStages = Map.from(state.roomStages);
    List<String> loadedUnlocks = List.from(state.unlockedRoomIds);

    if (savedStages != null) {
      for (var item in savedStages) {
        final parts = item.split(':');
        if (parts.length == 2) {
          loadedStages[parts[0]] = int.parse(parts[1]);
        }
      }
    }

    if (savedUnlocks != null) {
      loadedUnlocks = savedUnlocks;
    }

    state = state.copyWith(roomStages: loadedStages, unlockedRoomIds: loadedUnlocks);
  }

  // Veriyi kalıcı olarak kaydet
  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();

    // Stage bilgilerini kaydet
    List<String> stagesToSave = state.roomStages.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();
    await prefs.setStringList(_storageKey, stagesToSave);

    // Kilit açma bilgilerini kaydet
    await prefs.setStringList(_unlockKey, state.unlockedRoomIds);
  }

  Future<void> upgradeRoom(String roomId) async {
    // Oda verisini merkezi dosyadan al (Hardcoded 7 yerine dinamik totalStages kullanımı)
    final roomData = libraryRooms.firstWhere((r) => r['id'] == roomId);
    final int totalStages = roomData['totalStages'] as int;

    final currentStage = state.roomStages[roomId] ?? 0;

    // 1. Durum Kontrolü: Zaten maksimum seviyede mi?
    if (currentStage >= totalStages) return;

    final cost = getUpgradeCost(roomId, currentStage);
    final gameState = ref.read(gameProvider);

    // 2. Ekonomi Kontrolü
    if (gameState.tokens >= cost) {
      // Önce token düş (Future<void> olduğu için await edilir)
      await ref.read(gameProvider.notifier).spendTokens(cost);

      // Stage artır
      final newStages = Map<String, int>.from(state.roomStages);
      newStages[roomId] = currentStage + 1;

      state = state.copyWith(roomStages: newStages);

      // Değişikliği anında diske yaz
      await _saveToDisk();

      // 3. Oda Tamamlanma Kontrolü (Bir sonrakini aç)
      if (newStages[roomId] == totalStages) {
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
    bool stateChanged = false;
    List<String> currentUnlocks = List.from(state.unlockedRoomIds);

    for (var room in libraryRooms) {
      if (room['unlockRequirement'] == completedRoomId) {
        final String nextId = room['id'];
        if (!currentUnlocks.contains(nextId)) {
          currentUnlocks.add(nextId);
          stateChanged = true;
        }
      }
    }

    if (stateChanged) {
      state = state.copyWith(unlockedRoomIds: currentUnlocks);
      _saveToDisk();
    }
  }

  bool canAffordAnyUpgrade(int currentTokens) {
    for (String roomId in state.unlockedRoomIds) {
      final currentStage = state.roomStages[roomId] ?? 0;

      // Oda verisini bul (max stage kontrolü için)
      final roomData = libraryRooms.firstWhere((r) => r['id'] == roomId);
      final int totalStages = roomData['totalStages'] as int;

      if (currentStage < totalStages) {
        final cost = getUpgradeCost(roomId, currentStage);
        if (currentTokens >= cost) {
          return true; // En az bir oda için para yetiyor
        }
      }
    }
    return false;
  }
}



final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) => LibraryNotifier(ref));