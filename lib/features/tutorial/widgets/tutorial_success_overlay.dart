import 'dart:ui';
import 'package:flutter/material.dart';import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';

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
        color: AppColors.background.withValues(alpha: 0.85),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kutlama İkonu
                  const Text("🎉", style: TextStyle(fontSize: 64))
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 24),

                  // Başlık
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),

                  const SizedBox(height: 16),

                  // Mesaj
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),

                  // Aksiyon Butonu (Oyunun Genel Buton Stili)
                  _buildActionButton(),
                ],
              ),
            ).animate().scale(
              curve: Curves.easeOutBack,
              duration: 600.ms,
              begin: const Offset(0.9, 0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: onStartGame,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Center(
          child: Text(
            buttonText.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.black,
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat())
        .shimmer(delay: 4.seconds, duration: 1800.ms, color: Colors.white24);
  }
}