import 'package:flutter/material.dart';

/// Centralized design tokens for the Olfato brand identity.
///
/// Defines all brand colors, semantic aliases (light/dark), radii, spacing,
/// shadows, and gradients from `olfato_tokens.json`.
/// This class replaces [AppColors] and serves as the single source of truth
/// for all visual styling across the app.
class OlfatoTokens {
  OlfatoTokens._();

  // ─── Brand Colors ─────────────────────────────────────────────────────────

  /// Primary brand — plum purple
  static const Color plum = Color(0xFF5B2E68);

  /// Action / CTA — pitanga red-coral
  static const Color pitanga = Color(0xFFF2645A);

  /// Premium / rating — amber gold
  static const Color amber = Color(0xFFD99A32);

  /// Freshness / trust — green
  static const Color green = Color(0xFF2F796B);

  /// Background (light mode) — vanilla cream
  static const Color vanilla = Color(0xFFFBF7F2);

  /// Surface (light mode) — mist warm gray
  static const Color mist = Color(0xFFF1ECE7);

  /// Text secondary — gray
  static const Color gray = Color(0xFF6E6873);

  /// Text primary (light mode) — ink dark purple-black
  static const Color ink = Color(0xFF1D1924);

  // ─── Semantic Aliases: Light Mode ─────────────────────────────────────────

  static const Color backgroundLight = vanilla;
  static const Color surfaceLight = mist;
  static const Color textPrimaryLight = ink;
  static const Color textSecondaryLight = gray;

  // ─── Semantic Aliases: Dark Mode ──────────────────────────────────────────

  static const Color backgroundDark = ink;
  static const Color surfaceDark = Color(0xFF2A2530);
  static const Color textPrimaryDark = vanilla;
  static const Color textSecondaryDark = Color(0xFFB8B2BC);

  // ─── Utility Colors ───────────────────────────────────────────────────────

  static const Color success = Color(0xFF2F796B); // same as green
  static const Color error = Color(0xFFD4565E);
  static const Color warning = Color(0xFFD99A32); // same as amber

  // ─── Border Colors ────────────────────────────────────────────────────────

  static const Color borderLight = Color(0xFFE2DCD6);
  static const Color borderDark = Color(0xFF3D3845);

  // ─── Radii ────────────────────────────────────────────────────────────────

  /// Controls (buttons, inputs, chips)
  static const double radiusControl = 12;

  /// Cards and containers
  static const double radiusCard = 16;

  /// Feature elements and modals
  static const double radiusFeature = 24;

  // ─── Spacing ──────────────────────────────────────────────────────────────

  /// Base spacing unit — all layout gaps are multiples of this value
  static const double spaceUnit = 8;

  // ─── Shadow ───────────────────────────────────────────────────────────────

  /// Card elevation shadow: 0 8px 28px rgb(29 25 36 / 10%)
  static BoxShadow get cardShadow => BoxShadow(
        offset: const Offset(0, 8),
        blurRadius: 28,
        color: ink.withValues(alpha: 0.10),
      );

  // ─── Gradient ─────────────────────────────────────────────────────────────

  /// Aura brand gradient (plum → pitanga → amber, 135°)
  static const LinearGradient auraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [plum, pitanga, amber],
    stops: [0.0, 0.55, 1.0],
  );
}
