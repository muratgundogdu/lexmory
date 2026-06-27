class CollectionState {
  final List<String> ownedCardIds;
  final bool isLoading;

  CollectionState({
    required this.ownedCardIds,
    this.isLoading = false,
  });

  factory CollectionState.initial() {
    return CollectionState(ownedCardIds: []);
  }

  CollectionState copyWith({
    List<String>? ownedCardIds,
    bool? isLoading,
  }) {
    return CollectionState(
      ownedCardIds: ownedCardIds ?? this.ownedCardIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}