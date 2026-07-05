import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/theme/olfato_tokens.dart';

// Feature: olfato-rebranding, Property 24: Light mode contrast ratio
// **Validates: Requirements 14.6**
//
// For every text color / background color pair defined in the light theme tokens,
// the computed WCAG contrast ratio is at least 4.5:1.

/// Converts a single sRGB channel value (0–255) to its linear luminance component.
/// Per WCAG 2.1 relative luminance definition:
/// - Divide by 255 to get value in [0, 1]
/// - If <= 0.04045, divide by 12.92
/// - Otherwise, apply ((value + 0.055) / 1.055) ^ 2.4
double _linearize(int channel) {
  final srgb = channel / 255.0;
  if (srgb <= 0.04045) {
    return srgb / 12.92;
  }
  return math.pow((srgb + 0.055) / 1.055, 2.4).toDouble();
}

/// Computes the relative luminance of a color per WCAG 2.1.
/// L = 0.2126 * R + 0.7152 * G + 0.0722 * B
/// where R, G, B are the linearized channel values.
double relativeLuminance(Color color) {
  final r = _linearize(color.red);
  final g = _linearize(color.green);
  final b = _linearize(color.blue);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Computes the WCAG contrast ratio between two colors.
/// Ratio = (L1 + 0.05) / (L2 + 0.05)
/// where L1 is the lighter luminance and L2 is the darker luminance.
double contrastRatio(Color foreground, Color background) {
  final l1 = relativeLuminance(foreground);
  final l2 = relativeLuminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Represents a text/background color pair for testing.
class ColorPair {
  final String description;
  final Color foreground;
  final Color background;

  const ColorPair({
    required this.description,
    required this.foreground,
    required this.background,
  });
}

void main() {
  // All light mode text/background color pairs from OlfatoTokens
  final lightModePairs = <ColorPair>[
    ColorPair(
      description: 'Ink (#1D1924) on Vanilla (#FBF7F2) — primary text on background',
      foreground: OlfatoTokens.ink,
      background: OlfatoTokens.vanilla,
    ),
    ColorPair(
      description: 'Ink (#1D1924) on Mist (#F1ECE7) — primary text on surface',
      foreground: OlfatoTokens.ink,
      background: OlfatoTokens.mist,
    ),
    ColorPair(
      description: 'Gray (#6E6873) on Vanilla (#FBF7F2) — secondary text on background',
      foreground: OlfatoTokens.gray,
      background: OlfatoTokens.vanilla,
    ),
    ColorPair(
      description: 'Gray (#6E6873) on Mist (#F1ECE7) — secondary text on surface',
      foreground: OlfatoTokens.gray,
      background: OlfatoTokens.mist,
    ),
    ColorPair(
      description: 'Plum (#5B2E68) on Vanilla (#FBF7F2) — brand color on background',
      foreground: OlfatoTokens.plum,
      background: OlfatoTokens.vanilla,
    ),
    ColorPair(
      description: 'Pitanga (#F2645A) on Vanilla (#FBF7F2) — action color on background',
      foreground: OlfatoTokens.pitanga,
      background: OlfatoTokens.vanilla,
    ),
  ];

  group('Property 24: Light mode contrast ratio', () {
    for (final pair in lightModePairs) {
      test('${pair.description} meets WCAG AA (≥ 4.5:1)', () {
        final ratio = contrastRatio(pair.foreground, pair.background);

        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '${pair.description}\n'
              'Contrast ratio: ${ratio.toStringAsFixed(2)}:1\n'
              'Required: ≥ 4.5:1 (WCAG AA)',
        );
      });
    }

    test('all light mode pairs collectively satisfy WCAG AA', () {
      // Property-based assertion: for ALL pairs, ratio >= 4.5
      for (final pair in lightModePairs) {
        final ratio = contrastRatio(pair.foreground, pair.background);
        expect(
          ratio >= 4.5,
          isTrue,
          reason:
              'FAILED: ${pair.description} — ratio ${ratio.toStringAsFixed(2)}:1 < 4.5:1',
        );
      }
    });
  });
}
