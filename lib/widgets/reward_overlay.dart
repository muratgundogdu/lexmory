import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RewardOverlay extends StatefulWidget {
  final int trigger;
  final GlobalKey tokenKey;

  const RewardOverlay({super.key, required this.trigger, required this.tokenKey});

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay> {
  bool _isAnimating = false;
  final Random _random = Random();
  late List<Offset> _scatterOffsets;

  @override
  void initState() {
    super.initState();
    _generateOffsets();
  }

  void _generateOffsets() {
    // 15 adet token için patlama yönleri (rastgele daire etrafında)
    _scatterOffsets = List.generate(15, (_) {
      final double angle = _random.nextDouble() * 2 * pi;
      final double distance = 60 + _random.nextDouble() * 80;
      return Offset(cos(angle) * distance, sin(angle) * distance);
    });
  }

  @override
  void didUpdateWidget(RewardOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _generateOffsets();
      setState(() => _isAnimating = true);

      // Animasyon süresi bittikten sonra temizle
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _isAnimating = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAnimating) return const SizedBox.shrink();

    final Size screenSize = MediaQuery.of(context).size;
    final Offset screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

    // Hedef koordinat hesaplama (Cüzdan/Badge widget'ının konumu)
    Offset targetGlobalPos = Offset(screenSize.width - 50, 50); // Fallback
    final RenderBox? badgeBox = widget.tokenKey.currentContext?.findRenderObject() as RenderBox?;
    if (badgeBox != null) {
      targetGlobalPos = badgeBox.localToGlobal(badgeBox.size.center(Offset.zero));
    }

    // Merkeze göre hedefin mesafesi
    final Offset relativeTarget = targetGlobalPos - screenCenter;

    return IgnorePointer(
      child: Stack(
        children: List.generate(15, (index) {
          final Offset scatter = _scatterOffsets[index];
          final Duration staggerDelay = (index * 50).ms;

          return Positioned(
            left: screenCenter.dx - 15,
            top: screenCenter.dy - 15,
            child: const Text("🪙", style: TextStyle(fontSize: 30))
                .animate()
                // 1. FAZ: MERKEZDE PATLAMA (Explosion)
                .fadeIn(duration: 200.ms, delay: staggerDelay)
                .scale(begin: Offset.zero, end: const Offset(1.2, 1.2), duration: 300.ms, curve: Curves.easeOutBack)
                .move(
                  begin: Offset.zero,
                  end: scatter,
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                )
                
                // 2. FAZ: CÜZDANA UÇUŞ (Fly to Badge)
                .then(delay: 100.ms)
                .move(
                  begin: Offset.zero, // Zaten 'scatter' kadar kaymış durumda
                  end: relativeTarget - scatter,
                  duration: 900.ms,
                  curve: Curves.easeInOutCubic,
                )
                .scale(
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(0.5, 0.4),
                  duration: 900.ms,
                )
                // 3. FAZ: CÜZDANA GİRİŞ VE YOK OLMA
                .fadeOut(delay: 700.ms, duration: 200.ms),
          );
        }),
      ),
    );
  }
}
