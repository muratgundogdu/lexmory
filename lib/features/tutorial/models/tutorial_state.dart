import 'package:flutter/material.dart';

enum TutorialPhase { phase1, phase2, contextual }

enum TutorialStep {
  category,
  wordBoxes,
  grid,
  startButton,
  findingLetters,
  success,
  phase2Intro,
  phase2Play,
  forcedHint,      // Adım 1: Harf Aç Zorunlu
  forcedClear,     // Adım 2: Yanlış Sil Zorunlu
  forcedReveal,
  tokenInfo, // Yeni eklenen adım
  completed
}

class TutorialKeys {
  static GlobalKey? categoryKey;
  static GlobalKey? wordAreaKey;
  static GlobalKey? gridKey;
  static GlobalKey? startButtonKey;
  static List<GlobalKey> gridTileKeys = [];
  static GlobalKey? hintKey;
  static GlobalKey? clearKey;
  static GlobalKey? revealKey;
  static GlobalKey? tokenKey;
}

class TutorialState {
  final TutorialStep currentStep;
  final TutorialPhase phase;
  final bool isTutorialActive;

  // Onboarding Bayrakları
  final bool jokerTutorialShown;        // <--- HATA VEREN EKSİK DEĞİŞKEN
  final bool tokenTutorialShown;
  final bool hintClearTutorialShown;
  final bool revealTutorialShown;
  final bool hintJokerTutorialCompleted;
  final bool removeJokerTutorialCompleted;

  // Ücretsiz Kullanım Bayrakları
  final bool freeHintUsed;
  final bool freeRemoveUsed;
  final bool freeRevealUsed;

  TutorialState({
    required this.currentStep,
    required this.phase,
    required this.isTutorialActive,
    this.jokerTutorialShown = false,
    this.tokenTutorialShown = false,
    this.hintClearTutorialShown = false,
    this.revealTutorialShown = false,
    this.hintJokerTutorialCompleted = false,
    this.removeJokerTutorialCompleted = false,
    this.freeHintUsed = false,
    this.freeRemoveUsed = false,
    this.freeRevealUsed = false,
  });

  TutorialState copyWith({
    TutorialStep? currentStep,
    TutorialPhase? phase,
    bool? isTutorialActive,
    bool? jokerTutorialShown,
    bool? tokenTutorialShown,
    bool? hintClearTutorialShown,
    bool? revealTutorialShown,
    bool? hintJokerTutorialCompleted,
    bool? removeJokerTutorialCompleted,
    bool? freeHintUsed,
    bool? freeRemoveUsed,
    bool? freeRevealUsed,
  }) {
    return TutorialState(
      currentStep: currentStep ?? this.currentStep,
      phase: phase ?? this.phase,
      isTutorialActive: isTutorialActive ?? this.isTutorialActive,
      jokerTutorialShown: jokerTutorialShown ?? this.jokerTutorialShown,
      tokenTutorialShown: tokenTutorialShown ?? this.tokenTutorialShown,
      hintClearTutorialShown: hintClearTutorialShown ?? this.hintClearTutorialShown,
      revealTutorialShown: revealTutorialShown ?? this.revealTutorialShown,
      hintJokerTutorialCompleted: hintJokerTutorialCompleted ?? this.hintJokerTutorialCompleted,
      removeJokerTutorialCompleted: removeJokerTutorialCompleted ?? this.removeJokerTutorialCompleted,
      freeHintUsed: freeHintUsed ?? this.freeHintUsed,
      freeRemoveUsed: freeRemoveUsed ?? this.freeRemoveUsed,
      freeRevealUsed: freeRevealUsed ?? this.freeRevealUsed,
    );
  }
}