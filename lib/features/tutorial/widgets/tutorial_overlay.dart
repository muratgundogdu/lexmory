import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/tutorial_state.dart';

class TutorialOverlay extends StatefulWidget {
  final GlobalKey? targetKey;
  final String text;
  final String buttonText;
  final VoidCallback onNext;
  final bool showButton;
  final bool isInitialPhase; // <--- Bu satırı ekleyin
  final TutorialStep? currentStep; // <--- Bu satırı ekleyin

  const TutorialOverlay({
    super.key,
    this.targetKey,
    required this.text,
    this.buttonText = "DEVAM",
    required this.onNext,
    this.showButton = true,
    this.isInitialPhase = false, // <--- Varsayılan olarak false yapın
    this.currentStep, // <--- Constructor'a ekleyin
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  Rect? _spotlightRect;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRect();
    _timer = Timer.periodic(300.ms, (_) => _updateRect());
  }

  void _updateRect() {
    if (widget.targetKey == null) return;
    final RenderBox? box = widget.targetKey!.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final newRect = box.localToGlobal(Offset.zero) & box.size;
      if (newRect != _spotlightRect) {
        setState(() => _spotlightRect = newRect);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rect = _spotlightRect ?? Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 0, height: 0
    );

    return Stack(
      children: [
        // 1. Dinamik Spotlight Katmanı
        TweenAnimationBuilder<Rect?>(
          duration: 400.ms,
          curve: Curves.easeInOut,
          tween: RectTween(begin: rect, end: rect),
          builder: (context, animRect, _) {
            final r = animRect ?? Rect.zero;
            return Stack(
              children: [
                Positioned(top: 0, left: 0, right: 0, height: r.top, child: _blackOverlay()),
                Positioned(top: r.bottom, left: 0, right: 0, bottom: 0, child: _blackOverlay()),
                Positioned(top: r.top, left: 0, width: r.left, height: r.height, child: _blackOverlay()),
                Positioned(top: r.top, left: r.right, right: 0, height: r.height, child: _blackOverlay()),

                // Çerçeve
                Positioned.fromRect(
                  rect: r.inflate(4),
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber.withValues(alpha:0.5), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // 2. SABİTLENMİŞ BİLGİ KARTI (EN ALT)
        _buildFixedBottomCard(context),
      ],
    );
  }

  Widget _blackOverlay() => Container(
    color: Colors.black.withValues(alpha:0.8),
    child: GestureDetector(onTap: () {}),
  );

  Widget _buildFixedBottomCard(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final viewPadding = MediaQuery.of(context).padding;

    // Spotlight konumu hesabı
    final bool isSpotlightAtBottom = _spotlightRect != null &&
        _spotlightRect!.center.dy > (screenHeight * 0.5);

    // --- KRİTİK DÜZENLEME ---
    // Metnin altta sabit kalması gereken adımları kontrol et
    final bool isFixedStep = [
      TutorialStep.category,
      TutorialStep.wordBoxes,
      TutorialStep.grid,
      TutorialStep.startButton,
      TutorialStep.findingLetters,
      TutorialStep.success,
    ].contains(widget.currentStep);

    // Eğer başlangıç aşamasındaysak VEYA isInitialPhase true ise kartı yukarı taşıma (false zorla)
    final bool moveToTop = (widget.isInitialPhase || isFixedStep) ? false : isSpotlightAtBottom;


    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      // Dinamik konumlandırma artık moveToTop değişkenine bakıyor:
      top: moveToTop ? viewPadding.top + 80 : null,
      bottom: !moveToTop ? viewPadding.bottom + 40 : null,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D1B18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10)
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.showButton) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(widget.buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ).animate(key: ValueKey(widget.text)).fadeIn().slideY(begin: 0.2, end: 0),
    );
  }
}