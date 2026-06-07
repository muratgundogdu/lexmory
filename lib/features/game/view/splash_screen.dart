import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../main/view/main_navigation_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Native splash ekranını hemen kaldırıyoruz
    FlutterNativeSplash.remove();

    // Toplam animasyon ve izleme süresi (6 saniye)
    // 1.5sn başlangıç bekleme + (5 harf * 0.5sn) + 2sn son bekleme
    await Future.delayed(const Duration(milliseconds: 6000));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letters = ['L', 'X', 'M', 'R', 'Y'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. ARKA PLAN GÖRSELİ (Tam Ekran)
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/splash/app_splash.png',
              fit: BoxFit.cover,
            ).animate().fadeIn(duration: 800.ms),
          ),

          // Karartma Katmanı
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),

          // 2. 3D SIRALI HARFLER
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(letters.length, (index) {
                    return _SplashLetterTile(
                      letter: letters[index],
                      // GECİKME: 1500ms (ilk bekleme) + her harf için 500ms artış
                      delay: Duration(milliseconds: 1500 + (index * 500)),
                    );
                  }),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLetterTile extends StatefulWidget {
  final String letter;
  final Duration delay;

  const _SplashLetterTile({required this.letter, required this.delay});

  @override
  State<_SplashLetterTile> createState() => _SplashLetterTileState();
}

class _SplashLetterTileState extends State<_SplashLetterTile> {
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    // Kutunun dönmeye başlama anı
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _isFlipped = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOutBack,
      tween: Tween<double>(begin: 0, end: _isFlipped ? pi : 0),
      builder: (context, angle, child) {
        // 90 dereceyi (pi/2) geçince harf, geçmeyince ? görünür
        bool isPastHalf = angle > (pi / 2);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // Premium 3D derinlik
            ..rotateY(angle),
          child: Transform(
            alignment: Alignment.center,
            // Ayna görüntüsünü engellemek için 90 dereceden sonra içeriği geri çevir
            transform: isPastHalf
                ? (Matrix4.identity()..rotateY(pi))
                : Matrix4.identity(),
            child: _buildCardUI(isPastHalf),
          ),
        );
      },
    );
  }

  Widget _buildCardUI(bool isOpened) {
    return Container(
      width: 54,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Kapalıysa koyu gri/yüzey, açıksa hafif altın dolgulu yüzey
        color: isOpened
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(
          color: isOpened ? AppColors.primary : AppColors.border,
          width: isOpened ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isOpened)
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2
            ),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Text(
        isOpened ? widget.letter : "?",
        style: AppTypography.displayLarge.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: isOpened ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}