import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/main/view/main_navigation_screen.dart';
import 'package:lexmory/features/tutorial/providers/tutorial_provider.dart';
import 'package:lexmory/features/tutorial/models/tutorial_state.dart';
import 'package:lexmory/features/main/providers/navigation_provider.dart';
import 'package:lexmory/features/library/provider/library_provider.dart';

// Mock Library Notifier to avoid animations/badge
class MockLibraryNotifier extends LibraryNotifier {
  MockLibraryNotifier(super.ref);

  
  @override
  bool canAffordAnyUpgrade(int tokens) => false;
}

// Mock Tutorial Controller to prevent _init from overwriting state
class MockTutorialController extends TutorialController {
  MockTutorialController(super.ref, TutorialState initialState) {
    state = initialState;
  }
}

void main() {
  testWidgets('MainNavigationScreen ignores bottom nav taps when spotlight is active', (tester) async {
    // Set a very tall height to ensure bottom nav is always on screen during entrance animations
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final initialState = TutorialState(
      currentStep: TutorialStep.category,
      phase: TutorialPhase.phase1,
      isTutorialActive: true,
      isSpotlightPending: true,
      requiredTabIndex: 0,
    );

    final container = ProviderContainer(
      overrides: [
        libraryProvider.overrideWith((ref) => MockLibraryNotifier(ref)),
        tutorialProvider.overrideWith((ref) => MockTutorialController(ref, initialState)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.zero),
            child: MainNavigationScreen(),
          ),
        ),
      ),
    );

    // Wait for slide-up animation to finish
    await tester.pump(const Duration(seconds: 2)); 

    expect(container.read(navigationProvider), 0);
    expect(container.read(tutorialProvider).isNavigationLocked, true);

    final libraryTab = find.byKey(const ValueKey('nav_library'));
    await tester.tap(libraryTab, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(navigationProvider), 0);
  });

  testWidgets('MainNavigationScreen allows bottom nav taps during "Sıra Sende" (Finding Letters)', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final initialState = TutorialState(
      currentStep: TutorialStep.findingLetters,
      phase: TutorialPhase.phase1,
      isTutorialActive: true,
      isSpotlightPending: false, 
      isSpotlightVisible: false,
      isSpotlightTransitioning: false,
      requiredTabIndex: null,
    );

    final container = ProviderContainer(
      overrides: [
        libraryProvider.overrideWith((ref) => MockLibraryNotifier(ref)),
        tutorialProvider.overrideWith((ref) => MockTutorialController(ref, initialState)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.zero),
            child: MainNavigationScreen(),
          ),
        ),
      ),
    );

    // Ensure all animations and post frame callbacks are processed
    await tester.pump(const Duration(seconds: 2));

    expect(container.read(navigationProvider), 0);
    expect(container.read(tutorialProvider).isNavigationLocked, false);

    final libraryTab = find.byKey(const ValueKey('nav_library'));
    
    // Tap specifically on the library tab
    await tester.tap(libraryTab, warnIfMissed: false);
    
    // We need multiple pumps sometimes to process the navigation change
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(navigationProvider), 1);
  });
}
