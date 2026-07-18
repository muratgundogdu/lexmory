import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/debug_config.dart';
import '../../game/providers/game_provider.dart';
import '../../library/provider/library_provider.dart';
import '../../tutorial/providers/tutorial_provider.dart';
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
    final tutorial = ref.watch(tutorialProvider);

    // 2. BİLDİRİM NOKTASI MANTIĞI: Para yetiyor mu kontrol et
    final bool showBadge = libraryNotifier.canAffordAnyUpgrade(gameState.tokens);

    final Widget navContent = Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: DebugConfig.enableBackdropBlurs ? 0.8 : 0.95),
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
          _buildNavItem(ref, 0, Icons.grid_view_rounded, currentIndex == 0, isLocked: tutorial.isNavigationLocked, key: const ValueKey('nav_game')),

          _buildNavItem(
            ref,
            1,
            Icons.menu_book_rounded,
            currentIndex == 1,
            showBadge: showBadge,
            isLocked: tutorial.isNavigationLocked,
            key: const ValueKey('nav_library'),
          ),

          _buildNavItem(ref, 2, Icons.shopping_bag_rounded, currentIndex == 2, isLocked: tutorial.isNavigationLocked, key: const ValueKey('nav_store')),
          _buildNavItem(ref, 3, Icons.settings_rounded, currentIndex == 3, isLocked: tutorial.isNavigationLocked, key: const ValueKey('nav_settings')),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.s24,
        right: AppDimens.s24,
        bottom: bottomPadding > 0 ? bottomPadding : AppDimens.s24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        child: DebugConfig.enableBackdropBlurs
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: navContent,
              )
            : navContent,
      ),
    ).animate().slideY(
      begin: 1, 
      end: 0, 
      duration: 600.ms, 
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildNavItem(
      WidgetRef ref,
      int index,
      IconData icon,
      bool isActive, {
        bool showBadge = false,
        bool isLocked = false,
        Key? key,
      }) {
    return GestureDetector(
      key: key,
      onTap: isLocked ? null : () => ref.read(navigationProvider.notifier).state = index,
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
                Icon(
                  icon,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  size: 26,
                ).animate(target: isActive ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 200.ms,
                ),

                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2C078),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
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
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

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
