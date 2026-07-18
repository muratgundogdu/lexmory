import 'package:flutter/foundation.dart';
import '../features/library/models/room_reward_config.dart';

final Map<String, RoomRewardConfig> roomRewards = {
  'room_01': const RoomRewardConfig(
    tokens: 500,
    hints: 1,
    removeWrongs: 1,
    chestTypeId: 'silver_chest',
  ),
  'room_02': const RoomRewardConfig(
    tokens: 750,
    hints: 2,
    removeWrongs: 2,
    chestTypeId: 'silver_chest',
  ),
  'room_03': const RoomRewardConfig(
    tokens: 1000,
    hints: 2,
    removeWrongs: 2,
    chestTypeId: 'golden_chest',
  ),
  'room_04': const RoomRewardConfig(
    tokens: 1250,
    hints: 3,
    removeWrongs: 3,
    chestTypeId: 'golden_chest',
  ),
  'room_05': const RoomRewardConfig(
    tokens: 1500,
    hints: 3,
    removeWrongs: 3,
    chestTypeId: 'golden_chest',
  ),
};

RoomRewardConfig getRewardForRoom(String roomId) {
  final reward = roomRewards[roomId];
  if (reward == null) {
    if (kDebugMode) {
      debugPrint('WARNING: No room completion reward configured for room: $roomId. Using fallback.');
    }
    // Fallback for production safely
    return const RoomRewardConfig(
      tokens: 500,
      hints: 1,
      removeWrongs: 1,
      chestTypeId: 'wooden_chest',
    );
  }
  return reward;
}
