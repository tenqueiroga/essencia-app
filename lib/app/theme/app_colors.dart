import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Obsidian backgrounds
  static const Color background = Color(0xFF0C0A0A);
  static const Color surface = Color(0xFF151212);
  static const Color elevated = Color(0xFF1D1818);
  static const Color card = Color(0xFF181414);

  // Accent — Rosé
  static const Color accent = Color(0xFFC4727A);
  static const Color accentSoft = Color(0xFF9E5A62);
  static const Color accentGlow = Color(0x1AC4727A);

  // Secondary — Gold
  static const Color gold = Color(0xFFB8956A);
  static const Color goldSoft = Color(0xFF8A6E4E);

  // Text
  static const Color textPrimary = Color(0xFFF2ECE6);
  static const Color textSecondary = Color(0xFF958A82);
  static const Color textMuted = Color(0xFF4D4544);
  static const Color textHint = Color(0xFF3A3232);

  // Utility
  static const Color success = Color(0xFF6BCB8B);
  static const Color error = Color(0xFFD4565E);
  static const Color warning = Color(0xFFE8B04A);

  // Glass/Border
  static const Color border = Color(0x0FC4727A);
  static const Color borderLight = Color(0x20F2ECE6);

  // Compatibility aliases (old names used in various files)
  static const Color surfaceLight = elevated;
  static const Color glassBorder = border;
  static const Color glassBackground = Color(0x0CF2ECE6);
  static const Color glassHighlight = Color(0x05F2ECE6);
  static const Color roseGold = accent;
  static const Color goldLight = Color(0xFFD4B87A);
  static const Color goldDark = Color(0xFF8A6E4E);
}
