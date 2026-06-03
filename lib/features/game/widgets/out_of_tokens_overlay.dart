import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/regen_countdown.dart';

class OutOfTokensOverlay extends StatelessWidget {
  final bool isVisible;
  final int currentTokens;
  final DateTime lastRegen;
  final VoidCallback onWatchAd;
  final VoidCallback onStore;
  final bool isDismissible;
  final VoidCallback onClose;

  const OutOfTokensOverlay({
    super.key,
    required this.isVisible,
    required this.currentTokens,
    required this.lastRegen,
    required this.onWatchAd,
    required this.onStore,
    required this.isDismissible,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        // YENİ: withValues kullanımı
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 320,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1B18),
                  borderRadius: BorderRadius.circular(30),
                  // YENİ: withValues kullanımı
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      // YENİ: withValues kullanımı
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🪙", style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 20),
                    Text(
                      "TOKENLARIN TÜKENDİ",
                      style: GoogleFonts.baloo2(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Devam etmek için daha fazla tokena ihtiyacın var.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 40),

                    _buildActionButton(
                      label: "REKLAM İZLE",
                      subLabel: "+50 TOKEN",
                      icon: Icons.play_circle_fill,
                      color: Colors.amber.shade700,
                      onTap: onWatchAd,
                    ),

                    const SizedBox(height: 15),

                    _buildActionButton(
                      label: "MAĞAZAYA GİT",
                      subLabel: "TOKEN SATIN AL",
                      icon: Icons.shopping_bag,
                      color: Colors.white10,
                      onTap: onStore,
                    ),

                    const SizedBox(height: 30),

                    if (currentTokens < 100)
                      RegenCountdown(
                        lastRegenTime: lastRegen,
                        currentTokens: currentTokens,
                        style: GoogleFonts.poppins(
                          // YENİ: withValues kullanımı
                          color: Colors.amber.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),

              if (isDismissible)
                Positioned(
                  top: -10,
                  right: -10,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E342E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                Text(subLabel, style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}