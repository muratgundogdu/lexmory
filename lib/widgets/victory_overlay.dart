import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../core/app_dimens.dart';
import '../core/app_typography.dart';
import '../core/debug_config.dart';

class PremiumRewardOverlay extends StatelessWidget {
  final bool isVisible;
  final int baseReward;
  final int memoryBonus;
  final int masterBonus;
  final double multiplier;
  final int totalReward;

  const PremiumRewardOverlay({
    super.key,
    required this.isVisible,
    required this.baseReward,
    required this.memoryBonus,
    required this.masterBonus,
    required this.multiplier,
    required this.totalReward,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final Widget overlayContent = Container(
      color: AppColors.background.withValues(alpha: DebugConfig.enableBackdropBlurs ? 0.85 : 0.95),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. İhtişamlı Başlık (Mükemmel/Tebrikler ayrımı içeride yapılıyor)
            _buildHeader(),

            const SizedBox(height: AppDimens.s32),

            // 2. Ana Ödül Kartı (Detaylı Puanlama)
            _buildRewardCard(),

            const SizedBox(height: AppDimens.s48),

            // 3. Alt Bilgi (Spinner kaldırıldı, daha temiz shimmer yazı eklendi)
            _buildFooterText(),
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

  Widget _buildHeader() {
    final bool isPerfect = memoryBonus > 0 && masterBonus > 0;
    final String title = isPerfect ? "MÜKEMMEL" : "TEBRİKLER";

    return Column(
      children: [
        const Text("✨", style: TextStyle(fontSize: 40))
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: AppDimens.s8),
        // Harf aralığı animasyonu için .custom kullanıyoruz
        Text(
          title,
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.primary,
            fontSize: 24,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .custom(
          begin: 15, // Başlangıç letterSpacing
          end: 8,    // Bitiş letterSpacing
          duration: 600.ms,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Text(
            title,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.primary,
              letterSpacing: value, // Animasyonlu değer buraya geliyor
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppDimens.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          // Satırlar sırayla (staggered) geliyor
          _buildRewardRow("TEMEL ÖDÜL", "+$baseReward", Icons.stars_rounded, 0),
          if (memoryBonus > 0)
            _buildRewardRow("HAFIZA BONUSU", "+$memoryBonus", Icons.psychology_rounded, 1),
          if (masterBonus > 0)
            _buildRewardRow("USTA BONUSU", "+$masterBonus", Icons.verified_rounded, 2),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimens.s16),
            child: Divider(color: AppColors.border, thickness: 1),
          ),

          // Çarpan Alanı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SERİ ÇARPANI",
                style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "x${multiplier.toStringAsFixed(1)}",
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: AppDimens.s24),

          // TOPLAM SKOR
          Column(
            children: [
              Text(
                "TOPLAM KAZANÇ",
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppDimens.s4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("🪙", style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppDimens.s12),
                  Text(
                    totalReward.toString(),
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 48,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildRewardRow(String label, String value, IconData icon, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.s8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.6)),
          const SizedBox(width: AppDimens.s12),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (150 * index).ms).slideX(begin: 0.1);
  }

  Widget _buildFooterText() {
    final textWidget = Text(
      "YENİ BÖLÜM HAZIRLANIYOR",
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 4,
      ),
    );

    if (DebugConfig.enableShimmers) {
      return textWidget.animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2.seconds, color: AppColors.primary)
          .fadeIn(delay: 1000.ms);
    }

    return textWidget.animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds)
        .fadeIn(delay: 1000.ms);
  }
}
