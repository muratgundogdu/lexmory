class RoomRewardConfig {
  final int tokens;
  final int hints;
  final int removeWrongs;
  final String chestTypeId; // Keeping ID to match registry architecture

  const RoomRewardConfig({
    required this.tokens,
    required this.hints,
    required this.removeWrongs,
    required this.chestTypeId,
  });
}
