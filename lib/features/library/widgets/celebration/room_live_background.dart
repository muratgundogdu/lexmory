import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/debug_config.dart';

class RoomLiveBackground extends StatelessWidget {
  final String roomId;
  final int stageCount;

  const RoomLiveBackground({
    super.key,
    required this.roomId,
    required this.stageCount,
  });

  @override
  Widget build(BuildContext context) {
    // Room 3 is "room_state", others are "room_stage" based on previous fix
    final String prefix = roomId == 'room_03' ? 'room_state' : 'room_stage';
    final String assetPath = 'lib/assets/library/$roomId/${prefix}_$stageCount.webp';

    return Stack(
      fit: StackFit.expand,
      children: [
        // The completed room image
        Image.asset(
          assetPath,
          fit: BoxFit.contain,
        ),

        // Warm golden overlay pulse
        _buildOverlayPulse(),

        // Dust particles (Simulated with small circles)
        const _DustParticles(),
        
        // Soft magical glow spots
        ...List.generate(3, (index) => _MagicalGlowSpot(index: index)),
      ],
    );
  }

  Widget _buildOverlayPulse() {
    final Widget pulse = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2C078).withValues(alpha: 0.05),
        gradient: DebugConfig.enableRoomLiveGradients 
          ? RadialGradient(
              colors: [
                const Color(0xFFF2C078).withValues(alpha: 0.15),
                Colors.transparent,
              ],
            )
          : null,
      ),
    );

    return pulse.animate(onPlay: (c) => c.repeat(reverse: true))
         .fadeIn(duration: 2.seconds);
  }
}

class _DustParticles extends StatelessWidget {
  const _DustParticles();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(15, (i) {
          final random = Random(i);
          return Positioned(
            left: random.nextDouble() * 400,
            top: random.nextDouble() * 800,
            child: Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat())
             .moveY(begin: 0, end: -20, duration: (2 + random.nextDouble() * 2).seconds)
             .fadeOut(),
          );
        }),
      ),
    );
  }
}

class _MagicalGlowSpot extends StatelessWidget {
  final int index;
  const _MagicalGlowSpot({required this.index});

  @override
  Widget build(BuildContext context) {
    final random = Random(index);
    return Positioned(
      left: 50 + random.nextDouble() * 200,
      top: 100 + random.nextDouble() * 400,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF2C078).withValues(alpha: 0.02),
          gradient: DebugConfig.enableRoomLiveGradients
            ? RadialGradient(
                colors: [
                  const Color(0xFFF2C078).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              )
            : null,
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: (3 + random.nextDouble()).seconds)
       .fadeIn(duration: 2.seconds),
    );
  }
}
