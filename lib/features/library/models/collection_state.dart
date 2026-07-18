class CollectionState {
  final Set<String> ownedCardIds;
  final Set<String> unlockedCharacterIds;
  final Set<String> newlyUnlockedCardIds; // Cards acquired but not yet seen in library
  final int pityCounter;
  final bool isLoading;

  CollectionState({
    required this.ownedCardIds,
    required this.unlockedCharacterIds,
    this.newlyUnlockedCardIds = const {},
    required this.pityCounter,
    this.isLoading = false,
  });

  factory CollectionState.initial() {
    return CollectionState(
      ownedCardIds: {},
      unlockedCharacterIds: {},
      newlyUnlockedCardIds: {},
      pityCounter: 0,
      isLoading: false,
    );
  }

  CollectionState copyWith({
    Set<String>? ownedCardIds,
    Set<String>? unlockedCharacterIds,
    Set<String>? newlyUnlockedCardIds,
    int? pityCounter,
    bool? isLoading,
  }) {
    return CollectionState(
      ownedCardIds: ownedCardIds ?? this.ownedCardIds,
      unlockedCharacterIds: unlockedCharacterIds ?? this.unlockedCharacterIds,
      newlyUnlockedCardIds: newlyUnlockedCardIds ?? this.newlyUnlockedCardIds,
      pityCounter: pityCounter ?? this.pityCounter,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownedCardIds': ownedCardIds.toList(),
      'unlockedCharacterIds': unlockedCharacterIds.toList(),
      'newlyUnlockedCardIds': newlyUnlockedCardIds.toList(),
      'pityCounter': pityCounter,
    };
  }

  factory CollectionState.fromJson(Map<String, dynamic> json) {
    return CollectionState(
      ownedCardIds: Set<String>.from(json['ownedCardIds'] as List? ?? []),
      unlockedCharacterIds: Set<String>.from(json['unlockedCharacterIds'] as List? ?? []),
      newlyUnlockedCardIds: Set<String>.from(json['newlyUnlockedCardIds'] as List? ?? []),
      pityCounter: json['pityCounter'] as int? ?? 0,
      isLoading: false,
    );
  }
}
