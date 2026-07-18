import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CollectionPlacementTransition extends StatefulWidget {
  final Widget slot;
  final Widget? lockedContent;
  final Widget incomingArtwork;
  final Widget ownedContent;
  final bool shouldAnimate;
  final VoidCallback? onCompleted;
  final Duration staggerDelay;

  const CollectionPlacementTransition({
    super.key,
    required this.slot,
    this.lockedContent,
    required this.incomingArtwork,
    required this.ownedContent,
    required this.shouldAnimate,
    this.onCompleted,
    this.staggerDelay = Duration.zero,
  });

  @override
  State<CollectionPlacementTransition> createState() => _CollectionPlacementTransitionState();
}

class _CollectionPlacementTransitionState extends State<CollectionPlacementTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isAnimationFinished = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: 800.ms,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final bool disableAnimations = MediaQuery.of(context).disableAnimations;

      if (widget.shouldAnimate && !disableAnimations) {
        Future.delayed(widget.staggerDelay, () {
          if (mounted) {
            _controller.forward().then((_) {
              if (mounted) {
                setState(() => _isAnimationFinished = true);
              }
              widget.onCompleted?.call();
            });
          }
        });
      } else {
        _isAnimationFinished = true;
        if (widget.shouldAnimate) {
          // If it was supposed to animate but animations are disabled, still notify completion
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCompleted?.call();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;

    if (_isAnimationFinished || !widget.shouldAnimate || disableAnimations) {
      return widget.ownedContent;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Permanent slot background with reaction
        _buildSlotWithReaction(),

        // 2. Locked content (visible until covered or replaced)
        if (widget.lockedContent != null)
          Opacity(
            opacity: (1.0 - _controller.value).clamp(0.0, 1.0),
            child: widget.lockedContent,
          ),

        // 3. Incoming collectible artwork (Animated foreground layer)
        RepaintBoundary(child: _buildIncomingArtwork()),

        // 4. Impact pulse effect
        _buildImpactPulse(),
      ],
    );
  }

  Widget _buildSlotWithReaction() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        double scale = 1.0;
        
        // Slot reaction begins around 0.65 (Placement near end)
        if (val > 0.65) {
          final t = (val - 0.65) / 0.35;
          // sequence: 1.0 -> 0.985 -> 1.01 -> 1.0
          if (t < 0.4) {
            scale = 1.0 - (0.015 * (t / 0.4));
          } else if (t < 0.8) {
            scale = 0.985 + (0.025 * ((t - 0.4) / 0.4));
          } else {
            scale = 1.01 - (0.01 * ((t - 0.8) / 0.2));
          }
        }
        
        return Transform.scale(
          scale: scale,
          child: widget.slot,
        );
      },
    );
  }

  Widget _buildIncomingArtwork() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        
        // Phase 1: Arrival (0.0 - 0.3)
        // Phase 2: Placement (0.3 - 0.7)
        // Phase 3: Settle impact (0.7 - 1.0)
        
        double opacity = 0;
        double translateY = 0;
        double scale = 1.0;
        double rotation = 0;

        if (val < 0.3) {
          // Arrival
          final t = val / 0.3;
          opacity = Curves.easeOut.transform(t);
          translateY = -35 * (1 - t);
          scale = 1.15 - (0.13 * t); // 1.15 -> 1.02
          rotation = 0.05 * (1 - t); // ~3 degrees -> 0
        } else if (val < 0.7) {
          // Placement
          final t = (val - 0.3) / 0.4;
          opacity = 1.0;
          translateY = 0;
          scale = 1.02 - (0.06 * t); // 1.02 -> 0.96
          rotation = 0;
        } else {
          // Settle Impact
          final t = (val - 0.7) / 0.3;
          opacity = 1.0;
          translateY = 0;
          // Scale bounce: 0.96 -> 1.025 -> 1.0
          if (t < 0.5) {
            scale = 0.96 + (0.065 * (t / 0.5));
          } else {
            scale = 1.025 - (0.025 * ((t - 0.5) / 0.5));
          }
          rotation = 0;
        }

        return Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setTranslationRaw(0.0, translateY, 0.0)
              ..scaleByDouble(scale, scale, 1.0, 1.0)
              ..rotateZ(rotation),
            child: widget.incomingArtwork,
          ),
        );
      },
    );
  }

  Widget _buildImpactPulse() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        if (val < 0.65 || val > 0.9) return const SizedBox.shrink();

        final t = (val - 0.65) / 0.25;
        final pulseScale = 1.0 + (0.1 * t);
        final pulseOpacity = (1.0 - t).clamp(0.0, 1.0);

        return Opacity(
          opacity: pulseOpacity,
          child: Transform.scale(
            scale: pulseScale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
