import 'package:flutter/material.dart';

class AlbumSet {
  final String id;
  final String name;
  final String characterName;
  final String characterImagePath;
  final int rewardTokens; // Consistent with UI usage
  final Color themeColor;

  const AlbumSet({
    required this.id,
    required this.name,
    required this.characterName,
    required this.characterImagePath,
    required this.rewardTokens,
    required this.themeColor,
  });

  AlbumSet copyWith({
    String? id,
    String? name,
    String? characterName,
    String? characterImagePath,
    int? rewardTokens,
    Color? themeColor,
  }) {
    return AlbumSet(
      id: id ?? this.id,
      name: name ?? this.name,
      characterName: characterName ?? this.characterName,
      characterImagePath: characterImagePath ?? this.characterImagePath,
      rewardTokens: rewardTokens ?? this.rewardTokens,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}
