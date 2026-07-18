import 'dart:math';
import '../models/album_set.dart';
import '../models/card_rarity.dart';
import '../models/card_reward_result.dart';
import '../models/chest_open_result.dart';
import '../models/chest_type.dart';
import '../models/collection_card.dart';
import '../models/collection_state.dart';

class ChestService {
  ChestOpenResult openChest({
    required ChestType chestType,
    required CollectionState currentState,
    required List<CollectionCard> cardRegistry,
    required List<AlbumSet> collectionRegistry,
    required Random random,
  }) {
    final Set<String> temporaryOwnedCardIds = Set.from(currentState.ownedCardIds);
    final Set<String> temporaryUnlockedCharacterIds = Set.from(currentState.unlockedCharacterIds);
    final Set<String> rolledCardIdsInThisChest = {};

    int temporaryPityCounter = currentState.pityCounter;
    int generatedNewCardCount = 0;
    int duplicateTokensCount = 0;
    int completionRewardTokensCount = 0;
    final Set<String> completedCollectionIds = {};
    final Set<String> newlyUnlockedCharacterIds = {};
    final List<CardRewardResult> rewards = [];

    for (int i = 0; i < chestType.cardCount; i++) {
      final eligibleUnowned = cardRegistry
          .where((c) => !temporaryOwnedCardIds.contains(c.id) && !rolledCardIdsInThisChest.contains(c.id))
          .toList();

      final eligibleOwned = cardRegistry
          .where((c) => temporaryOwnedCardIds.contains(c.id) && !rolledCardIdsInThisChest.contains(c.id))
          .toList();

      if (eligibleUnowned.isEmpty && eligibleOwned.isEmpty) break;

      bool wantsNew = false;
      if (generatedNewCardCount < chestType.guaranteedNewCardCount && eligibleUnowned.isNotEmpty) {
        wantsNew = true;
      } else {
        final double finalNewCardChance = min(0.95, chestType.baseNewCardChance + temporaryPityCounter * 0.05);

        if (eligibleUnowned.isNotEmpty) {
          if (eligibleOwned.isEmpty) {
            wantsNew = true;
          } else {
            wantsNew = random.nextDouble() < finalNewCardChance;
          }
        } else {
          wantsNew = false;
        }
      }

      List<CollectionCard> candidatePool = wantsNew ? eligibleUnowned : eligibleOwned;
      // Fallback if requested pool is empty but other pool has cards
      if (candidatePool.isEmpty) {
        candidatePool = wantsNew ? eligibleOwned : eligibleUnowned;
      }

      if (candidatePool.isEmpty) break;

      final selected = _selectWeightedCard(
        candidatePool: candidatePool,
        cardRegistry: cardRegistry,
        rarityWeights: chestType.rarityWeights,
        random: random,
        ownedIds: temporaryOwnedCardIds,
        unlockedSets: temporaryUnlockedCharacterIds,
      );

      if (selected == null) break;

      rolledCardIdsInThisChest.add(selected.id);
      final bool isActuallyNew = !temporaryOwnedCardIds.contains(selected.id);
      String? completedId;

      if (isActuallyNew) {
        temporaryOwnedCardIds.add(selected.id);
        generatedNewCardCount++;
        temporaryPityCounter = 0;

        final collectionCards = cardRegistry.where((c) => c.collectionId == selected.collectionId).toList();
        final ownedInCollectionCount = collectionCards.where((c) => temporaryOwnedCardIds.contains(c.id)).length;

        if (ownedInCollectionCount == collectionCards.length && !temporaryUnlockedCharacterIds.contains(selected.collectionId)) {
          final album = collectionRegistry.firstWhere((a) => a.id == selected.collectionId);
          completedId = album.id;
          completedCollectionIds.add(album.id);
          newlyUnlockedCharacterIds.add(album.id);
          completionRewardTokensCount += album.rewardTokens;
          temporaryUnlockedCharacterIds.add(album.id);
        }
      } else {
        duplicateTokensCount += selected.rarity.duplicateTokenValue;
        temporaryPityCounter += chestType.pityIncrement;
      }

      rewards.add(CardRewardResult(
        card: selected,
        isNew: isActuallyNew,
        duplicateTokenValue: isActuallyNew ? 0 : selected.rarity.duplicateTokenValue,
        completedCollectionId: completedId,
      ));
    }

    return ChestOpenResult(
      rewards: rewards,
      duplicateTokens: duplicateTokensCount,
      completionRewardTokens: completionRewardTokensCount,
      totalGrantedTokens: duplicateTokensCount + completionRewardTokensCount,
      completedCollectionIds: completedCollectionIds,
      unlockedCharacterIds: newlyUnlockedCharacterIds,
      finalPityCounter: temporaryPityCounter,
    );
  }

  CollectionCard? _selectWeightedCard({
    required List<CollectionCard> candidatePool,
    required List<CollectionCard> cardRegistry,
    required Map<CardRarity, double> rarityWeights,
    required Random random,
    required Set<String> ownedIds,
    required Set<String> unlockedSets,
  }) {
    final availableRarities = candidatePool.map((c) => c.rarity).toSet();
    Map<CardRarity, double> currentRarityWeights = {};
    double totalRarityWeight = 0;

    for (var rarity in CardRarity.values) {
      if (availableRarities.contains(rarity)) {
        double weight = rarityWeights[rarity] ?? 0.0;
        if (weight > 0) {
          currentRarityWeights[rarity] = weight;
          totalRarityWeight += weight;
        }
      }
    }

    CardRarity selectedRarity;
    if (totalRarityWeight <= 0) {
      selectedRarity = availableRarities.first;
    } else {
      double roll = random.nextDouble() * totalRarityWeight;
      double cumulative = 0;
      selectedRarity = currentRarityWeights.keys.first;
      for (var entry in currentRarityWeights.entries) {
        cumulative += entry.value;
        if (roll <= cumulative) {
          selectedRarity = entry.key;
          break;
        }
      }
    }

    final rarityPool = candidatePool.where((c) => c.rarity == selectedRarity).toList();
    if (rarityPool.isEmpty) return null;

    double totalCardWeight = 0;
    final List<double> cardWeights = [];

    for (var card in rarityPool) {
      double weight = 1.0;
      final bool isCompleted = unlockedSets.contains(card.collectionId);

      if (isCompleted) {
        weight *= 0.15;
      } else {
        final bool isOwned = ownedIds.contains(card.id);
        if (!isOwned) {
          final collectionCards = cardRegistry.where((c) => c.collectionId == card.collectionId).toList();
          final ownedCount = collectionCards.where((c) => ownedIds.contains(c.id)).length;
          if (ownedCount == 5) {
            weight *= 1.4;
          } else if (ownedCount == 4) {
            weight *= 1.2;
          }
        }
      }
      cardWeights.add(weight);
      totalCardWeight += weight;
    }

    double cardRoll = random.nextDouble() * totalCardWeight;
    double cardCumulative = 0;
    for (int i = 0; i < rarityPool.length; i++) {
      cardCumulative += cardWeights[i];
      if (cardRoll <= cardCumulative) {
        return rarityPool[i];
      }
    }

    return rarityPool.last;
  }
}
