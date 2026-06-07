import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';

class StoreItemCard extends StatelessWidget {
  final String title;
  final String? description;
  final String rewardAmount;
  final String? price;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isAd;
  final bool isPopular;

  const StoreItemCard({
    super.key,
    required this.title,
    this.description,
    required this.rewardAmount,
    this.price,
    required this.icon,
    this.onTap,
    this.isAd = false,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isPopular ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          border: Border.all(
            color: isPopular ? AppColors.primary : AppColors.border,
            width: isPopular ? 2 : 1,
          ),
          boxShadow: [
            if (isPopular)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: 0,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: Text(
                    "POPÜLER",
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.background,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.s20),
              child: isAd ? _buildHorizontalLayout() : _buildVerticalLayout(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildVerticalLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: 12),
        Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🪙", style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(rewardAmount, style: AppTypography.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          price ?? "",
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTypography.cardTitle),
              Text(description ?? "", style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
            ],
          ),
        ),
        Text(
          "+$rewardAmount",
          style: AppTypography.pageTitle.copyWith(color: AppColors.primary, fontSize: 20),
        ),
      ],
    );
  }
}