import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumRewardOverlay extends StatelessWidget {
  final bool isVisible;
  final int baseReward;
  final int memoryBonus;
  final int masterBonus;
  final double multiplier;
  final int totalReward;

  const PremiumRewardOverlay({
    super.key,
    required this.isVisible,
    required this.baseReward,
    required this.memoryBonus,
    required this.masterBonus,
    required this.multiplier,
    required this.totalReward,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return BackdropFilter(
      // Arka planı hafifçe bulandırarak odak noktası oluşturur
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withValues(alpha:0.8),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. BAŞLIK: Mükemmel veya Tebrikler
              _buildTitle(),

              const SizedBox(height: 30),

              // 2. ÖDÜL KARTI: Detaylı puanlama
              _buildRewardCard(),

              const SizedBox(height: 50),

              // 3. ALT BİLGİ: Otomatik geçiş ibaresi
              _buildLoadingText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final bool isPerfect = memoryBonus > 0 && masterBonus > 0;
    return Text(
      isPerfect ? "MÜKEMMEL!" : "TEBRİKLER!",
      style: GoogleFonts.baloo2(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: Colors.amber,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 10),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut);
  }

  Widget _buildRewardCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.07),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          _buildRewardRow("Bölüm Tamamlama", "+$baseReward", 0),
          if (memoryBonus > 0)
            _buildRewardRow("Hafıza Bonusu", "+$memoryBonus", 200),
          if (masterBonus > 0)
            _buildRewardRow("Usta Bonusu", "+$masterBonus", 400),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, thickness: 1),
          ),

          // Çarpan Satırı
          _buildMultiplierRow(),

          const SizedBox(height: 20),

          // Toplam Sonuç
          _buildTotalRow(),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutQuint);
  }

  Widget _buildRewardRow(String label, String value, int delay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildMultiplierRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Seri Çarpanı", style: TextStyle(color: Colors.white70)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha:0.3)),
          ),
          child: Text(
            "x${multiplier.toStringAsFixed(1)}",
            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: Colors.white24)
            .boxShadow(
          begin: const BoxShadow(color: Colors.transparent, blurRadius: 0),
          end: const BoxShadow(color: Colors.orange, blurRadius: 8),
          duration: 1500.ms,
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildTotalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("TOPLAM",
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1)),
        Text(
          "+$totalReward",
          style: GoogleFonts.poppins(
            color: Colors.greenAccent,
            fontWeight: FontWeight.w900,
            fontSize: 32,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms).scale(delay: 800.ms, curve: Curves.easeOutBack);
  }

  Widget _buildLoadingText() {
    return Column(
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
          strokeWidth: 2,
        ),
        const SizedBox(height: 15),
        Text(
          "YENİ BÖLÜM HAZIRLANIYOR",
          style: GoogleFonts.poppins(
            color: Colors.white30,
            fontSize: 12,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2.seconds, color: Colors.white)
        .fadeIn(delay: 1000.ms);
  }
}