import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryCompleteOverlay extends StatelessWidget {
  final bool isVisible;
  final String categoryName;
  final int totalWrong;
  final int totalJokers;
  final int sectionCount;
  final VoidCallback onContinue;

  const CategoryCompleteOverlay({
    super.key,
    required this.isVisible,
    required this.categoryName,
    required this.totalWrong,
    required this.totalJokers,
    required this.sectionCount,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Başlık
              Text(
                "KATEGORİ TAMAMLANDI",
                style: GoogleFonts.baloo2(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade200,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 8),

              // 2. Kategori Adı
              Text(
                categoryName,
                style: GoogleFonts.baloo2(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),

              const SizedBox(height: 40),

              // 3. Büyük Ödül Alanı
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha:0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text("🪙", style: TextStyle(fontSize: 50)),
                    Text(
                      "+150 TOKEN",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade400,
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds)
                  .shimmer(delay: 1.seconds, duration: 2.seconds),

              const SizedBox(height: 50),

              // 4. İstatistikler
              _buildStatRow("$sectionCount Bölüm Tamamlandı", Icons.check_circle_outline, 600),
              _buildStatRow("$totalWrong Yanlış", Icons.error_outline, 800),
              _buildStatRow("$totalJokers Joker Kullanıldı", Icons.auto_fix_high, 1000),

              const SizedBox(height: 60),

              // 5. Devam Butonu
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                  ),
                  child: Text(
                    "Yeni Kategoriye Geç",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String text, IconData icon, int delay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }
}