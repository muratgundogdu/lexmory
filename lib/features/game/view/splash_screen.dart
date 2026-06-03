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
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Native splash'i kaldır
    FlutterNativeSplash.remove();

    // 3 saniye animasyon süresi (toplam 4 sn bekleme)
    await Future.delayed(const Duration(seconds: 4));

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
          // 1. Fullscreen Arka Plan
          Image.asset(
            "lib/assets/images/splash/splash.png",
            fit: BoxFit.cover,
          ),

          // 2. Koyu Overlay
          Container(
            color: Colors.black.withOpacity(0.55),
          ),

          // 3. İçerik (Taşma korumalı)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView( // KRİTİK: Dikey taşmayı önler
                physics: const NeverScrollableScrollPhysics(), // Kaydırmayı engelle, sadece taşmayı gizle
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60, top: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Sadece içeriği kadar yer kapla
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // L E X M O - Harf Tile'ları
                      // Taşmayı önlemek için Row'u Wrap ile değiştirebiliriz veya Row kalsın diyorsanız:
                      FittedBox( // Küçük ekranlarda Row'un sığmasını sağlar
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildLetterTiles(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Yükleniyor Yazısı
                      Text(
                        "YÜKLENİYOR...",
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 13,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1500.ms, color: Colors.amber.withOpacity(0.5)),
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

  List<Widget> _buildLetterTiles() {
    final List<String> letters = ["L", "E", "X", "M", "O"];

    return letters.asMap().entries.map((entry) {
      int index = entry.key;
      String char = entry.value;

      return Container(
        width: 46,
        height: 58,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          char,
          style: GoogleFonts.baloo2(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat())
          .flipH(
        begin: 0,
        end: 2,
        duration: 900.ms,
        delay: (300 * index).ms,
        curve: Curves.easeInOutBack,
      )
          .scale(
        begin: const Offset(1, 1),
        end: const Offset(1.08, 1.08),
        duration: 450.ms,
        delay: (300 * index).ms,
      )
          .then()
          .scale(
        begin: const Offset(1.08, 1.08),
        end: const Offset(1, 1),
        duration: 450.ms,
      );
    }).toList();
  }
}