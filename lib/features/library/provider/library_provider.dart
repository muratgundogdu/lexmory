import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/library_state.dart';
import '../models/room_completion_reward_result.dart';
import '../models/chest_reward_source.dart';
import '../../../data/library_rooms.dart';
import '../../../data/room_rewards.dart';
import '../../game/providers/game_provider.dart';
import '../provider/collection_provider.dart';

import '../provider/library_navigation_provider.dart';

class LibraryNotifier extends StateNotifier<LibraryState> {
  final Ref ref;
  static const String _storageKey = 'lexmory_library_state_json';
  static const String _legacyStagesKey = 'lexmory_library_stages';
  static const String _legacyUnlocksKey = 'lexmory_library_unlocks';

  @visibleForTesting
  late final Future<void> initialization;

  LibraryNotifier(this.ref) : super(LibraryState.initial()) {
    initialization = _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonState = prefs.getString(_storageKey);

      if (jsonState != null) {
        state = LibraryState.fromJson(json.decode(jsonState));
      } else {
        // Migration from legacy keys
        final List<String>? savedStages = prefs.getStringList(_legacyStagesKey);
        final List<String>? savedUnlocks = prefs.getStringList(_legacyUnlocksKey);

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
        await _saveToDisk();
      }
    } catch (e) {
      debugPrint('LibraryNotifier load error: $e');
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint('LibraryNotifier save error: $e');
    }
  }

  Future<void> upgradeRoom(String roomId) async {
    final roomData = libraryRooms.firstWhere((r) => r['id'] == roomId);
    final int totalStages = roomData['totalStages'] as int;
    final String roomName = roomData['name'] as String;

    final int currentStage = state.roomStages[roomId] ?? 0;
    if (currentStage >= totalStages) return;

    final cost = getUpgradeCost(roomId, currentStage);
    final currentTokens = ref.read(gameProvider).tokens;

    if (currentTokens >= cost) {
      // 1. Deduct tokens
      await ref.read(gameProvider.notifier).spendTokens(cost);

      // 2. Increment stage
      final newStages = Map<String, int>.from(state.roomStages);
      final int nextStage = currentStage + 1;
      newStages[roomId] = nextStage;

      state = state.copyWith(roomStages: newStages);
      await _saveToDisk();

      // 3. Detect completion
      if (nextStage == totalStages) {
        await _applyRoomCompletionReward(roomId, roomName);
        _unlockNextRoom(roomId);
      }
    }
  }

  Future<void> _applyRoomCompletionReward(String roomId, String roomName) async {
    // Exactly-once check
    if (state.claimedRoomRewardIds.contains(roomId)) {
      debugPrint('LibraryNotifier: Reward for $roomId already claimed. Skipping.');
      return;
    }

    debugPrint('LibraryNotifier: Applying reward for completing $roomId');

    final config = getRewardForRoom(roomId);

    try {
      // 1. Grant tokens and jokers
      await ref.read(gameProvider.notifier).addTokens(config.tokens);
      await ref.read(gameProvider.notifier).addJokers(
        hints: config.hints,
        removeWrongs: config.removeWrongs,
      );

      // 2. Open chest immediately
      final chestResult = await ref.read(collectionProvider.notifier).openChestReward(
        ChestRewardSource.roomCompletion,
        chestTypeId: config.chestTypeId,
      );

      // 3. Create Result and Update State
      final result = RoomCompletionRewardResult(
        roomId: roomId,
        roomName: roomName,
        tokenReward: config.tokens,
        hintReward: config.hints,
        removeWrongReward: config.removeWrongs,
        chestTypeId: config.chestTypeId,
        chestResult: chestResult,
      );

      final newClaimed = Set<String>.from(state.claimedRoomRewardIds)..add(roomId);
      
      state = state.copyWith(
        claimedRoomRewardIds: newClaimed,
        pendingCelebration: result,
      );

      await _saveToDisk();
      debugPrint('LibraryNotifier: Successfully claimed and persisted reward for $roomId');
    } catch (e) {
      debugPrint('LibraryNotifier: FAILED to apply room completion reward: $e');
      // Idempotency: roomId was not added to claimedRoomRewardIds, so it can retry next time.
    }
  }

  void consumeCelebration() {
    if (state.pendingCelebration != null) {
      state = state.copyWith(clearPendingCelebration: true);
      _saveToDisk();
    }
  }

  void focusUnlockedRoom(String roomId) {
    // 1. Ensure we are on the Library tab
    ref.read(libraryTabProvider.notifier).state = 0;
    
    // 2. Set the newly unlocked room ID
    state = state.copyWith(newlyUnlockedRoomId: roomId);
  }

  void clearRoomFocus() {
    if (state.newlyUnlockedRoomId != null) {
      state = state.copyWith(clearNewlyUnlockedRoomId: true);
    }
  }

  int getUpgradeCost(String roomId, int currentStage) {
    final room = libraryRooms.firstWhere((r) => r['id'] == roomId);
    final List<int> baseCosts = List<int>.from(room['baseCosts']);
    final double multiplier = (room['multiplier'] as num?)?.toDouble() ?? 1.0;

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
      final roomData = libraryRooms.firstWhere((r) => r['id'] == roomId);
      final int totalStages = roomData['totalStages'] as int;

      if (currentStage < totalStages) {
        final cost = getUpgradeCost(roomId, currentStage);
        if (currentTokens >= cost) {
          return true;
        }
      }
    }
    return false;
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) => LibraryNotifier(ref));
