import 'package:flutter/material.dart';

class TutorialKeys {
  static final GlobalKey categoryKey = GlobalKey();
  static final GlobalKey wordAreaKey = GlobalKey();
  static final GlobalKey gridKey = GlobalKey();
  static final GlobalKey startButtonKey = GlobalKey();
  static final GlobalKey tokenKey = GlobalKey();
  static final GlobalKey hintKey = GlobalKey();
  static final GlobalKey clearKey = GlobalKey();
  static final GlobalKey revealKey = GlobalKey();

  // BURASI KRİTİK: Liste boş olmamalı, 16 elemanla başlamalı
  static final List<GlobalKey> gridTileKeys = List.generate(16, (_) => GlobalKey());
}