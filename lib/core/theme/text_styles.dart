import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Tipografi aplikasi yang mengutamakan kenyamanan membaca disleksia dewasa:
/// Menggunakan font Lexend dengan jarak antar huruf (letter spacing) dan baris (line height)
/// yang lebih lega untuk meminimalkan efek "huruf berkerumun" (visual crowding).
class AppTextStyles {
  // Headings
  static TextStyle headlineLarge = GoogleFonts.lexend(
    fontSize: 26.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
    height: 1.35,
  );

  static TextStyle headlineMedium = GoogleFonts.lexend(
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
    height: 1.4,
  );

  static TextStyle headlineSmall = GoogleFonts.lexend(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
    height: 1.4,
  );

  // Subtitles / Titles
  static TextStyle titleMedium = GoogleFonts.lexend(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
    height: 1.45,
  );

  static TextStyle titleSmall = GoogleFonts.lexend(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
    height: 1.45,
  );

  // Body Texts (Jarak baris ditingkatkan ke 1.6 - 1.75 untuk mencegah baris melompat)
  static TextStyle bodyLarge = GoogleFonts.lexend(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
    height: 1.65,
  );

  static TextStyle bodyMedium = GoogleFonts.lexend(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.35,
    height: 1.6,
  );

  static TextStyle bodySmall = GoogleFonts.lexend(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
    height: 1.5,
  );

  // Button Labels (Tegas dan tebal untuk memudahkan navigasi cepat)
  static TextStyle button = GoogleFonts.lexend(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Tag / Badge
  static TextStyle badge = GoogleFonts.lexend(
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    height: 1.2,
  );
}

