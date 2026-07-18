import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_typography.dart';
import '../models/tutorial_state.dart';
import '../providers/tutorial_provider.dart';

class TutorialOverlay extends ConsumerStatefulWidget {
  final GlobalKey? targetKey;
  final String text;
  final String buttonText;
  final VoidCallback onNext;
  final bool showButton;
  final bool isInitialPhase;
  final TutorialStep? currentStep;

  const TutorialOverlay({
    super.key,
    this.targetKey,
    required this.text,
    this.buttonText = "ANLADIM",
    required this.onNext,
    this.showButton = true,
    this.isInitialPhase = false,
    this.currentStep,
  });

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  Rect? _spotlightRect;
  Timer? _timer;
  bool _didNotifyMounted = false;
  int _retryCount = 0;
  static const int _maxRetries = 10;

  @override
  void initState() {
    super.initState();
    _scheduleRectUpdate();
    // 100ms'de bir kontrol ederek çok daha akıcı bir takip sağlıyoruz
    _timer = Timer.periodic(100.ms, (_) {
      if (mounted) _updateRect();
    });
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep || oldWidget.targetKey != widget.targetKey) {
      _didNotifyMounted = false;
      _retryCount = 0;
      _scheduleRectUpdate();
    }
  }

  void _scheduleRectUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateRect();
    });
  }

  void _updateRect() {
    if (widget.targetKey == null) return;
    
    final context = widget.targetKey!.currentContext;
    if (context == null || !context.mounted) {
      _handleRetry();
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
      final newRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      
      if (newRect != _spotlightRect) {
        if (mounted) {
          setState(() => _spotlightRect = newRect);
        }
      }

      if (!_didNotifyMounted && widget.currentStep != null) {
        _didNotifyMounted = true;
        _notifyMounted();
      }
    } else {
      _handleRetry();
    }
  }

  void _notifyMounted() {
    // Notify provider after frame to avoid build-phase mutation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(tutorialProvider.notifier).onSpotlightMounted(widget.currentStep!);
      }
    });
  }

  void _handleRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      _scheduleRectUpdate();
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
    final rect = _spotlightRect ?? Rect.fromLTWH(size.width / 2, size.height / 2, 0, 0);

    return TweenAnimationBuilder<Rect?>(
      duration: 600.ms,
      curve: Curves.easeOutQuart,
      tween: RectTween(begin: rect, end: rect),
      builder: (context, animRect, _) {
        final r = animRect ?? rect;
        return Stack(
          children: [
            // 1. BARRIER WITH HOLE (Spotlight effect + Interaction control)
            _buildSpotlightBarrier(size, r),

            // Hedef Alan Çerçevesi (Görsel Yardımcı - Tıklamayı Engellemez)
            IgnorePointer(
              ignoring: true,
              child: Stack(
                children: [
                  Positioned.fromRect(
                    rect: r.inflate(4),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. BİLGİ KARTI (Tıklanabilir)
            _buildInfoCard(context, r),
          ],
        );
      },
    );
  }

  Widget _buildSpotlightBarrier(Size size, Rect rect) {
    final isLocked = ref.watch(tutorialProvider).isNavigationLocked;
    
    return Stack(
      children: [
        if (isLocked) ...[
          // Top
          Positioned(
            top: 0, left: 0, right: 0,
            height: rect.top.clamp(0, size.height),
            child: _buildBarrierPart(),
          ),
          // Bottom
          Positioned(
            top: rect.bottom.clamp(0, size.height), left: 0, right: 0, bottom: 0,
            child: _buildBarrierPart(),
          ),
          // Left
          Positioned(
            top: rect.top.clamp(0, size.height), 
            height: (rect.bottom - rect.top).clamp(0, size.height),
            left: 0, width: rect.left.clamp(0, size.width),
            child: _buildBarrierPart(),
          ),
          // Right
          Positioned(
            top: rect.top.clamp(0, size.height),
            height: (rect.bottom - rect.top).clamp(0, size.height),
            left: rect.right.clamp(0, size.width), right: 0,
            child: _buildBarrierPart(),
          ),
        ],
        
        IgnorePointer(
          ignoring: true,
          child: CustomPaint(
            size: size,
            painter: SpotlightPainter(
              rect: rect,
              shadowColor: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarrierPart() {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(color: Colors.transparent),
    );
  }

  Widget _buildInfoCard(BuildContext context, Rect spotlightRect) {
    final screenHeight = MediaQuery.of(context).size.height;
    final viewPadding = MediaQuery.of(context).padding;

    // Kartın konumu: Spotlight aşağıdaysa kart yukarı, yukarıdaysa aşağı
    final bool isSpotlightAtBottom = spotlightRect.center.dy > (screenHeight * 0.45);

    final bool isFixedStep = [
      TutorialStep.category,
      TutorialStep.wordBoxes,
      TutorialStep.grid,
    ].contains(widget.currentStep);

    final bool moveToTop = (widget.isInitialPhase || isFixedStep) ? false : isSpotlightAtBottom;

    return AnimatedPositioned(
      duration: 500.ms,
      curve: Curves.easeOutBack,
      top: moveToTop ? viewPadding.top + 80 : null,
      bottom: !moveToTop ? viewPadding.bottom + 140 : null, // Bottom Nav üstüne çıkarıldı
      left: 20,
      right: 20,
      child: Material( // Tıklanabilir butonlar için gerekli
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(height: 1.5),
              ),
              if (widget.showButton) ...[
                const SizedBox(height: 16),
                _buildButton(),
              ],
            ],
          ),
        ).animate(key: ValueKey(widget.text)).fadeIn().slideY(begin: 0.1),
      ),
    );
  }

  Widget _buildButton() {
    return InkWell(
      onTap: widget.onNext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
        ),
        child: Center(
          child: Text(widget.buttonText,
              style: AppTypography.labelSmall.copyWith(color: AppColors.background, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

// EK: Spotlight'ı pürüzsüz çizen ve deliği şeffaf bırakan Painter
class SpotlightPainter extends CustomPainter {
  final Rect rect;
  final Color shadowColor;

  SpotlightPainter({required this.rect, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = shadowColor;

    // Tüm ekranı boyayan ama hedef Rect alanını çıkaran (Subtract) yol
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) => rect != oldDelegate.rect;
}
