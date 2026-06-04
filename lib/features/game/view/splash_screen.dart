import 'dart:async';
import 'dart:math' as math; // math kütüphanesini ekledik
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<bool> _isRevealed = [false, false, false, false, false];
  final List<String> _letters = ["L", "X", "M", "R", "Y"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(500.ms);

    for (int i = 0; i < _letters.length; i++) {
      if (!mounted) return;
      await Future.delayed(400.ms);
      setState(() {
        _isRevealed[i] = true;
      });
    }

    await Future.delayed(1500.ms);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "lib/assets/images/splash/splash.png",
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withValues(alpha:0.6),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80, top: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_letters.length, (index) {
                            return _buildAnimatedTile(index);
                          }),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "YÜKLENİYOR...",
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 12,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 2.seconds, color: Colors.amber.withValues(alpha:0.4)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTile(int index) {
    bool revealed = _isRevealed[index];
    String char = _letters[index];

    return Container(
      width: 50,
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: revealed ? const Color(0xFF38473A) : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: revealed ? Colors.greenAccent.withValues(alpha:0.6) : Colors.white24,
          width: 2,
        ),
        boxShadow: revealed
            ? [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha:0.2),
            blurRadius: 12,
            spreadRadius: 1,
          )
        ]
            : [],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: 300.ms,
        // Harfin ters dönmemesi için switcher içinde sadece Fade kullanıyoruz
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          revealed ? char : "?",
          key: ValueKey<bool>(revealed),
          style: GoogleFonts.baloo2(
            color: revealed ? Colors.white : Colors.white38,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    )
        .animate(target: revealed ? 1 : 0)
        .custom(
      duration: 600.ms,
      builder: (context, value, child) {
        // Kartın dönüş açısı (0 - 180 derece)
        final double angle = value * math.pi;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          // KRİTİK DÜZELTME:
          // Kart 90 dereceyi geçtiğinde (arka yüzü bize dönerken)
          // içeriği tekrar 180 derece döndürüyoruz ki harf DÜZ görünsün.
          child: angle > (math.pi / 2)
              ? Transform(
            transform: Matrix4.identity()..rotateY(math.pi),
            alignment: Alignment.center,
            child: child,
          )
              : child,
        );
      },
    )
        .shimmer(delay: 200.ms, duration: 400.ms);
  }
}

// RotationYTransition sınıfı kullanılmıyor ancak kod yapısını bozmamak adına bırakılmıştır.
class RotationYTransition extends AnimatedWidget {
  const RotationYTransition({
    super.key,
    required Animation<double> turns,
    this.child,
  }) : super(listenable: turns);

  Animation<double> get turns => listenable as Animation<double>;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double angle = turns.value * math.pi;
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      alignment: Alignment.center,
      child: child,
    );
  }
}