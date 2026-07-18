import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../core/debug_config.dart';

class OutOfTokensOverlay extends StatelessWidget {
  final bool isVisible;
  final int currentTokens;
  final DateTime lastRegen;
  final int rewardAmount;
  final VoidCallback onWatchAd;
  final VoidCallback onStore;
  final bool isDismissible;
  final VoidCallback onClose;

  const OutOfTokensOverlay({
    super.key,
    required this.isVisible,
    required this.currentTokens,
    required this.lastRegen,
    required this.rewardAmount,
    required this.onWatchAd,
    required this.onStore,
    required this.isDismissible,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final Widget overlayContent = Container(
      color: AppColors.background.withValues(alpha: DebugConfig.enableBackdropBlurs ? 0.85 : 0.95),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 320,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.s24,
                  vertical: AppDimens.s32
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🪙", style: TextStyle(fontSize: AppDimens.iconXL + 12)),
                  const SizedBox(height: AppDimens.s24),

                  Text(
                    "TOKENLAR TÜKENDİ",
                    textAlign: TextAlign.center,
                    style: AppTypography.pageTitle.copyWith(color: AppColors.primary),
                  ),

                  const SizedBox(height: AppDimens.s12),

                  Text(
                    "Reklam izleyerek anında $rewardAmount token kazanabilirsin.",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),

                  const SizedBox(height: AppDimens.s32),

                  _buildLexButton(
                    label: "ÜCRETSİZ TOKEN",
                    subLabel: "+$rewardAmount TOKEN KAZAN",
                    icon: Icons.play_arrow_rounded,
                    isPrimary: true,
                    onTap: onWatchAd,
                  ),

                  const SizedBox(height: AppDimens.s12),

                  _buildLexButton(
                    label: "MAĞAZA",
                    subLabel: "DAHA FAZLASINI AL",
                    icon: Icons.shopping_bag_outlined,
                    isPrimary: false,
                    onTap: onStore,
                  ),
                ],
              ),
            ).animate().fade().scale(curve: Curves.easeOutBack),

            if (isDismissible)
              Positioned(
                top: -AppDimens.s12,
                right: -AppDimens.s12,
                child: _buildCloseButton(),
              ),
          ],
        ),
      ),
    );

    if (DebugConfig.enableBackdropBlurs) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: overlayContent,
      );
    }
    return overlayContent;
  }

  Widget _buildLexButton({
    required String label,
    required String subLabel,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppDimens.s16,
              horizontal: AppDimens.s20
          ),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            border: Border.all(
              color: isPrimary ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isPrimary ? AppColors.background : AppColors.primary),
              const SizedBox(width: AppDimens.s16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isPrimary ? AppColors.background : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 10,
                      color: isPrimary ? AppColors.background.withValues(alpha: 0.7) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: isPrimary ? AppColors.background : AppColors.border),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.s8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}
