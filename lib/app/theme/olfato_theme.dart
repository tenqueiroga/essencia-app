import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'olfato_tokens.dart';

/// Theme configuration for the Olfato brand.
///
/// Provides [lightTheme] (default), [darkTheme], and [scannerTheme] getters.
/// Uses EB Garamond for display/headline styles and Inter for UI/body styles.
/// All values are derived from [OlfatoTokens].
class OlfatoTheme {
  OlfatoTheme._();

  // ─── Light Theme ────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final displayText = GoogleFonts.ebGaramondTextTheme(ThemeData.light().textTheme);
    final uiText = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    final textTheme = uiText.copyWith(
      headlineLarge: displayText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: OlfatoTokens.textPrimaryLight,
        height: 1.2,
      ),
      headlineMedium: displayText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: OlfatoTokens.textPrimaryLight,
      ),
      headlineSmall: displayText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: OlfatoTokens.textPrimaryLight,
      ),
      titleLarge: displayText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: OlfatoTokens.textPrimaryLight,
      ),
      titleMedium: uiText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: OlfatoTokens.textPrimaryLight,
      ),
      bodyLarge: uiText.bodyLarge?.copyWith(color: OlfatoTokens.textPrimaryLight),
      bodyMedium: uiText.bodyMedium?.copyWith(color: OlfatoTokens.textSecondaryLight),
      bodySmall: uiText.bodySmall?.copyWith(color: OlfatoTokens.gray),
      labelLarge: uiText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: OlfatoTokens.textPrimaryLight,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: OlfatoTokens.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: OlfatoTokens.plum,
        secondary: OlfatoTokens.pitanga,
        surface: OlfatoTokens.surfaceLight,
        error: OlfatoTokens.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: OlfatoTokens.textPrimaryLight,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: OlfatoTokens.textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: OlfatoTokens.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: OlfatoTokens.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          side: const BorderSide(color: OlfatoTokens.borderLight, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: OlfatoTokens.backgroundLight,
        selectedItemColor: OlfatoTokens.plum,
        unselectedItemColor: OlfatoTokens.gray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OlfatoTokens.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          borderSide: const BorderSide(color: OlfatoTokens.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          borderSide: const BorderSide(color: OlfatoTokens.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          borderSide: const BorderSide(color: OlfatoTokens.plum, width: 1),
        ),
        hintStyle: const TextStyle(color: OlfatoTokens.gray, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OlfatoTokens.pitanga,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OlfatoTokens.textPrimaryLight,
          side: const BorderSide(color: OlfatoTokens.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: OlfatoTokens.surfaceLight,
        side: const BorderSide(color: OlfatoTokens.borderLight),
        labelStyle: const TextStyle(fontSize: 11, color: OlfatoTokens.textSecondaryLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: OlfatoTokens.borderLight,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OlfatoTokens.ink,
        contentTextStyle: const TextStyle(color: OlfatoTokens.vanilla),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Dark Theme ─────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    final displayText = GoogleFonts.ebGaramondTextTheme(ThemeData.dark().textTheme);
    final uiText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    final textTheme = uiText.copyWith(
      headlineLarge: displayText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: OlfatoTokens.textPrimaryDark,
        height: 1.2,
      ),
      headlineMedium: displayText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: OlfatoTokens.textPrimaryDark,
      ),
      headlineSmall: displayText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: OlfatoTokens.textPrimaryDark,
      ),
      titleLarge: displayText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: OlfatoTokens.textPrimaryDark,
      ),
      titleMedium: uiText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: OlfatoTokens.textPrimaryDark,
      ),
      bodyLarge: uiText.bodyLarge?.copyWith(color: OlfatoTokens.textPrimaryDark),
      bodyMedium: uiText.bodyMedium?.copyWith(color: OlfatoTokens.textSecondaryDark),
      bodySmall: uiText.bodySmall?.copyWith(color: OlfatoTokens.textSecondaryDark),
      labelLarge: uiText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: OlfatoTokens.textPrimaryDark,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OlfatoTokens.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: OlfatoTokens.pitanga,
        secondary: OlfatoTokens.plum,
        surface: OlfatoTokens.surfaceDark,
        error: OlfatoTokens.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: OlfatoTokens.textPrimaryDark,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: OlfatoTokens.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: OlfatoTokens.textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: OlfatoTokens.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          side: const BorderSide(color: OlfatoTokens.borderDark, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: OlfatoTokens.backgroundDark,
        selectedItemColor: OlfatoTokens.pitanga,
        unselectedItemColor: OlfatoTokens.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OlfatoTokens.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          borderSide: const BorderSide(color: OlfatoTokens.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          borderSide: const BorderSide(color: OlfatoTokens.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          borderSide: const BorderSide(color: OlfatoTokens.pitanga, width: 1),
        ),
        hintStyle: const TextStyle(color: OlfatoTokens.textSecondaryDark, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OlfatoTokens.pitanga,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OlfatoTokens.textPrimaryDark,
          side: const BorderSide(color: OlfatoTokens.borderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: OlfatoTokens.surfaceDark,
        side: const BorderSide(color: OlfatoTokens.borderDark),
        labelStyle: const TextStyle(fontSize: 11, color: OlfatoTokens.textSecondaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: OlfatoTokens.borderDark,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OlfatoTokens.surfaceDark,
        contentTextStyle: const TextStyle(color: OlfatoTokens.textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Scanner Theme (always dark) ───────────────────────────────────────────

  /// A dark theme used exclusively for the scanner screen,
  /// regardless of the user's light/dark preference.
  static ThemeData get scannerTheme {
    final base = darkTheme;
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: base.colorScheme.copyWith(
        surface: Colors.black,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
