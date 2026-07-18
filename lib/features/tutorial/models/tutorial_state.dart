import 'package:flutter/material.dart';

enum TutorialPhase { phase1, phase2, contextual }

enum RealGameOnboardingStep {
  notStarted,
  hintJokerPending,
  clearJokerPending,
  waitingForFoundButton,
  revealJokerPending,
  completed,
}

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
  tokenInfo, 
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
  final RealGameOnboardingStep onboardingStep;

  // Onboarding Bayrakları
  final bool jokerTutorialShown;        
  final bool tokenTutorialShown;
  final bool hintClearTutorialShown;
  final bool revealTutorialShown;
  final bool hintJokerTutorialCompleted;
  final bool removeJokerTutorialCompleted;
  final bool tutorialCompleted;

  // Ücretsiz Kullanım Bayrakları
  final bool freeHintUsed;
  final bool freeRemoveUsed;
  final bool freeRevealUsed;

  // Spotlight sub-states
  final bool isSpotlightPending;
  final bool isSpotlightVisible;
  final bool isSpotlightTransitioning;

  final int? requiredTabIndex;

  TutorialState({
    required this.currentStep,
    required this.phase,
    required this.isTutorialActive,
    this.onboardingStep = RealGameOnboardingStep.notStarted,
    this.jokerTutorialShown = false,
    this.tokenTutorialShown = false,
    this.hintClearTutorialShown = false,
    this.revealTutorialShown = false,
    this.hintJokerTutorialCompleted = false,
    this.removeJokerTutorialCompleted = false,
    this.freeHintUsed = false,
    this.freeRemoveUsed = false,
    this.freeRevealUsed = false,
    this.tutorialCompleted = false,
    this.isSpotlightPending = false,
    this.isSpotlightVisible = false,
    this.isSpotlightTransitioning = false,
    this.requiredTabIndex,
  });

  bool get isNavigationLocked => isSpotlightPending || isSpotlightVisible || isSpotlightTransitioning;

  bool get onboardingFullyCompleted => 
    tutorialCompleted && 
    onboardingStep == RealGameOnboardingStep.completed;

  TutorialState copyWith({
    TutorialStep? currentStep,
    TutorialPhase? phase,
    bool? isTutorialActive,
    RealGameOnboardingStep? onboardingStep,
    bool? jokerTutorialShown,
    bool? tokenTutorialShown,
    bool? hintClearTutorialShown,
    bool? revealTutorialShown,
    bool? hintJokerTutorialCompleted,
    bool? removeJokerTutorialCompleted,
    bool? freeHintUsed,
    bool? freeRemoveUsed,
    bool? freeRevealUsed,
    bool? tutorialCompleted,
    bool? isSpotlightPending,
    bool? isSpotlightVisible,
    bool? isSpotlightTransitioning,
    int? requiredTabIndex,
  }) {
    return TutorialState(
      currentStep: currentStep ?? this.currentStep,
      phase: phase ?? this.phase,
      isTutorialActive: isTutorialActive ?? this.isTutorialActive,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      jokerTutorialShown: jokerTutorialShown ?? this.jokerTutorialShown,
      tokenTutorialShown: tokenTutorialShown ?? this.tokenTutorialShown,
      hintClearTutorialShown: hintClearTutorialShown ?? this.hintClearTutorialShown,
      revealTutorialShown: revealTutorialShown ?? this.revealTutorialShown,
      hintJokerTutorialCompleted: hintJokerTutorialCompleted ?? this.hintJokerTutorialCompleted,
      removeJokerTutorialCompleted: removeJokerTutorialCompleted ?? this.removeJokerTutorialCompleted,
      freeHintUsed: freeHintUsed ?? this.freeHintUsed,
      freeRemoveUsed: freeRemoveUsed ?? this.freeRemoveUsed,
      freeRevealUsed: freeRevealUsed ?? this.freeRevealUsed,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      isSpotlightPending: isSpotlightPending ?? this.isSpotlightPending,
      isSpotlightVisible: isSpotlightVisible ?? this.isSpotlightVisible,
      isSpotlightTransitioning: isSpotlightTransitioning ?? this.isSpotlightTransitioning,
      requiredTabIndex: requiredTabIndex ?? this.requiredTabIndex,
    );
  }

  @override
  String toString() {
    return 'TutorialState(step: $currentStep, active: $isTutorialActive, onboarding: $onboardingStep, pending: $isSpotlightPending, visible: $isSpotlightVisible, transitioning: $isSpotlightTransitioning, locked: $isNavigationLocked)';
  }
}
