import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Eklendi
import '../../tutorial/providers/tutorial_provider.dart'; // Eklendi
import '../../tutorial/models/tutorial_state.dart'; // Eklendi

class WordRevealArea extends ConsumerWidget { // StatelessWidget -> ConsumerWidget yapıldı
  final GameState game;
  final List<GlobalKey>? boxKeys;

  const WordRevealArea({
    super.key,
    required this.game,
    this.boxKeys,
  });

  @override
  // ref parametresi eklendi
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final int wordLength = game.targetWord.length;

      double boxMargin = 5.0;
      double availableWidth = screenWidth - 40;
      double boxWidth = (availableWidth / wordLength) - (boxMargin * 2);

      if (boxWidth > 48) boxWidth = 48;
      if (boxWidth < 28) boxWidth = 28;

      double boxHeight = boxWidth * 1.2;
      double fontSize = boxWidth * 0.65;
      double totalWordRowWidth = wordLength * (boxWidth + (boxMargin * 2));

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(wordLength, (index) {
          final char = game.foundLetters[index];
          final isFilled = char != null;
          final isJustFound = game.justFoundIndex == index;

          return Container(
            key: (boxKeys != null && index < boxKeys!.length) ? boxKeys![index] : null,
            width: boxWidth,
            height: boxHeight,
            margin: EdgeInsets.symmetric(horizontal: boxMargin),
            decoration: BoxDecoration(
              color: isFilled
                  ? Colors.green.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(boxWidth * 0.25),
              border: Border.all(
                color: isFilled ? Colors.greenAccent : Colors.white.withValues(alpha: 0.3),
                width: 2.0,
              ),
              boxShadow: isFilled
                  ? [
                BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.25),
                    blurRadius: 10)
              ]
                  : [],
            ),
            alignment: Alignment.center,
            child: isFilled
                ? _buildFlyingLetter(
              index,
              char,
              fontSize,
              isJustFound,
              screenWidth,
              totalWordRowWidth,
              boxWidth,
              boxMargin,
              context, // <--- context parametresini buraya ekledik
              ref, // 9. parametre olarak ref gönderildi
            )
                : null,
          )
              .animate(target: isJustFound ? 1 : 0)
              .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.2, 1.2),
            duration: 400.ms,
            curve: Curves.elasticOut,
          );
        }),
      );
    });
  }

  Widget _buildFlyingLetter(
      int index,
      String char,
      double fontSize,
      bool isJustFound,
      double screenWidth,
      double totalWordRowWidth,
      double boxWidth,
      double boxMargin,
      BuildContext context, // <--- Parametreyi buraya ekledik
      WidgetRef ref, // ref burada tanımlı
      ) {
    double beginX = 0;
    double beginY = 0;

    if (isJustFound && game.lastAttemptIndex != null) {
      final int lastIdx = game.lastAttemptIndex!;
      final int gridCol = lastIdx % 4;
      final int gridRow = lastIdx ~/ 4;

      final double gridX = 50 +
          (gridCol * ((screenWidth - 100) / 4)) +
          ((screenWidth - 100) / 8);

      final double slotX = (screenWidth / 2) -
          (totalWordRowWidth / 2) +
          (index * (boxWidth + boxMargin * 2)) +
          (boxWidth / 2 + boxMargin);

      beginX = gridX - slotX;
      beginY = 380.0 + (gridRow * 50.0);
    }

    return Text(
      char,
      style: GoogleFonts.baloo2(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    )
        .animate(
      key: ValueKey("fly_${game.targetWord}_$index\_$char"),
    )
        .fadeIn(duration: 150.ms)
        .move(
      begin: Offset(beginX, beginY),
      end: Offset.zero,
      duration: 650.ms,
      curve: Curves.easeInOutExpo,
    )
        .scale(
      begin: isJustFound ? const Offset(0.4, 0.4) : const Offset(1, 1),
      end: const Offset(1, 1),
      duration: 650.ms,
      curve: Curves.easeOutBack,
    )
        .shimmer(delay: 600.ms, duration: 800.ms, color: Colors.white54);
  }
}
