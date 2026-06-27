import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../game/providers/game_provider.dart';
import '../../library/provider/library_provider.dart';
import '../providers/navigation_provider.dart';

class LexBottomNav extends ConsumerWidget {
  const LexBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 1. GEREKLİ VERİLERİ ÇEK
    final gameState = ref.watch(gameProvider);
    final libraryNotifier = ref.read(libraryProvider.notifier);

    // 2. BİLDİRİM NOKTASI MANTIĞI: Para yetiyor mu kontrol et
    // Not: Bu metodun library_provider içinde tanımlı olduğundan emin ol
    final bool showBadge = libraryNotifier.canAffordAnyUpgrade(gameState.tokens);

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.s24,
        right: AppDimens.s24,
        bottom: bottomPadding > 0 ? bottomPadding : AppDimens.s24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppDimens.radiusXL),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(ref, 0, Icons.grid_view_rounded, currentIndex == 0),

                // 3. KÜTÜPHANE İKONU (Badge desteği eklendi)
                _buildNavItem(
                  ref,
                  1,
                  Icons.menu_book_rounded,
                  currentIndex == 1,
                  showBadge: showBadge, // Badge durumunu buraya bağladık
                ),

                _buildNavItem(ref, 2, Icons.shopping_bag_rounded, currentIndex == 2),
                _buildNavItem(ref, 3, Icons.settings_rounded, currentIndex == 3),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart);
  }

  Widget _buildNavItem(
      WidgetRef ref,
      int index,
      IconData icon,
      bool isActive, {
        bool showBadge = false, // Bildirim noktası için yeni parametre
      }) {
    return GestureDetector(
      onTap: () => ref.read(navigationProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Ana İkon
                Icon(
                  icon,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  size: 26,
                ).animate(target: isActive ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 200.ms,
                ),

                // BİLDİRİM İŞARETİ (Altın Parlayan Nokta)
                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2C078), // Parlak Altın
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface, // NavBar yüzeyi ile kontrast
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF2C078).withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    )
                    // Oyuncunun dikkatini çeken hafif büyüme/küçülme efekti
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Aktif Tab Altındaki Küçük Altın Nokta
            AnimatedContainer(
              duration: 300.ms,
              width: isActive ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}