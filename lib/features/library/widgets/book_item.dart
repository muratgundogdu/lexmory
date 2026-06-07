import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';

class BookItem extends StatelessWidget {
  final String categoryName;
  final bool isCompleted;
  final int index;

  const BookItem({
    super.key,
    required this.categoryName,
    required this.isCompleted,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.surfaceElevated : AppColors.background,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppDimens.radiusMedium),
                bottomRight: Radius.circular(AppDimens.radiusMedium),
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
                width: 1.5,
              ),
              boxShadow: [
                if (isCompleted)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                const BoxShadow(
                  color: Colors.black38,
                  offset: Offset(-4, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Kitap Sırtı
                Positioned(
                  left: 6,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 1.5,
                    color: isCompleted
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                // İkon ve Durum
                Center(
                  child: Icon(
                    isCompleted ? Icons.menu_book_rounded : Icons.lock_outline_rounded,
                    color: isCompleted ? AppColors.primary : AppColors.textMuted,
                    size: 32,
                  ),
                ),
                // "Mühür" (Eğer tamamlanmışsa)
                if (isCompleted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: const Icon(Icons.verified, color: AppColors.primary, size: 16),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          categoryName.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10,
            color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: isCompleted ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(delay: (index % 6 * 100).ms).slideY(begin: 0.1);
  }
}