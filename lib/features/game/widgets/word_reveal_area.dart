import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WordRevealArea extends ConsumerWidget {
  final GameState game;
  final List<GlobalKey>? boxKeys;

  const WordRevealArea({
    super.key,
    required this.game,
    this.boxKeys,
  });

  @override
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
                ? _buildLetter(char, fontSize, isJustFound)
                : null,
          );
        }),
      );
    });
  }

  /// Anlık beliren ve hafif efektli harf widget'ı
  Widget _buildLetter(String char, double fontSize, bool isJustFound) {
    return Text(
      char,
      style: GoogleFonts.baloo2(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        // Yeni harf geldiğinde hafif bir dış ışıma (glow) ekler
        shadows: isJustFound
            ? [const Shadow(color: Colors.greenAccent, blurRadius: 15)]
            : null,
      ),
    )
        .animate(target: isJustFound ? 1 : 0)
    // 1. Anlık görsel tepki için hızlı bir büyüme efekti (200ms)
        .scale(
      begin: const Offset(0.7, 0.7),
      end: const Offset(1.0, 1.0),
      duration: 200.ms,
      curve: Curves.easeOutBack,
    )
    // 2. Yeni yerleşen harfe dikkat çekmek için kısa süreli parlama
        .shimmer(
      duration: 400.ms,
      color: Colors.white54,
    );
  }
}