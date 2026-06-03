import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/letter_tile.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

/* 16 harflik ana oyun alanıdır. Harfleri 4x4 dizecek olan ızgara sistemini yönetir. */

class LetterGrid extends ConsumerWidget {
  final GameState game;
  final List<GlobalKey>? tileKeys; // TUTORIAL İÇİN EKLENDİ

  const LetterGrid({
    super.key,
    required this.game,
    this.tileKeys, // Parametrelere ekle
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: GridView.builder(
        key: ValueKey("grid_${game.targetWord}"),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: 16,
        itemBuilder: (context, index) {
          final isAttempting = game.lastAttemptIndex == index;

          return GestureDetector(
            onTap: () => ref.read(gameProvider.notifier).selectLetter(index),
            key: (tileKeys != null && index < tileKeys!.length) ? tileKeys![index] : null,
            child: LetterTile(
              index: index,
              letter: game.gridLetters[index],
              showFace: game.isInitialReveal ||
                  game.selectedIndices.contains(index) ||
                  isAttempting,
              isSelected: game.selectedIndices.contains(index),
              isWrong: isAttempting && game.isLastAttemptCorrect == false,
              isGlobalReveal: game.isInitialReveal,
              isEliminated: game.eliminatedIndices.contains(index),
            ),
          );
        },
      ),
    );
  }
}