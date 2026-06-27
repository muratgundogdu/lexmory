import 'package:flutter/material.dart';

class AlbumSet {
  final String name;          // Örn: 'Bilge Amca'
  final String coverImagePath;// Örn: 'lib/assets/album_covers/bilge_amca_cover.png'
  final int rewardTokens;     // Tamamlandığında verilecek ödül (Örn: 1000)
  final Color themeColor;     // Albüme özel neon renk (Örn: Altın sarısı, mor vs.)

  const AlbumSet({
    required this.name,
    required this.coverImagePath,
    required this.rewardTokens,
    required this.themeColor,
  });
}