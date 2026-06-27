class LibraryState {  final Map<String, int> roomStages; // roomId -> currentStageIndex
final List<String> unlockedRoomIds;

LibraryState({
  required this.roomStages,
  required this.unlockedRoomIds,
});

// Başlangıç durumu için bir factory ekleyelim (Temiz bir başlangıç sağlar)
factory LibraryState.initial() {
  return LibraryState(
    roomStages: {
      'room_01': 0, // İlk oda 0. stage ile başlar
    },
    unlockedRoomIds: ['room_01'], // İlk oda varsayılan olarak açıktır
  );
}

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