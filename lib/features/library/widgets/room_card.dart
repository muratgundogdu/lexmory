import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomCard extends StatelessWidget {
  final String name;
  final String description;
  final double progress; // 0.0 to 1.0
  final String imagePath;
  final bool isLocked;
  final String? lockRequirement;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.name,
    required this.description,
    required this.progress,
    required this.imagePath,
    this.isLocked = false,
    this.lockRequirement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = progress >= 1.0;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted 
                ? const Color(0xFFD4A574).withValues(alpha: 0.5) 
                : const Color(0xFF2E2E32),
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: isCompleted ? [
            BoxShadow(
              color: const Color(0xFFD4A574).withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Image Area (16:9) - Artık Kırpılmıyor
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: const Color(0xFF141414),
                  child: Stack(
                    children: [
                      // Arka Plan Görseli (Contain ile tam görünür)
                      Positioned.fill(
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.fitWidth,
                          filterQuality: FilterQuality.medium,
                          isAntiAlias: true,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.white10,
                            child: const Icon(Icons.broken_image, color: Colors.white24, size: 48),
                          ),
                        ),
                      ),

                      // Kilitli Karartma (Blur kaldırıldı)
                      if (isLocked)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Center(
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFFD4A574),
                              size: 40,
                            ),
                          ),
                        ),

                      // Tamamlandı Rozeti
                      if (isCompleted && !isLocked)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A574),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: Text(
                              "✓ TAMAMLANDI",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bilgi Alanı
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isLocked && lockRequirement != null)
                                Text(
                                  lockRequirement!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFFD4A574),
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else
                                Text(
                                  description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF8E8E93),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isLocked)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white24,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    
                    if (!isLocked) ...[
                      const SizedBox(height: 16),
                      // İlerleme Barı (Premium Gradient)
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFD4A574), Color(0xFFF2C078)],
                                ),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4A574).withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCompleted 
                            ? "Tüm geliştirmeler tamamlandı" 
                            : "%${(progress * 100).toInt()} Geliştirildi",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
