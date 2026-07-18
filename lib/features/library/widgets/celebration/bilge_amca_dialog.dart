import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class BilgeAmcaDialog extends StatelessWidget {
  final String message;
  final bool showBilgeAmca;

  const BilgeAmcaDialog({
    super.key,
    required this.message,
    this.showBilgeAmca = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bilge Amca Image
          if (showBilgeAmca)
            Image.asset(
              'lib/assets/cards/bilge_amca/bilge_amca.webp',
              height: 180,
            ).animate().fadeIn().slideY(begin: 0.1),
          
          const SizedBox(height: 24),

          // Dialog Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4A574), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                Text(
                  "BİLGE AMCA",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFF2C078),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms).fadeIn(),
        ],
      ),
    );
  }
}
