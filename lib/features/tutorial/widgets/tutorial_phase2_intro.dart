import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialPhase2Intro extends StatelessWidget {
  final VoidCallback onStart;

  const TutorialPhase2Intro({
    super.key,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      // Arka planı yumuşakça bulanıklaştırarak odak noktası oluşturur
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: Colors.black.withValues(alpha:0.75),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B18), // Cozy Dark Brown
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.amber.withValues(alpha:0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon Alanı
                _buildIcon(),
                const SizedBox(height: 24),

                // Başlık
                Text(
                  "Sıra Sende!",
                  style: GoogleFonts.baloo2(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[100],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 16),

                // Açıklama Metni
                Text(
                  "Artık nasıl oynanacağını biliyorsun.\n\n"
                      "Kelimeyi dikkatlice incele. Hazır olduğunda 'Buldum' butonuna bas.\n\n"
                      "Daha sonra eksik harfleri hafızandan tamamlayarak kelimeyi çöz.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha:0.85),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),

                // Güven Veren Alt Not
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // İçeriğe göre küçül
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.amber[200]),
                      const SizedBox(width: 8),
                      // HATA ÇÖZÜMÜ: Flexible ekleyerek metnin sığmasını sağlıyoruz
                      Flexible(
                        child: Text(
                          "Bu denemede token kaybetmezsin.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[200],
                          ),
                          // Yazı sığmazsa taşmasını engellemek için
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 32),

                // Aksiyon Butonu
                _buildStartButton(),
              ],
            ),
          ).animate().scale(
            curve: Curves.easeOutBack,
            duration: 600.ms,
            begin: const Offset(0.8, 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha:0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.psychology_outlined,
        size: 48,
        color: Colors.amber[400],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(end: const Offset(1.1, 1.1), duration: 2.seconds);
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          "Denemeye Başla",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat())
        .shimmer(delay: 3.seconds, duration: 1500.ms);
  }
}