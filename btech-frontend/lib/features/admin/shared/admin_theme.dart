import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Core Colors extracted from screenshots
  static const Color background = Color(0xFF021024); // Deep Navy
  static const Color surface =
      Color(0xFF112240); // Slightly lighter for sidebar
  static const Color primaryAccent = Color(0xFF64FFDA); // Teal/Cyan accent
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.white70;

  // Status Colors
  static const Color successGreen = Color(0xFF28C76F);
  static const Color warningOrange = Color(0xFFFF9F43);
  static const Color dangerRed = Color(0xFFEA5455);

  // Typography (Outfit as requested)
  static TextStyle get header => GoogleFonts.outfit(
      fontSize: 24, fontWeight: FontWeight.bold, color: textWhite);

  static TextStyle get subHeader => GoogleFonts.outfit(
      fontSize: 18, fontWeight: FontWeight.w600, color: textWhite);

  static TextStyle get body => GoogleFonts.outfit(
      fontSize: 14, fontWeight: FontWeight.normal, color: textGrey);

  // Glassmorphism Decoration (The "BTech Look")
  // Glassmorphism Decoration (The "BTech Look")
  static BoxDecoration glassDecoration = BoxDecoration(
      color: const Color(0xFF1E1E2C)
          .withValues(alpha: 0.6), // Darker, richer background
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: Colors.white.withValues(alpha: 0.08)), // Subtle border
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 4),
        )
      ]);

  // For active cards or headers
  static BoxDecoration glassGradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.1),
        Colors.white.withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
  );
}
