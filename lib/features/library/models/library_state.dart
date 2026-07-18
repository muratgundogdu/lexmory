import 'room_completion_reward_result.dart';

class LibraryState {
  final Map<String, int> roomStages; // roomId -> currentStageIndex
  final List<String> unlockedRoomIds;
  final Set<String> claimedRoomRewardIds;
  final RoomCompletionRewardResult? pendingCelebration;
  final String? newlyUnlockedRoomId; // For automatic focus/glow

  LibraryState({
    required this.roomStages,
    required this.unlockedRoomIds,
    this.claimedRoomRewardIds = const {},
    this.pendingCelebration,
    this.newlyUnlockedRoomId,
  });

  factory LibraryState.initial() {
    return LibraryState(
      roomStages: {
        'room_01': 0,
      },
      unlockedRoomIds: ['room_01'],
      claimedRoomRewardIds: {},
    );
  }

  LibraryState copyWith({
    Map<String, int>? roomStages,
    List<String>? unlockedRoomIds,
    Set<String>? claimedRoomRewardIds,
    RoomCompletionRewardResult? pendingCelebration,
    bool clearPendingCelebration = false,
    String? newlyUnlockedRoomId,
    bool clearNewlyUnlockedRoomId = false,
  }) {
    return LibraryState(
      roomStages: roomStages ?? this.roomStages,
      unlockedRoomIds: unlockedRoomIds ?? this.unlockedRoomIds,
      claimedRoomRewardIds: claimedRoomRewardIds ?? this.claimedRoomRewardIds,
      pendingCelebration: clearPendingCelebration ? null : (pendingCelebration ?? this.pendingCelebration),
      newlyUnlockedRoomId: clearNewlyUnlockedRoomId ? null : (newlyUnlockedRoomId ?? this.newlyUnlockedRoomId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomStages': roomStages,
      'unlockedRoomIds': unlockedRoomIds,
      'claimedRoomRewardIds': claimedRoomRewardIds.toList(),
      'pendingCelebration': pendingCelebration?.toJson(),
      'newlyUnlockedRoomId': newlyUnlockedRoomId,
    };
  }

  factory LibraryState.fromJson(Map<String, dynamic> json) {
    return LibraryState(
      roomStages: Map<String, int>.from(json['roomStages'] ?? {}),
      unlockedRoomIds: List<String>.from(json['unlockedRoomIds'] ?? []),
      claimedRoomRewardIds: Set<String>.from(json['claimedRoomRewardIds'] ?? []),
      pendingCelebration: json['pendingCelebration'] != null
          ? RoomCompletionRewardResult.fromJson(json['pendingCelebration'])
          : null,
      newlyUnlockedRoomId: json['newlyUnlockedRoomId'],
    );
  }
}
