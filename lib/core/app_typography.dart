import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
  );

  static TextStyle get pageTitle => GoogleFonts.outfit(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle get cardTitle => GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted,
    letterSpacing: 1.1,
  );
}