import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Önceki stage sabit kalır; yeni stage üzerine "yerleşiyormuş" gibi belirir.
class RoomStageReveal extends StatefulWidget {
  final String roomId;
  final int stageIndex;
  final int? revealFromStage;
  final Animation<double> revealAnimation;
  final bool showSparkles;

  const RoomStageReveal({
    super.key,
    required this.roomId,
    required this.stageIndex,
    required this.revealFromStage,
    required this.revealAnimation,
    this.showSparkles = false,
  });

  @override
  State<RoomStageReveal> createState() => _RoomStageRevealState();
}

class _RoomStageRevealState extends State<RoomStageReveal> {
  String _asset(int stage) =>
      'lib/assets/library/${widget.roomId}/room_stage_$stage.webp';

  @override
  Widget build(BuildContext context) {
    final bool isRevealing = widget.revealFromStage != null;
    final int baseStage =
        isRevealing ? widget.revealFromStage! : widget.stageIndex;

    return Stack(
      fit: StackFit.expand,
      children: [
        _stageImage(_asset(baseStage)),

        if (isRevealing)
          AnimatedBuilder(
            animation: widget.revealAnimation,
            builder: (context, _) {
              final t = widget.revealAnimation.value;
              final opacity = _interval(t, 0.12, 1.0, Curves.easeOutCubic);
              final scaleY = _interval(t, 0.0, 0.88, Curves.easeOutCubic, begin: 0.92, endValue: 1.0);
              final blur = _interval(t, 0.0, 0.55, Curves.easeOut, begin: 5.0, endValue: 0.0);
              final shimmer = _interval(t, 0.0, 0.35, Curves.easeOut, begin: 0.45, endValue: 0.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (shimmer > 0)
                    ColoredBox(
                      color: const Color(0xFFF2C078).withValues(alpha: shimmer * 0.22),
                    ),
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.diagonal3Values(1, scaleY, 1),
                        child: _stageImage(_asset(widget.stageIndex)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (isRevealing && widget.showSparkles)
          AnimatedBuilder(
            animation: widget.revealAnimation,
            builder: (context, _) => _StageSparkleOverlay(
              progress: widget.revealAnimation.value,
              seed: widget.revealFromStage!,
            ),
          ),
      ],
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

class _StageSparkleOverlay extends StatelessWidget {
  final double progress;
  final int seed;

  const _StageSparkleOverlay({required this.progress, required this.seed});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SparklePainter(progress: progress, seed: seed),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final int seed;

  _SparklePainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final rng = Random(seed * 9973);
    const particleCount = 28;

    for (int i = 0; i < particleCount; i++) {
      final birth = rng.nextDouble() * 0.45;
      final life = 0.25 + rng.nextDouble() * 0.45;
      final localT = ((progress - birth) / life).clamp(0.0, 1.0);
      if (localT <= 0 || localT >= 1) continue;

      final x = rng.nextDouble() * size.width;
      final baseY = size.height * (0.35 + rng.nextDouble() * 0.55);
      final y = baseY - localT * (40 + rng.nextDouble() * 60);
      final radius = 1.2 + rng.nextDouble() * 2.8;
      final alpha = sin(localT * pi) * (0.25 + rng.nextDouble() * 0.55);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFD4A574),
          const Color(0xFFF2C078),
          rng.nextDouble(),
        )!.withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), radius, paint);

      if (rng.nextBool()) {
        final glow = Paint()
          ..color = const Color(0xFFF2C078).withValues(alpha: alpha * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x, y), radius * 2.2, glow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.seed != seed;
}
