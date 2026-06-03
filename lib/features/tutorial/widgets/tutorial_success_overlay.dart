// lib/features/tutorial/widgets/tutorial_success_overlay.dartimport 'dart:ui';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialSuccessOverlay extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onStartGame;

  const TutorialSuccessOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onStartGame,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withValues(alpha:0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B18),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.amber.withValues(alpha:0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🎉", style: TextStyle(fontSize: 64))
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                Text(
                  title, // Değişken kullanıldı
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    fontSize: 32, // Biraz küçültüldü uzun başlıklar için
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ).animate().fadeIn(delay: 200.ms).shimmer(duration: 2.seconds),

                const SizedBox(height: 12),

                Text(
                  message, // Değişken kullanıldı
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStartGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      buttonText, // Değişken kullanıldı
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat())
                    .shimmer(delay: 3.seconds, duration: 1500.ms)
                    .animate().fadeIn(delay: 600.ms),
              ],
            ),
          ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
        ),
      ),
    );
  }
}