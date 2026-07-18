import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../tutorial/models/tutorial_state.dart';
import '../../tutorial/providers/tutorial_provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

class JokerBar extends ConsumerWidget {
  final GameState game;
  final GlobalKey? hintKey;
  final GlobalKey? clearKey;
  final GlobalKey? revealKey;

  const JokerBar({
    super.key,
    required this.game,
    this.hintKey,
    this.clearKey,
    this.revealKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final tutorial = ref.watch(tutorialProvider);
    final step = tutorial.currentStep;
    final bool isTutorialActive = tutorial.isTutorialActive;

    // Tıklama İzinleri (Mevcut mantık korundu)
    final bool canUseHint = isTutorialActive ? (step == TutorialStep.forcedHint) : true;
    final bool canUseClear = isTutorialActive ? (step == TutorialStep.forcedClear) : true;
    final bool canUseReveal = isTutorialActive
        ? (step == TutorialStep.forcedReveal)
        : (game.hasStarted && !game.isInitialReveal);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.s16,
        vertical: AppDimens.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _JokerItem(
            key: hintKey,
            icon: Icons.lightbulb_outline_rounded,
            label: "Harf Aç",
            cost: 80,
            inventoryCount: game.hintInventory,
            onTap: canUseHint
                ? () async {
                    final bool wasFree = game.hintInventory > 0;
                    await notifier.useHint();
                    if (wasFree && context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ücretsiz Harf Aç kullanıldı'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                : null,
          ),
          _buildDivider(),
          _JokerItem(
            key: clearKey,
            icon: Icons.auto_fix_high_rounded,
            label: "Yanlış Sil",
            cost: 60,
            inventoryCount: game.removeWrongInventory,
            onTap: canUseClear
                ? () async {
                    final bool wasFree = game.removeWrongInventory > 0;
                    await notifier.clearWrong();
                    if (wasFree && context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ücretsiz Yanlışı Sil kullanıldı'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                : null,
          ),
          _buildDivider(),
          _JokerItem(
            key: revealKey,
            icon: Icons.visibility_outlined,
            label: "Tekrar",
            cost: 40,
            inventoryCount: 0,
            onTap: canUseReveal ? () => notifier.showAgain() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.border.withValues(alpha: 0.5),
    );
  }
}

class _JokerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int cost;
  final int inventoryCount;
  final VoidCallback? onTap;

  const _JokerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.cost,
    required this.inventoryCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;
    final bool hasInventory = inventoryCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon Alanı (Squirce/Rounded Corner Tasarımı)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.s12),
                  decoration: BoxDecoration(
                    color: isEnabled ? AppColors.surfaceElevated : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    border: Border.all(
                      color: isEnabled
                          ? (hasInventory ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3))
                          : AppColors.border,
                      width: hasInventory ? 2 : 1,
                    ),
                  ),
                  child: Icon(icon, color: isEnabled ? AppColors.primary : AppColors.textMuted, size: 24),
                ),
                if (isEnabled && hasInventory)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard, size: 10, color: Colors.black),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 800.ms),
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.s8),
            // Metin ve Token Etiketi
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            if (hasInventory)
              Text(
                "Ücretsiz ×$inventoryCount",
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🪙", style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text(
                    cost.toString(),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ).animate(target: isEnabled ? 1 : 0).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      duration: 200.ms,
    );
  }
}
