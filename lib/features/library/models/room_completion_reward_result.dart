import 'chest_open_result.dart';

class RoomCompletionRewardResult {
  final String roomId;
  final String roomName;
  final int tokenReward;
  final int hintReward;
  final int removeWrongReward;
  final String chestTypeId;
  final ChestOpenResult chestResult;

  const RoomCompletionRewardResult({
    required this.roomId,
    required this.roomName,
    required this.tokenReward,
    required this.hintReward,
    required this.removeWrongReward,
    required this.chestTypeId,
    required this.chestResult,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'tokenReward': tokenReward,
      'hintReward': hintReward,
      'removeWrongReward': removeWrongReward,
      'chestTypeId': chestTypeId,
      'chestResult': chestResult.toJson(),
    };
  }

  factory RoomCompletionRewardResult.fromJson(Map<String, dynamic> json) {
    return RoomCompletionRewardResult(
      roomId: json['roomId'],
      roomName: json['roomName'],
      tokenReward: json['tokenReward'],
      hintReward: json['hintReward'],
      removeWrongReward: json['removeWrongReward'],
      chestTypeId: json['chestTypeId'],
      chestResult: ChestOpenResult.fromJson(json['chestResult']),
    );
  }
}
