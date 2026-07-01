import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
      ),
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textPrimary, height: 1.2),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.textPrimary),
        headlineSmall: baseText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.textPrimary),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.textPrimary),
        bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.textSecondary),
        bodySmall: baseText.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1)),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.5),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
