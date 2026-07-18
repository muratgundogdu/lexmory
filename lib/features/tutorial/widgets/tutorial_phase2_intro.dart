import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';
import '../../../core/debug_config.dart';

class TutorialPhase2Intro extends StatelessWidget {
  final VoidCallback onStart;

  const TutorialPhase2Intro({
    super.key,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final Widget overlayContent = Container(
      color: AppColors.background.withValues(alpha: DebugConfig.enableBackdropBlurs ? 0.85 : 0.95),
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
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon Alanı
                _buildIcon(),
                const SizedBox(height: 32),

                // Başlık
                Text(
                  "Sıra Sende!",
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),

                const SizedBox(height: 16),

                // Açıklama Metni
                Text(
                  "Artık nasıl oynanacağını biliyorsun.\n\n"
                      "Kelimeyi incele, hazır olduğunda 'Buldum' butonuna bas ve harfleri hafızandan tamamla.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 32),

                // Bilgi Kutusu (Taşma düzeltildi)
                _buildInfoBox(),

                const SizedBox(height: 40),

                // Aksiyon Butonu
                _buildStartButton(),
              ],
            ),
          ).animate().scale(
            curve: Curves.easeOutBack,
            duration: 600.ms,
            begin: const Offset(0.9, 0.9),
          ),
        ),
      ),
    );

    if (DebugConfig.enableBackdropBlurs) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: overlayContent,
      );
    }
    return overlayContent;
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.psychology_outlined,
        size: 56,
        color: AppColors.primary,
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(end: const Offset(1.08, 1.1), duration: 2.seconds);
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              "Bu deneme sana token harcatmaz.",
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildStartButton() {
    final Widget buttonContent = Container(
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
          "Denemeye Başla".toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Colors.black,
          ),
        ),
      ),
    );

    if (DebugConfig.enableShimmers) {
      return GestureDetector(
        onTap: onStart,
        child: buttonContent.animate(onPlay: (c) => c.repeat())
            .shimmer(delay: 4.seconds, duration: 1800.ms, color: Colors.white24),
      );
    }

    return GestureDetector(
      onTap: onStart,
      child: buttonContent.animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(end: const Offset(1.03, 1.03), duration: 1.seconds),
    );
  }
}
