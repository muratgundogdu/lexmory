import 'package:flutter/material.dart';

enum MissionStatus { ongoing, claimable, claimed }
enum ChestStatus { locked, claimable, claimed }

class MissionModel {
  final String id;
  final String icon;
  final String title;
  final int rewardToken;
  final int currentProgress;
  final int targetProgress;
  MissionStatus status;

  MissionModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.rewardToken,
    required this.currentProgress,
    required this.targetProgress,
    this.status = MissionStatus.ongoing,
  });
}