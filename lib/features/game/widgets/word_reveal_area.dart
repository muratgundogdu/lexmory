import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../models/game_state.dart';

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
      // MediaQuery yerine constraints.maxWidth kullanmak daha güvenlidir
      final double availableTotalWidth = constraints.maxWidth;
      final int wordLength = game.targetWord.length;

      double boxMargin = AppDimens.s4;
      // Padding'leri düştükten sonra kalan alan
      double usableArea = availableTotalWidth - (AppDimens.s16 * 2);
      double boxWidth = (usableArea / wordLength) - (boxMargin * 2);

      // Sınırları belirle
      if (boxWidth > 48) boxWidth = 48;
      if (boxWidth < 28) boxWidth = 28;

      double boxHeight = boxWidth * 1.25;
      double fontSize = boxWidth * 0.65;

      // KRİTİK DÜZELTME: FittedBox ekleyerek taşmayı (overflow) engelliyoruz
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown, // İçerik büyükse orantılı küçültür, küçükse büyütmez
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min, // FittedBox'ın doğru çalışması için min olmalı
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(wordLength, (index) {
              final String? char = game.foundLetters[index];
              final bool isFilled = char != null;
              final bool isJustFound = game.justFoundIndex == index;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                key: (boxKeys != null && index < boxKeys!.length) ? boxKeys![index] : null,
                width: boxWidth,
                height: boxHeight,
                margin: EdgeInsets.symmetric(horizontal: boxMargin),
                decoration: BoxDecoration(
                  color: isFilled
                      ? AppColors.surfaceElevated
                      : AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  border: Border.all(
                    color: isJustFound
                        ? AppColors.primary
                        : (isFilled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
                    width: isJustFound ? 2.0 : 1.5,
                  ),
                  boxShadow: isFilled
                      ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: isJustFound ? 0.2 : 0.1),
                      blurRadius: isJustFound ? 15 : 8,
                    )
                  ]
                      : [],
                ),
                alignment: Alignment.center,
                child: isFilled
                    ? _buildLetter(char, fontSize, isJustFound)
                    : _buildEmptyPlaceholder(),
              );
            }),
          ),
        ),
      );
    });
  }

  Widget _buildLetter(String char, double fontSize, bool isJustFound) {
    return Text(
      char,
      style: AppTypography.displayLarge.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        shadows: isJustFound
            ? [const Shadow(color: AppColors.primary, blurRadius: 15)]
            : null,
      ),
    )
        .animate(target: 1)
        .fadeIn(duration: isJustFound ? 150.ms : 0.ms)
        .scale(
      begin: isJustFound ? const Offset(0.8, 0.8) : const Offset(1, 1),
      end: const Offset(1.0, 1.0),
      duration: isJustFound ? 200.ms : 0.ms,
      curve: Curves.easeOutBack,
    )
        .shimmer(
      duration: isJustFound ? 400.ms : 0.ms,
      color: AppColors.primaryLight.withValues(alpha: 0.3),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}