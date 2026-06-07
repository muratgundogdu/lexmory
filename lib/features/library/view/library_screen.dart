import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../game/providers/game_provider.dart';
import '../../../../data/categories.dart'; // Ana kategori listesi
import '../widgets/book_item.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final completedCount = game.completedCategories.length;
    final totalCount = categories.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // 1. Premium App Bar (Modern & Minimal)
            _buildSliverAppBar(completedCount, totalCount),

            // 2. Kitap Rafları (Grid)
            SliverPadding(
              padding: const EdgeInsets.all(AppDimens.s24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: AppDimens.s20,
                  mainAxisSpacing: AppDimens.s32,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final category = categories[index];
                    final String catName = category['category'] as String;
                    final bool isCompleted = game.completedCategories.contains(catName);

                    return BookItem(
                      categoryName: catName,
                      isCompleted: isCompleted,
                      index: index,
                    );
                  },
                  childCount: totalCount,
                ),
              ),
            ),

            // Alt Boşluk (Navigation Bar için)
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(int completed, int total) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "BÜYÜK ARŞİV",
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Kütüphanen",
              style: AppTypography.pageTitle.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            _buildProgressBadge(completed, total),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBadge(int completed, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        "$completed / $total KİTAP",
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}