import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/collection_pool.dart';
import '../../../data/collections.dart';
import '../../../data/chest_configs.dart';
import '../../../data/chest_reward_mapping.dart';
import '../../../core/services/random_provider.dart';
import '../../game/providers/game_provider.dart';
import '../models/collection_card.dart';
import '../models/collection_state.dart';
import '../models/chest_type.dart';
import '../models/chest_open_result.dart';
import '../models/chest_reward_source.dart';
import '../services/chest_service.dart';

class CollectionNotifier extends StateNotifier<CollectionState> {
  final Ref ref;
  final ChestService _chestService = ChestService();

  static const String _storageKey = 'lexmory_collection_state';
  static const String _legacyOwnedCardsKey = 'lexmory_owned_cards';

  @visibleForTesting
  late Future<void> initialization;

  CollectionNotifier(this.ref) : super(CollectionState.initial()) {
    initialization = _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!mounted) return;

      // 1. Try to load new JSON state
      final String? jsonState = prefs.getString(_storageKey);
      if (jsonState != null) {
        try {
          final decoded = json.decode(jsonState);
          state = CollectionState.fromJson(decoded);
          return;
        } catch (e) {
          // Fallback to legacy or initial if JSON is corrupted
        }
      }

      // 2. Migration: Try to load legacy owned cards
      final List<String>? legacyCards = prefs.getStringList(_legacyOwnedCardsKey);
      if (legacyCards != null) {
        state = state.copyWith(
          ownedCardIds: legacyCards.toSet(),
          pityCounter: 0,
        );
        // Save migrated state immediately
        await _saveToDisk();
      }
    } catch (e) {
      debugPrint('CollectionNotifier init error: $e');
    }
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(state.toJson()));
  }

  /// Authoritative method for opening a chest reward immediately.
  /// Uses compensating rollback strategy for consistency between collection and economy.
  Future<ChestOpenResult> openChestReward(ChestRewardSource source, {String? chestTypeId}) async {
    final config = chestRewardMapping[source];
    final finalId = chestTypeId ?? config?.chestTypeId;

    if (kDebugMode) {
      print('CollectionNotifier: Opening chest for source: $source, requestedId: $chestTypeId, resolvedId: $finalId');
    }

    if (finalId == null || !chestConfigs.containsKey(finalId)) {
      throw ArgumentError('Invalid chestTypeId: $finalId for source: $source');
    }

    final chestType = chestConfigs[finalId]!;
    final random = ref.read(randomProvider);
    final previousState = state;

    // 1. Logic (Pure Simulation)
    final result = _chestService.openChest(
      chestType: chestType,
      currentState: state,
      cardRegistry: collectionPool,
      collectionRegistry: albumSets,
      random: random,
    );

    if (kDebugMode) {
      print('CollectionNotifier: Chest open result: ${result.rewards.length} cards, ${result.totalGrantedTokens} total tokens');
    }

    // Invariant check: Chests with cardCount > 0 should not return empty rewards
    // unless candidate pool is exhausted (which is nearly impossible for Silver Chest early on).
    if (chestType.cardCount > 0 && result.rewards.isEmpty) {
      throw StateError('Chest opening produced zero rewards for chest type: ${chestType.id}');
    }

    // 2. Build new state from result
    final newOwnedCards = Set<String>.from(state.ownedCardIds);
    final newlyUnlocked = Set<String>.from(state.newlyUnlockedCardIds);
    for (final reward in result.rewards) {
      if (reward.isNew) {
        newOwnedCards.add(reward.card.id);
        newlyUnlocked.add(reward.card.id);
      }
    }

    final newState = state.copyWith(
      ownedCardIds: newOwnedCards,
      unlockedCharacterIds: state.unlockedCharacterIds.union(result.unlockedCharacterIds),
      newlyUnlockedCardIds: newlyUnlocked,
      pityCounter: result.finalPityCounter,
    );

    // 3. Attempt Persistence
    try {
      if (!mounted) return result;
      state = newState;
      await _saveToDisk();

      // 4. Attempt Economy Update
      if (result.totalGrantedTokens > 0) {
        await ref.read(gameProvider.notifier).addTokens(result.totalGrantedTokens);
      }
    } catch (e) {
      // 5. Compensating Rollback
      if (mounted) {
        state = previousState;
        try {
          await _saveToDisk();
        } catch (inner) {
          debugPrint('Critical: Failed to rollback collection state on disk: $inner');
        }
      }
      rethrow;
    }

    return result;
  }

  /// Testing only: opening chests directly.
  @visibleForTesting
  Future<ChestOpenResult> openChest(ChestType chestType) async {
    final random = ref.read(randomProvider);
    final previousState = state;

    final result = _chestService.openChest(
      chestType: chestType,
      currentState: state,
      cardRegistry: collectionPool,
      collectionRegistry: albumSets,
      random: random,
    );

    final newOwnedCards = Set<String>.from(state.ownedCardIds);
    final newlyUnlocked = Set<String>.from(state.newlyUnlockedCardIds);
    for (final reward in result.rewards) {
      if (reward.isNew) {
        newOwnedCards.add(reward.card.id);
        newlyUnlocked.add(reward.card.id);
      }
    }

    final newState = state.copyWith(
      ownedCardIds: newOwnedCards,
      unlockedCharacterIds: state.unlockedCharacterIds.union(result.unlockedCharacterIds),
      newlyUnlockedCardIds: newlyUnlocked,
      pityCounter: result.finalPityCounter,
    );

    try {
      if (!mounted) return result;
      state = newState;
      await _saveToDisk();
      if (result.totalGrantedTokens > 0) {
        await ref.read(gameProvider.notifier).addTokens(result.totalGrantedTokens);
      }
    } catch (e) {
      if (mounted) {
        state = previousState;
        try {
          await _saveToDisk();
        } catch (_) {}
      }
      rethrow;
    }

    return result;
  }

  @Deprecated('Use openChestReward instead')
  Future<ChestResult> openRewardChest() async {
    final wooden = chestConfigs['wooden_chest']!;
    final result = await openChest(wooden);
    
    if (result.rewards.isEmpty) {
      throw Exception("Chest opening returned no rewards");
    }

    final firstReward = result.rewards.first;
    return ChestResult(
      card: firstReward.card,
      isNew: firstReward.isNew,
      isDuplicate: !firstReward.isNew,
      refundTokens: firstReward.duplicateTokenValue,
    );
  }

  @Deprecated('Use openChestReward instead')
  Future<ChestResult?> buyCardPacket({int packetCost = 500}) async {
    final gameState = ref.read(gameProvider);
    if (gameState.tokens < packetCost) return null;

    await ref.read(gameProvider.notifier).spendTokens(packetCost);
    return await openRewardChest();
  }

  /// Marks a card as "seen" in the library, clearing its newly-unlocked animation status.
  Future<void> markCardAsSeen(String cardId) async {
    if (state.newlyUnlockedCardIds.contains(cardId)) {
      final updated = Set<String>.from(state.newlyUnlockedCardIds)..remove(cardId);
      state = state.copyWith(newlyUnlockedCardIds: updated);
      await _saveToDisk();
    }
  }
}

class ChestResult {
  final CollectionCard card;
  final bool isNew;
  final bool isDuplicate;
  final int refundTokens;

  ChestResult({
    required this.card,
    required this.isNew,
    required this.isDuplicate,
    required this.refundTokens,
  });
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  return CollectionNotifier(ref);
});
