import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexmory/features/library/models/card_rarity.dart';
import 'package:lexmory/features/library/models/collection_card.dart';
import 'package:lexmory/features/library/widgets/pure_image_card.dart';

void main() {
  const mockCard = CollectionCard(
    id: 'test_card',
    name: 'Test Card Name',
    description: 'Description',
    rarity: CardRarity.rare,
    imagePath: 'lib/assets/cards/bilge_amca/bilge_sapkasi.webp',
    collectionId: 'set_01',
    setName: 'Set Name',
    stars: 2,
  );

  Widget createWidget({required bool isOwned, bool isMistikMode = false}) {
    return MaterialApp(
      home: Scaffold(
        body: PureImageCard(
          card: mockCard,
          isOwned: isOwned,
          isMistikMode: isMistikMode,
        ),
      ),
    );
  }

  group('PureImageCard Widget Tests', () {
    testWidgets('Unowned card uses reduced opacity on artwork', (tester) async {
      await tester.pumpWidget(createWidget(isOwned: false));

      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsOneWidget);

      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, 0.30);
      
      // Card name should be hidden for unowned
      expect(find.text('Test Card Name'), findsNothing);
      expect(find.text('???'), findsOneWidget);
    });

    testWidgets('Owned card uses full opacity (no Opacity widget on artwork)', (tester) async {
      await tester.pumpWidget(createWidget(isOwned: true));

      // In my implementation, I only return the image without Opacity/ColorFiltered if owned.
      // So find.byType(Opacity) should find nothing in the artwork layer.
      // Note: There might be other Opacity widgets in the card (e.g. name background), 
      // but let's check the core behavior.
      
      final opacityFinder = find.byType(Opacity);
      // If no Opacity widget is used for owned cards, this should be true.
      expect(opacityFinder, findsNothing);

      expect(find.text('Test Card Name'), findsOneWidget);
    });

    testWidgets('isMistikMode does not darken an owned card', (tester) async {
      await tester.pumpWidget(createWidget(isOwned: true, isMistikMode: true));

      // Artwork layer should still be full brightness (no Opacity widget)
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('Test Card Name'), findsOneWidget);
    });

    testWidgets('Unowned card shows lock icon', (tester) async {
      await tester.pumpWidget(createWidget(isOwned: false));
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('Owned card does not show lock icon', (tester) async {
      await tester.pumpWidget(createWidget(isOwned: true));
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });
  });
}
