import 'card_reward_result.dart';

class ChestOpenResult {
  final List<CardRewardResult> rewards;
  final int duplicateTokens;
  final int completionRewardTokens;
  final int totalGrantedTokens;
  final Set<String> completedCollectionIds;
  final Set<String> unlockedCharacterIds;
  final int finalPityCounter;

  const ChestOpenResult({
    required this.rewards,
    required this.duplicateTokens,
    required this.completionRewardTokens,
    required this.totalGrantedTokens,
    required this.completedCollectionIds,
    required this.unlockedCharacterIds,
    required this.finalPityCounter,
  });

  Map<String, dynamic> toJson() {
    return {
      'rewards': rewards.map((r) => r.toJson()).toList(),
      'duplicateTokens': duplicateTokens,
      'completionRewardTokens': completionRewardTokens,
      'totalGrantedTokens': totalGrantedTokens,
      'completedCollectionIds': completedCollectionIds.toList(),
      'unlockedCharacterIds': unlockedCharacterIds.toList(),
      'finalPityCounter': finalPityCounter,
    };
  }

  factory ChestOpenResult.fromJson(Map<String, dynamic> json) {
    return ChestOpenResult(
      rewards: (json['rewards'] as List).map((r) => CardRewardResult.fromJson(r)).toList(),
      duplicateTokens: json['duplicateTokens'],
      completionRewardTokens: json['completionRewardTokens'],
      totalGrantedTokens: json['totalGrantedTokens'],
      completedCollectionIds: Set<String>.from(json['completedCollectionIds'] ?? []),
      unlockedCharacterIds: Set<String>.from(json['unlockedCharacterIds'] ?? []),
      finalPityCounter: json['finalPityCounter'],
    );
  }
}
