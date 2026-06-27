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
    // Stage-PNG sisteminde progress 1.0 ise oda bitmiştir
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
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? const Color(0xFFD4A574).withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. GÖRSEL ALANI (Thumbnail - 16:9)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        imagePath,
                        // ANALİZ: Thumbnail olduğu için cover en iyi sonucu verir
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF141414),
                          child: const Icon(Icons.broken_image, color: Colors.white10, size: 40),
                        ),
                      ),
                    ),

                    // Kilit Overlay
                    if (isLocked)
                      Container(
                        color: Colors.black.withValues(alpha: 0.65),
                        child: const Center(
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFFD4A574),
                            size: 44,
                          ),
                        ),
                      ),

                    // Tamamlandı Rozeti (Premium Badge)
                    if (isCompleted && !isLocked)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4A574), Color(0xFFF2C078)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 4)
                            ],
                          ),
                          child: Text(
                            "✓ TAMAMLANDI",
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. BİLGİ VE PROGRESS ALANI
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isLocked ? Colors.white38 : Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        if (!isLocked)
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLocked ? (lockRequirement ?? "Kilitli Bölüm") : description,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isLocked ? const Color(0xFFD4A574).withValues(alpha: 0.6) : const Color(0xFF8E8E93),
                        fontWeight: isLocked ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),

                    if (!isLocked) ...[
                      const SizedBox(height: 20),
                      // Premium Progress Bar
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
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
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isCompleted ? "Tüm eşyalar yerleştirildi" : "Gelişim devam ediyor",
                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white24),
                          ),
                          Text(
                            "%${(progress * 100).toInt()}",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFFF2C078),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
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