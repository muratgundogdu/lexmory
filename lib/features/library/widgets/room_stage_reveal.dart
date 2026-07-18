import 'dart:math';

import 'package:flutter/material.dart';

/// Önceki stage sabit kalır; yeni stage üzerine "yerleşiyormuş" gibi belirir.
class RoomStageReveal extends StatefulWidget {
  final String roomId;
  final int stageIndex;
  final int? targetStageIndex; // Added to decouple animation from persistent state
  final int? revealFromStage;
  final Animation<double> revealAnimation;

  const RoomStageReveal({
    super.key,
    required this.roomId,
    required this.stageIndex,
    this.targetStageIndex,
    required this.revealFromStage,
    required this.revealAnimation,
  });

  @override
  State<RoomStageReveal> createState() => _RoomStageRevealState();
}

class _RoomStageRevealState extends State<RoomStageReveal> {
  String _asset(int stage) {
    final String prefix = widget.roomId == 'room_03' ? 'room_state' : 'room_stage';
    return 'lib/assets/library/${widget.roomId}/${prefix}_$stage.webp';
  }

  @override
  Widget build(BuildContext context) {
    final bool isRevealing = widget.revealFromStage != null;

    if (!isRevealing) {
      return _stageImage(_asset(widget.stageIndex));
    }

    return AnimatedBuilder(
      animation: widget.revealAnimation,
      builder: (context, _) {
        final t = widget.revealAnimation.value;
        const double contactPoint = 0.65;
        final bool hasContacted = t >= contactPoint;

        // 1. Background Logic: Switch from old to new exactly at contact
        // If targetStageIndex is provided, use it as the "new" stage to avoid dependency on provider state timing
        final int nextStage = widget.targetStageIndex ?? widget.stageIndex;
        final int backgroundStage = hasContacted ? nextStage : widget.revealFromStage!;

        // 2. Overlay Logic: Landing object
        // It arrives from 0.0 to 0.65
        final double arrivalOpacity = _interval(t, 0.0, 0.3, Curves.easeIn);
        final double arrivalScale = _interval(t, 0.0, contactPoint, Curves.easeOutBack, begin: 0.85, endValue: 1.0);
        final double arrivalTranslateY = _interval(t, 0.0, contactPoint, Curves.easeOutCubic, begin: -30.0, endValue: 0.0);

        // It fades out rapidly after contact to merge with the background
        final double overlayFadeOut = _interval(t, contactPoint, contactPoint + 0.15, Curves.easeOut, begin: 1.0, endValue: 0.0);

        // 3. Impact Settle Logic: Applied to the WHOLE background at contact
        final double impactScale = _interval(t, contactPoint, 1.0, Curves.elasticOut, begin: 1.02, endValue: 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // BASE LAYER: Switches from Old Room to New Room
            Transform.scale(
              scale: hasContacted ? impactScale : 1.0,
              child: _stageImage(_asset(backgroundStage)),
            ),

            // ANIMATED OVERLAY: The incoming object (represented by the next stage image)
            if (!hasContacted || overlayFadeOut > 0)
              Opacity(
                opacity: hasContacted ? overlayFadeOut : arrivalOpacity,
                child: Transform.translate(
                  offset: Offset(0, hasContacted ? 0 : arrivalTranslateY),
                  child: Transform.scale(
                    scale: hasContacted ? 1.0 : arrivalScale,
                    alignment: Alignment.bottomCenter,
                    child: _stageImage(_asset(nextStage)),
                  ),
                ),
              ),

            // GLOW/SPARKLE EFFECT
            if (hasContacted)
               _buildImpactGlow(t, contactPoint),
          ],
        );
      },
    );
  }

  Widget _buildImpactGlow(double t, double contactPoint) {
    final double glowOpacity = _interval(t, contactPoint, contactPoint + 0.3, Curves.easeOut, begin: 0.4, endValue: 0.0);
    if (glowOpacity <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFFF2C078).withValues(alpha: glowOpacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _stageImage(String path) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
    );
  }

  double _interval(
    double t,
    double start,
    double end,
    Curve curve, {
    double begin = 0.0,
    double endValue = 1.0,
  }) {
    if (t <= start) return begin;
    if (t >= end) return endValue;
    return begin + (endValue - begin) * curve.transform((t - start) / (end - start));
  }
}
