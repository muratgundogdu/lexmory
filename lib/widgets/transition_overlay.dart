import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/debug_config.dart';

class TransitionOverlay extends StatefulWidget {
  final String? message;
  final int trigger;

  const TransitionOverlay({super.key, this.message, required this.trigger});

  @override
  State<TransitionOverlay> createState() => _TransitionOverlayState();
}

class _TransitionOverlayState extends State<TransitionOverlay> {
  bool _isVisible = false;

  @override
  void didUpdateWidget(TransitionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger && widget.message != null) {
      _showTransition();
    }
  }

  void _showTransition() {
    setState(() => _isVisible = true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || widget.message == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.brown[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                const SizedBox(height: 15),
                Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
              ],
            ),
          ),
        )
            .animate()
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutBack)
            .fadeOut(delay: 2.seconds, duration: 400.ms),
      ),
    ).animate().fadeIn(duration: 300.ms).fadeOut(delay: 2.2.seconds, duration: 300.ms);
  }

  Widget _buildIcon() {
    final iconWidget = const Icon(Icons.stars_rounded, color: Colors.amber, size: 60)
        .animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut);

    if (DebugConfig.enableShimmers) {
      return iconWidget.shimmer(delay: 600.ms);
    }
    return iconWidget;
  }
}
