import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class GameFinishedOverlay extends StatelessWidget {
  final bool isVisible;
  final int totalCategories;
  final int totalWords;
  final int totalTokens;
  final VoidCallback onReset;

  const GameFinishedOverlay({
    super.key,
    required this.isVisible,
    required this.totalCategories,
    required this.totalWords,
    required this.totalTokens,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: Colors.black.withValues(alpha:0.85),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. BAŞLIK VE İKON
                  const Text("🎉", style: TextStyle(fontSize: 70))
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 10),

                  Text(
                    "MÜKEMMEL!",
                    style: GoogleFonts.baloo2(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                    ),
                  ).animate().shimmer(duration: 2.seconds).fadeIn(delay: 200.ms),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "LEXMORY kütüphanesindeki tüm kelimeleri keşfettin.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),

                  // 2. İSTATİSTİK KARTI
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow("$totalCategories Kategori Tamamlandı", Icons.category_outlined),
                        _buildStatRow("$totalWords Kelime Çözüldü", Icons.check_circle_outline),
                        _buildStatRow("$totalTokens Toplam Bakiye", Icons.monetization_on_outlined),
                      ],
                    ),
                  ).animate().scale(delay: 600.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 50),

                  // 3. COMING SOON MESAJI
                  Column(
                    children: [
                      Text(
                        "Yeni kategoriler çok yakında gelecek.",
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Günlük meydan okumalar yakında!",
                        style: GoogleFonts.poppins(
                            color: Colors.amber.withValues(alpha:0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1000.ms),

                  const SizedBox(height: 40),

                  // 4. BUTON
                  SizedBox(
                    width: 240,
                    child: ElevatedButton(
                      onPressed: onReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: const Text("BAŞA DÖN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber.withValues(alpha:0.5), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
                text,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)
            ),
          ),
        ],
      ),
    );
  }
}