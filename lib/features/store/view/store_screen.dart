import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../game/providers/game_provider.dart';
import '../widgets/store_item_card.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);

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
            // 1. Premium App Bar
            _buildSliverAppBar(game.tokens),

            // 2. Özel Teklifler / Reklam Bölümü
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppDimens.s24, AppDimens.s24, AppDimens.s24, 0),
                child: _buildSectionHeader("HIZLI DESTEK"),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.s24, vertical: AppDimens.s16),
                child: StoreItemCard(
                  title: "Ücretsiz Token",
                  description: "Kısa bir video izle ve 50 Token kazan.",
                  rewardAmount: "50",
                  icon: Icons.play_circle_fill_rounded,
                  onTap: () => ref.read(gameProvider.notifier).watchAdForTokens(),
                  isAd: true,
                ),
              ),
            ),

            // 3. Token Paketleri Bölümü
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppDimens.s24, AppDimens.s12, AppDimens.s24, 0),
                child: _buildSectionHeader("TOKEN PAKETLERİ"),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimens.s24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: AppDimens.s16,
                  mainAxisSpacing: AppDimens.s16,
                ),
                delegate: SliverChildListDelegate([
                  const StoreItemCard(
                    title: "Başlangıç",
                    rewardAmount: "250",
                    price: "₺19.99",
                    icon: Icons.auto_awesome_rounded,
                  ),
                  const StoreItemCard(
                    title: "Gezgin",
                    rewardAmount: "600",
                    price: "₺44.99",
                    icon: Icons.explore_rounded,
                    isPopular: true,
                  ),
                  const StoreItemCard(
                    title: "Bilge",
                    rewardAmount: "1500",
                    price: "₺99.99",
                    icon: Icons.history_edu_rounded,
                  ),
                  const StoreItemCard(
                    title: "Üstad",
                    rewardAmount: "4000",
                    price: "₺199.99",
                    icon: Icons.diamond_rounded,
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(int tokens) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "LEXMORY BOUTIQUE",
              style: AppTypography.labelSmall.copyWith(color: AppColors.primary, letterSpacing: 4),
            ),
            const SizedBox(height: AppDimens.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🪙", style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  tokens.toString(),
                  style: AppTypography.pageTitle.copyWith(fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}