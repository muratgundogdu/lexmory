import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../core/debug_config.dart';
import '../../library/models/chest_open_result.dart';
import '../../library/models/card_reward_result.dart';
import '../../library/widgets/reward_rarity_style.dart';
import '../../library/widgets/reward_ribbon.dart';
import '../providers/game_provider.dart';

class CategoryCompleteOverlay extends ConsumerWidget {
  final bool isVisible;
  final String categoryName;
  final int totalWrong;
  final int totalJokers;
  final int sectionCount;
  final VoidCallback onContinue;

  const CategoryCompleteOverlay({
    super.key,
    required this.isVisible,
    required this.categoryName,
    required this.totalWrong,
    required this.totalJokers,
    required this.sectionCount,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();

    final gameNotifierState = ref.watch(gameProvider);
    final bool hasDoubleClaimed = gameNotifierState.hasClaimedDoubleReward;
    final int displayedCategoryBonus = gameNotifierState.displayedCategoryBonus;
    final bool isDoubleRewardClaiming = gameNotifierState.isClaimingDoubleReward;
    final ChestOpenResult? rewardResult = gameNotifierState.categoryRewardResult;

    final Widget overlayContent = Container(
      color: AppColors.background.withValues(alpha: DebugConfig.enableBackdropBlurs ? 0.92 : 0.98),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: AppDimens.s40,
              bottom: 120,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDimens.s40),
                _buildRewardGallery(rewardResult),
                const SizedBox(height: AppDimens.s32),
                _buildRewardBadge(
                  hasDoubleClaimed,
                  displayedCategoryBonus,
                  isDoubleRewardClaiming,
                  () => ref.read(gameProvider.notifier).doubleRewardWithAd(),
                ),
                const SizedBox(height: AppDimens.s40),
                _buildStatsGrid(totalWrong, totalJokers, sectionCount),
                const SizedBox(height: AppDimens.s48),
                _buildContinueButton(onContinue),
              ],
            ),
          ),
        ),
      ),
    );

    if (DebugConfig.enableBackdropBlurs) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: overlayContent,
      );
    }
    return overlayContent;
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "KATEGORİ TAMAMLANDI",
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primary,
            letterSpacing: 4,
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
        const SizedBox(height: AppDimens.s8),
        Text(
          "KOLEKSİYON ÖDÜLLERİ",
          style: AppTypography.pageTitle.copyWith(
            fontSize: 20,
            color: AppColors.textPrimary,
            letterSpacing: 1,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildRewardGallery(ChestOpenResult? result) {
    if (result == null || result.rewards.isEmpty) {
      if (kDebugMode) {
        debugPrint("Warning: CategoryCompleteOverlay rewardResult is null or empty!");
      }
      return Center(
        child: Text(
          "Koleksiyon ödülü gösterilemedi.",
          style: AppTypography.bodyMedium.copyWith(color: Colors.white24),
        ),
      );
    }

    final rewards = result.rewards;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final int count = rewards.length;
        
        if (count == 1) {
          return Center(
            child: SizedBox(
              width: 160,
              height: 220,
              child: CategoryRewardCard(reward: rewards[0]),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
        }

        if (count <= 3) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rewards.map((r) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child: CategoryRewardCard(reward: r),
                  ),
                ),
              )).toList(),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
        }

        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            itemCount: count,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) => SizedBox(
              width: 140,
              child: CategoryRewardCard(reward: rewards[index]),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms);
      },
    );
  }

  Widget _buildRewardBadge(
    bool hasDoubleClaimed,
    int displayedCategoryBonus,
    bool isDoubleRewardClaiming,
    VoidCallback onDoubleRewardAction,
  ) {
    final shimmerEffect = DebugConfig.enableShimmers
        ? (Animate p) => p.shimmer(delay: 2.seconds, duration: 1.seconds, color: Colors.white24)
        : (Animate p) => p.scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🪙", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                "+$displayedCategoryBonus TOKEN KAZANILDI",
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),

        if (!hasDoubleClaimed) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isDoubleRewardClaiming ? null : onDoubleRewardAction,
            child: shimmerEffect(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4A574), Color(0xFFF2C078)],
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A574).withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    if (isDoubleRewardClaiming)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    else
                      const Icon(Icons.play_circle_fill, size: 16, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      "x2",
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) {
                if (!const bool.fromEnvironment('FLUTTER_TEST')) {
                  if (!isDoubleRewardClaiming) c.repeat(reverse: true);
                }
              })
              .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 800.ms, curve: Curves.easeInOut)
              .animate(onPlay: (c) {
                if (!const bool.fromEnvironment('FLUTTER_TEST')) {
                  c.repeat();
                }
              })
            ),
          ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2),
        ],
      ],
    );
  }

  Widget _buildStatsGrid(int totalWrong, int totalJokers, int sectionCount) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppDimens.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("BÖLÜM", sectionCount.toString(), Icons.check_circle_outline),
          _buildStatItem("HATA", totalWrong.toString(), Icons.close_rounded),
          _buildStatItem("JOKER", totalJokers.toString(), Icons.auto_fix_high_outlined),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w500)
        ),
      ],
    );
  }

  Widget _buildContinueButton(VoidCallback onContinue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s48),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onContinue,
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
              border: Border.all(color: AppColors.primary, width: 1.5),
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                "SIRADAKİ KATEGORİ",
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}

class CategoryRewardCard extends StatelessWidget {
  final CardRewardResult reward;

  const CategoryRewardCard({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    final card = reward.card;
    final rarityStyle = RewardRarityStyle.from(card.rarity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarityStyle.borderColor, width: 2),
        boxShadow: rarityStyle.glow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              card.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.style_rounded, size: 40, color: Colors.white10),
              ),
            ),
          ),
          
          // Info Overlay
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    card.setName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: rarityStyle.accentColor.withValues(alpha: 0.7),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ribbon Badge
          RewardRibbon(
            isNew: reward.isNew,
            duplicateTokenValue: reward.duplicateTokenValue,
          ),
        ],
      ),
    );
  }
}
