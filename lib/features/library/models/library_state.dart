class LibraryState {
  final Map<String, int> roomStages; // roomId -> currentStageIndex
  final List<String> unlockedRoomIds;

  LibraryState({
    required this.roomStages,
    required this.unlockedRoomIds,
  });

  LibraryState copyWith({
    Map<String, int>? roomStages,
    List<String>? unlockedRoomIds,
  }) {
    return LibraryState(
      roomStages: roomStages ?? this.roomStages,
      unlockedRoomIds: unlockedRoomIds ?? this.unlockedRoomIds,
    );
  }
}