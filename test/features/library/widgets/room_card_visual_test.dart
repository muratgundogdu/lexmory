import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexmory/features/library/widgets/room_card.dart';

void main() {
  testWidgets('RoomCard Visual State Hierarchy Test', (WidgetTester tester) async {
    // Set large surface size to avoid overflows
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. COMPLETED ROOM
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomCard(
            name: 'Completed Room',
            description: 'Desc',
            progress: 1.0,
            imagePath: '',
            highlightGlow: false,
            onTap: () {},
          ),
        ),
      ),
    );

    final containerFinder = find.byType(AnimatedContainer);
    AnimatedContainer container = tester.widget<AnimatedContainer>(containerFinder);
    BoxDecoration decoration = container.decoration as BoxDecoration;
    
    // Should have neutral border (white with 0.15 alpha)
    expect(decoration.border!.top.color.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.15));
    expect(decoration.border!.top.width, 1.5);
    // Should have black shadow (no gold glow)
    expect(decoration.boxShadow![0].color.withValues(alpha: 1.0), Colors.black.withValues(alpha: 1.0));

    // 2. ACTIVE INCOMPLETE ROOM
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomCard(
            name: 'Active Room',
            description: 'Desc',
            progress: 0.5,
            imagePath: '',
            highlightGlow: true,
            onTap: () {},
          ),
        ),
      ),
    );

    // Wait for AnimatedContainer to finish transition
    await tester.pump(const Duration(seconds: 1));

    container = tester.widget<AnimatedContainer>(containerFinder);
    decoration = container.decoration as BoxDecoration;

    // Should have bright gold border (0xFFF2C078)
    expect(decoration.border!.top.color, const Color(0xFFF2C078));
    expect(decoration.border!.top.width, 3.0);
    // Should have golden glow
    expect(decoration.boxShadow![0].color, const Color(0xFFF2C078).withValues(alpha: 0.3));
    expect(decoration.boxShadow![0].blurRadius, 20.0);

    // 3. NEWLY UNLOCKED ROOM
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomCard(
            name: 'New Room',
            description: 'Desc',
            progress: 0.0,
            imagePath: '',
            highlightGlow: true,
            isNewlyUnlocked: true,
            onTap: () {},
          ),
        ),
      ),
    );

    // Should show "YENİ ODA" label
    expect(find.text('YENİ ODA'), findsOneWidget);
    
    container = tester.widget<AnimatedContainer>(containerFinder);
    decoration = container.decoration as BoxDecoration;
    // Should still have gold border
    expect(decoration.border!.top.color, const Color(0xFFF2C078));
  });

  testWidgets('RoomCard throws assertion if completed and active', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomCard(
            name: 'Error Room',
            description: 'Desc',
            progress: 1.0,
            imagePath: '',
            highlightGlow: true, 
            onTap: () {},
          ),
        ),
      ),
    );
    
    expect(tester.takeException(), isAssertionError);
  });
}
