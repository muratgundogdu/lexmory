import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/debug_config.dart';

class CelebrationRewardChest extends StatelessWidget {
  final String chestTypeId;
  final bool isOpened;

  const CelebrationRewardChest({
    super.key,
    required this.chestTypeId,
    required this.isOpened,
  });

  @override
  Widget build(BuildContext context) {
    // Basic image path logic, usually wooden/silver/golden
    final String assetPath = 'lib/assets/chests/$chestTypeId.webp';

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Falling & Shake animation
          Image.asset(
            assetPath,
            width: 180,
          ).animate(target: isOpened ? 1 : 0)
           .slideY(begin: -2.0, end: 0, duration: 800.ms, curve: Curves.bounceOut)
           .then()
           .shake(duration: 400.ms, hz: 4),

          // Glowing light when opened
          if (isOpened && DebugConfig.enableCelebrationGlow)
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF2C078).withValues(alpha: 0.6),
                    blurRadius: 40,
                    spreadRadius: DebugConfig.enableRoomCardHighlight ? 20 : 0,
                  )
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.5, 0.5)),
        ],
      ),
    );
  }
}
