import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexmory/features/library/widgets/collection_placement_transition.dart';

void main() {
  testWidgets('CollectionPlacementTransition shows ownedContent immediately if shouldAnimate is false', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CollectionPlacementTransition(
            slot: Text('Slot'),
            ownedContent: Text('Owned'),
            incomingArtwork: Text('Artwork'),
            shouldAnimate: false,
          ),
        ),
      ),
    );

    expect(find.text('Owned'), findsOneWidget);
    expect(find.text('Slot'), findsNothing); // It should return ownedContent directly
  });

  testWidgets('CollectionPlacementTransition plays animation sequence when shouldAnimate is true', (tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CollectionPlacementTransition(
            slot: const Text('Slot'),
            lockedContent: const Text('Locked'),
            ownedContent: const Text('Owned'),
            incomingArtwork: const Text('Artwork'),
            shouldAnimate: true,
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    // Initial state: Slot and Locked should be visible (Locked might be fading)
    // Artwork should be visible (Arrival phase)
    expect(find.text('Slot'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('Artwork'), findsOneWidget);
    expect(find.text('Owned'), findsNothing);

    // Advance to middle of animation
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Artwork'), findsOneWidget);
    
    // Advance to end
    await tester.pump(const Duration(milliseconds: 1000));
    
    // Should be finished
    expect(find.text('Owned'), findsOneWidget);
    expect(completed, isTrue);
  });
}
