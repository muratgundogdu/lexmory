import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

class LetterGrid extends ConsumerWidget {
  final GameState game;
  final List<GlobalKey>? tileKeys;

  const LetterGrid({super.key, required this.game, this.tileKeys});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        double availableHeight = constraints.maxHeight;
        double size = (availableWidth < availableHeight ? availableWidth : availableHeight);

        if (size > 420) size = 420;

        return SizedBox(
          width: size,
          height: size,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimens.s8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppDimens.s12,
              crossAxisSpacing: AppDimens.s12,
              childAspectRatio: 1.0,
            ),
            itemCount: game.gridLetters.length,
            itemBuilder: (context, index) {
              final String char = game.gridLetters[index];
              final bool isSelected = game.selectedIndices.contains(index);
              final bool isEliminated = game.eliminatedIndices.contains(index);
              final bool isCorrect = game.isLastAttemptCorrect ?? false;
              final bool isLastAttempt = game.lastAttemptIndex == index;

              // Harf görünme mantığı: Doğru seçildiyse, oyun başlamadıysa veya tekrar açıldıysa
              final bool showLetter = isSelected || !game.hasStarted || game.isInitialReveal;

              return _build3DCard(
                ref: ref,
                index: index,
                char: char,
                isSelected: isSelected,
                isEliminated: isEliminated,
                showLetter: showLetter,
                isLastAttempt: isLastAttempt,
                isCorrect: isCorrect,
              );
            },
          ),
        );
      },
    );
  }

  Widget _build3DCard({
    required WidgetRef ref,
    required int index,
    required String char,
    required bool isSelected,
    required bool isEliminated,
    required bool showLetter,
    required bool isLastAttempt,
    required bool isCorrect,
  }) {
    // 1. DURUM: Yanlış Sil Jokeri ile elenmiş kartlar
    // %70 küçülür, ters döner (?), kararır ve hiçbir animasyondan etkilenmez.
    if (isEliminated) {
      return _buildCardUI(
        content: "?",
        isOpened: false,
        isSelected: false,
        isError: false,
      )
          .animate()
      // 1. Önce kart bir sarsılır (seçildiğini belli eder)
          .shake(hz: 10, duration: 400.ms, curve: Curves.easeInOut)
      // 2. Ardından kararır ve küçülür
          .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(0.7, 0.7),
        duration: 600.ms,
        delay: 200.ms, // Sarsıntıdan hemen sonra başlasın
        curve: Curves.easeOutBack,
      )
          .custom(
        begin: 1.0,
        end: 0.4,
        duration: 600.ms,
        delay: 200.ms,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: child,
        ),
      )
      // 3. İçeriği tamamen grileştirir
          .tint(color: Colors.black, end: 0.5, duration: 600.ms);
    }

    // Hedef açı: Açık ise 180 derece (pi), kapalı ise 0 derece.
    final double targetAngle = showLetter ? pi : 0;

    // 2. DURUM: Aktif Kartlar (3D Flip Animasyonlu)
    return TweenAnimationBuilder<double>(
      // KRİTİK DÜZELTME: Oyun henüz başlamadıysa süre 0, başladıysa 1000ms (Yavaş dönüş)
      duration: game.hasStarted
          ? const Duration(milliseconds: 1000)
          : Duration.zero,
      curve: Curves.easeInOutBack,
      tween: Tween<double>(end: targetAngle),
      builder: (context, angle, child) {
        // 90 dereceden (pi/2) fazlaysa harfi göster, azsa "?" işaretini
        bool isPastHalf = angle > (pi / 2);

        return GestureDetector(
          onTap: isSelected ? null : () => ref.read(gameProvider.notifier).selectLetter(index),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // 3D Perspektif derinliği
              ..rotateY(angle),
            child: Transform(
              // Harfin ters görünmemesi için 90 dereceden sonra içeriği tekrar çeviriyoruz
              alignment: Alignment.center,
              transform: isPastHalf ? (Matrix4.identity()..rotateY(pi)) : Matrix4.identity(),
              child: _buildCardUI(
                key: (tileKeys != null && index < tileKeys!.length) ? tileKeys![index] : null,
                content: isPastHalf ? char : "?",
                isOpened: isPastHalf,
                isSelected: isSelected,
                isError: isLastAttempt && !isCorrect,
              ),
            ),
          ),
        );
      },
    ).animate(target: (isLastAttempt && !isCorrect) ? 1 : 0)
        .shake(hz: 8, duration: 400.ms);
  }

  Widget _buildCardUI({
    Key? key,
    required String content,
    required bool isOpened,
    required bool isSelected,
    required bool isError,
  }) {
    return Container(
      key: key,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : (isOpened ? AppColors.surfaceElevated : AppColors.surface),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isError
              ? AppColors.error
              : (isOpened ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border)),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(0, 2)
          ),
        ],
      ),
      child: Text(
        content,
        style: AppTypography.cardTitle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? AppColors.primary
              : (isError ? AppColors.error : (isOpened ? AppColors.textPrimary : AppColors.textMuted)),
        ),
      ),
    );
  }
}