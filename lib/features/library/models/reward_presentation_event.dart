import 'chest_open_result.dart';
import 'chest_reward_source.dart';

class RewardPresentationEvent {
  final String id;
  final ChestRewardSource source;
  final ChestOpenResult result;
  final DateTime createdAt;
  final String? title;
  final String? subtitle;

  RewardPresentationEvent({
    required this.id,
    required this.source,
    required this.result,
    required this.createdAt,
    this.title,
    this.subtitle,
  });
}
