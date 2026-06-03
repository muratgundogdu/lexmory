import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LetterTile extends StatelessWidget {
  final int index;
  final String letter;
  final bool showFace;
  final bool isSelected;
  final bool isWrong;
  final bool isGlobalReveal;
  final bool isEliminated;

  const LetterTile({
    super.key,
    required this.index,
    required this.letter,
    required this.showFace,
    required this.isSelected,
    required this.isWrong,
    required this.isGlobalReveal,
    required this.isEliminated,
  });

  @override
  Widget build(BuildContext context) {
    // Premium Renk Paleti
    const Color cardBackCol = Color(0xFF5D4037);
    const Color correctCol = Color(0xFF2E7D32);
    const Color wrongCol = Color(0xFFC62828);

    // Mevcut duruma göre aktif renk
    final Color activeColor = isSelected
        ? correctCol
        : (isWrong ? wrongCol : cardBackCol);

    return AnimatedScale(
      scale: isEliminated ? 0.4 : 1.0,
      duration: 500.ms,
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: isEliminated ? 0.4 : 1.0,
        duration: 500.ms,
        child: _buildFlipAnimation(activeColor, cardBackCol),
      ),
    );
  }

  /// 3D Kart Çevirme Animasyonu
  /// 3D Kart Çevirme Animasyonu
  Widget _buildFlipAnimation(Color frontColor, Color backColor) {
    // YENİ MANTIK: Eğer kart elenmişse, showFace true olsa bile kart dönmesin (0 kalsın)
    final double animationTarget = (showFace && !isEliminated) ? 1 : 0;

    return Animate(
      target: animationTarget, // showFace ? 1 : 0 yerine animationTarget
      effects: [
        // Yanlış seçimde sallanma ve parlama
        if (isWrong) ...[
          ShakeEffect(hz: 8, duration: 400.ms),
          TintEffect(color: Colors.red.withValues(alpha: 0.3), duration: 200.ms),
        ],
        // Seçildiğinde hafif küçülme
        if (isSelected) ScaleEffect(end: const Offset(0.9, 0.9), duration: 200.ms),
      ],
      child: CustomPaint(
        // Custom efekti ile 3D rotasyon
        child: Container(color: Colors.transparent),
      ).animate(target: animationTarget).custom( // showFace ? 1 : 0 yerine animationTarget
        duration: 500.ms,
        // Gecikme mantığını da koruyoruz
        delay: (isGlobalReveal || animationTarget == 0) ? (index * 40).ms : 0.ms,
        builder: (context, value, child) {
          final double rotation = (1 - value) * pi;
          final bool isBackSide = rotation > pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // Perspektif derinliği
              ..rotateY(rotation),
            alignment: Alignment.center,
            child: isBackSide
                ? _buildCardFace(
              color: backColor,
              content: "?",
              textColor: Colors.white24,
              isBack: true,
            )
                : _buildCardFace(
              color: frontColor,
              content: letter,
              textColor: Colors.amber[100]!,
              isBack: false,
            ),
          );
        },
      ),
    );
  }

  /// Kartın Ön veya Arka Yüzü
  Widget _buildCardFace({
    required Color color,
    required String content,
    required Color textColor,
    required bool isBack,
  }) {
    return Transform(
      // Arka yüzün ters görünmemesi için kendi içinde 180 derece döndürülür
      transform: isBack ? (Matrix4.identity()..rotateY(pi)) : Matrix4.identity(),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          // Premium Gradient ekleyerek derinlik kazandırdık
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
            // Yanlış cevapta kırmızı dış ışıma
            if (isWrong && !isBack)
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.6),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          content,
          style: GoogleFonts.baloo2(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }
}