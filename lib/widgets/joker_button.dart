import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JokerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int cost;
  final VoidCallback onTap;

  const JokerButton({
    super.key,
    required this.icon,
    required this.label,
    required this.cost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Butonun aktif olup olmadığını onTap'in boş olup olmamasından anlıyoruz
    // (game_screen tarafında canUseJoker ? action : () {} şeklinde gönderdiğimiz için)

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.amber.withValues(alpha:0.1),
        highlightColor: Colors.amber.withValues(alpha:0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon Konteynırı (Premium Gradient & Shadow)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4E342E), // Brown 800-900 arası
                      const Color(0xFF2D1B18),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha:0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.amber[200],
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),

              // Etiket
              Text(
                label.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha:0.9),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 2),

              // Maliyet (Token)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🪙", style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 2),
                  Text(
                    "$cost",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}