import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';

class CategoryCompleteOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: AppColors.background.withValues(alpha: 0.92),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.s40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Üst Başlık (Premium Tracking Effect)
                  _buildHeader(),

                  const SizedBox(height: AppDimens.s40),

                  // 2. Kazanılan Kitap (Görsel Odak)
                  _buildBookVisual(),

                  const SizedBox(height: AppDimens.s32),

                  // 3. Ödül Bilgisi (+150 Token)
                  _buildRewardBadge(),

                  const SizedBox(height: AppDimens.s40),

                  // 4. İstatistik Paneli
                  _buildStatsGrid(),

                  const SizedBox(height: AppDimens.s48),

                  // 5. Devam Et Butonu
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          "KÜTÜPHANENE EKLENDİ",
          style: AppTypography.pageTitle.copyWith(
            fontSize: 20,
            color: AppColors.textPrimary,
            letterSpacing: 1,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildBookVisual() {
    return Container(
      width: 150,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppDimens.radiusMedium),
          bottomRight: Radius.circular(AppDimens.radiusMedium),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black54,
            offset: Offset(-12, 12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Kitap Sırtı Detayı (Texture)
          Positioned(
            left: 10,
            top: 20,
            bottom: 20,
            child: Container(
              width: 1.5,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          // İçerik
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(height: 16),
                  Text(
                    categoryName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(
      duration: 800.ms,
      curve: Curves.easeOutBack,
    ).shimmer(delay: 1.seconds, duration: 2.seconds, color: Colors.white12);
  }

  Widget _buildRewardBadge() {
    return Container(
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
            "+150 TOKEN KAZANILDI",
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildStatsGrid() {
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
            style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary
            )
        ),
        Text(
            label,
            style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500
            )
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
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