import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardRibbon extends StatelessWidget {
  final bool isNew;
  final int duplicateTokenValue;

  const RewardRibbon({
    super.key,
    required this.isNew,
    required this.duplicateTokenValue,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: ClipRect(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: -30,
                child: Transform.rotate(
                  angle: -0.785398, // -45 degrees
                  child: Container(
                    width: 140,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: isNew
                          ? const LinearGradient(
                              colors: [Color(0xFFD4A574), Color(0xFFF2C078)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.9),
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: isNew
                          ? null
                          : Border.symmetric(
                              horizontal: BorderSide(
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: isNew
                            ? Text(
                                "YENİ",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("🪙", style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 4),
                                  Text(
                                    "+$duplicateTokenValue",
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFFD54F),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              // Optional glossy effect
              if (isNew)
                Positioned(
                  top: 16,
                  left: -30,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: -0.785398,
                      child: Container(
                        width: 140,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.2),
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.1),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().slide(
          begin: const Offset(-0.2, -0.2),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        ).fadeIn(duration: 400.ms);
  }
}
