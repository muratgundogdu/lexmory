import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexmory/features/missions/widgets/weekly_collection_card.dart';

void main() {
  Widget createWidget({
    required int current,
    required Set<int> claimedChests,
    Function(int)? onClaimChest,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: WeeklyCollectionCard(
            current: current,
            claimedChests: claimedChests,
            onClaimChest: onClaimChest,
          ),
        ),
      ),
    );
  }

  group('WeeklyCollectionCard Widget Tests', () {
    testWidgets('Progress 3/21 shows correct status text', (tester) async {
      await tester.pumpWidget(createWidget(current: 3, claimedChests: {}));

      expect(find.text('Sonraki Ödül'), findsOneWidget);
      expect(find.text('Bronz Sandık'), findsOneWidget);
      expect(find.text('4 kart kaldı'), findsOneWidget);
    });

    testWidgets('Progress 8/21 shows correct status text and highlights Silver', (tester) async {
      await tester.pumpWidget(createWidget(current: 8, claimedChests: {}));

      expect(find.text('Sonraki Ödül'), findsOneWidget);
      expect(find.text('Gümüş Sandık'), findsOneWidget);
      expect(find.text('6 kart kaldı'), findsOneWidget);
      
      expect(find.text('Sıradaki'), findsOneWidget); 
    });

    testWidgets('Progress 15/21 highlights Golden as the next reward', (tester) async {
      await tester.pumpWidget(createWidget(current: 15, claimedChests: {7, 14}));

      expect(find.text('Sonraki Ödül'), findsOneWidget);
      expect(find.text('Altın Sandık'), findsOneWidget);
      expect(find.text('6 kart kaldı'), findsOneWidget);
      
      expect(find.text('Sıradaki'), findsOneWidget);
    });

    testWidgets('Progress 21/21 shows completion text', (tester) async {
      await tester.pumpWidget(createWidget(current: 21, claimedChests: {7, 14, 21}));

      expect(find.text('Haftalık koleksiyon tamamlandı!'), findsOneWidget);
      expect(find.text('Tüm ödülleri topladın'), findsOneWidget);
    });

    testWidgets('Milestones use chest images', (tester) async {
      await tester.pumpWidget(createWidget(current: 0, claimedChests: {}));

      final images = find.byType(Image);
      expect(images, findsAtLeastNWidgets(3));
    });

    testWidgets('Milestones are positioned correctly on the track', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget(current: 0, claimedChests: {}));

      final pos7 = tester.getCenter(find.text('7'));
      final pos14 = tester.getCenter(find.text('14'));
      final pos21 = tester.getCenter(find.text('21'));

      expect(pos7.dx < pos14.dx, isTrue);
      expect(pos14.dx < pos21.dx, isTrue);
    });

    testWidgets('Claimed milestone shows check badge', (tester) async {
      await tester.pumpWidget(createWidget(current: 7, claimedChests: {7}));

      expect(find.text('Alındı'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Reached unclaimed milestone shows Hazır', (tester) async {
      await tester.pumpWidget(createWidget(current: 7, claimedChests: {}));

      expect(find.text('Hazır'), findsOneWidget);
    });

    testWidgets('Claim callback works when milestone is reached', (tester) async {
      int claimedValue = 0;
      await tester.pumpWidget(createWidget(
        current: 7,
        claimedChests: {},
        onClaimChest: (val) => claimedValue = val,
      ));

      await tester.tap(find.text('Hazır'));
      expect(claimedValue, 7);
    });

    testWidgets('Does not overflow at 360x640', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(createWidget(current: 3, claimedChests: {}));
      
      expect(tester.takeException(), isNull);
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('No medal icons remain', (tester) async {
      await tester.pumpWidget(createWidget(current: 3, claimedChests: {}));
      
      expect(find.text('🥉'), findsNothing);
      expect(find.text('🥈'), findsNothing);
      expect(find.text('🥇'), findsNothing);
    });
  });
}
