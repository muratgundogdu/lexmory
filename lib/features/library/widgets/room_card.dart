import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/debug_config.dart';

class RoomCard extends StatelessWidget {
  final String name;
  final String description;
  final double progress; // 0.0 to 1.0
  final String imagePath;
  final bool isLocked;
  final String? lockRequirement;
  final bool highlightGlow;
  final bool isNewlyUnlocked;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.name,
    required this.description,
    required this.progress,
    required this.imagePath,
    this.isLocked = false,
    this.lockRequirement,
    this.highlightGlow = false,
    this.isNewlyUnlocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = progress >= 1.0;
    final bool useHighlight = highlightGlow && DebugConfig.enableRoomCardHighlight;

    // BUSINESS RULE: A completed room should never be the "active" highlight target.
    // highlightGlow (derived from isActive || isNewlyUnlocked) should be false for completed rooms.
    assert(!(isCompleted && highlightGlow), 'Completed room cannot be the active focus target.');

    // VISUAL STATE HIERARCHY
    Color borderColor;
    double borderWidth;
    double blurRadius = 15;
    Color shadowColor = Colors.black.withValues(alpha: 0.3);

    if (isLocked) {
      borderColor = const Color(0xFF2E2E32);
      borderWidth = 1;
    } else if (useHighlight) {
      // ACTIVE or NEWLY UNLOCKED: Bright Gold + Glow
      borderColor = const Color(0xFFF2C078);
      borderWidth = 3;
      shadowColor = const Color(0xFFF2C078).withValues(alpha: 0.3);
      blurRadius = 20;
    } else if (isCompleted) {
      // COMPLETED: Neutral / Muted
      borderColor = Colors.white.withValues(alpha: 0.15); // Calm neutral border
      borderWidth = 1.5;
    } else {
      // UNLOCKED but not active yet: Standard
      borderColor = const Color(0xFF2E2E32);
      borderWidth = 1;
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: blurRadius,
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

                  // YENİ ODA Rozeti (Transient label)
                  if (isNewlyUnlocked && useHighlight)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2C078),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 8)
                            ],
                          ),
                          child: Text(
                            "YENİ ODA",
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
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
                    // Progress Bar
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
    );

    if (useHighlight) {
      // Subtle continuous pulse for the active room
      content = content.animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.015, 1.015),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
    }

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: content,
    );
  }
}
