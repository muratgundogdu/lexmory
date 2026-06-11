import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LibraryStatsTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const LibraryStatsTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C), // Surface
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E32)), // Border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD4A574), size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: const Color(0xFF8E8E93), // Text Muted
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}