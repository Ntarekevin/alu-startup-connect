import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary & Accents (Modychat)
  static const Color primary = Color(0xFFFF4B63); // Coral Red
  static const Color primaryDark = Color(0xFFE53E55);
  static const Color secondary = Color(0xFF6C5CE7); // Indigo
  static const Color gold = Color(0xFFFFB627);

  // Dark Theme
  static const Color darkBackground = Color(0xFF16161D);
  static const Color darkHeader = Color(0xFF1D2335); // Swoop header color
  static const Color darkSurface = Color(0xFF1E1E27);
  static const Color darkBorder = Color(0xFF2A2A35);
  static const Color darkTextPrimary = Color(0xFFF2F2F5);
  static const Color darkTextSecondary = Color(0xFFB0B0C0);

  // Light Theme
  static const Color lightBackground = Color(0xFFF9F9FB);
  static const Color lightHeader = Color(0xFF1D2335); // Keep header dark in light mode too for contrast
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFEAEAF0);
  static const Color lightTextPrimary = Color(0xFF1A1A1E);
  static const Color lightTextSecondary = Color(0xFF6B6B7B);

  // Status Colors
  static const Color success = Color(0xFF22D3A5);
  static const Color error = Color(0xFFFF4B63);
  static const Color warning = Color(0xFFFFB627);
  static const Color info = Color(0xFF5B8DEF);

  // Application status colors
  static const Color statusApplied = Color(0xFF5B8DEF);
  static const Color statusReviewing = Color(0xFFFFB627);
  static const Color statusInterview = Color(0xFF6C5CE7);
  static const Color statusAccepted = Color(0xFF22D3A5);
  static const Color statusRejected = Color(0xFFFF4B63);

  // ── Legacy aliases (keep files that reference these compiling) ─────────────
  /// Alias for [secondary] (indigo). Legacy files used `AppColors.teal`.
  static const Color teal = secondary;
  /// Alias for [darkBackground]. Legacy files used `AppColors.background`.
  static const Color background = darkBackground;
  /// Alias for [darkSurface]. Legacy files used `AppColors.surface`.
  static const Color surface = darkSurface;
  /// A slightly lighter surface tone for secondary containers.
  static const Color surfaceLight = Color(0xFF252530);
  /// Alias for [darkBorder]. Legacy files used `AppColors.cardBorder`.
  static const Color cardBorder = darkBorder;
  /// Alias for [darkTextPrimary]. Legacy files used `AppColors.textPrimary`.
  static const Color textPrimary = darkTextPrimary;
  /// Alias for [darkTextSecondary]. Legacy files used `AppColors.textSecondary`.
  static const Color textSecondary = darkTextSecondary;
  /// Muted text — slightly dimmer than [textSecondary].
  static const Color textMuted = Color(0xFF7A7A8C);
}

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      border: AppColors.lightBorder,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      border: AppColors.darkBorder,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final textTheme = GoogleFonts.outfitTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary),
      headlineMedium: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
      titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary),
      bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary.withOpacity(0.8)),
      labelLarge: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: brightness == Brightness.light ? 4 : 0,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: brightness == Brightness.dark ? border : Colors.transparent, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(color: textSecondary.withOpacity(0.6)),
        labelStyle: GoogleFonts.outfit(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    );
  }
}
