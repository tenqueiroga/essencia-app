import 'package:flutter_test/flutter_test.dart' hide test, expect;
import 'package:glados/glados.dart';
import 'package:frontend/features/decant_advisor/presentation/decant_helpers.dart';

// Feature: olfato-rebranding, Property 15: Decant advisor presents exactly 3 volumes with one recommendation
// Feature: olfato-rebranding, Property 16: Decant advisor shows no prices
// **Validates: Requirements 11.2, 11.3, 11.4, 11.5**

// ─── Generators ─────────────────────────────────────────────────────────────

/// Generator for justification text (arbitrary strings up to 200 chars to test truncation).
final Generator<String> _justificationGenerator = any.choose([
  '',
  'Ideal para testar uma nova fragrância sem comprometer.',
  'Perfeito para quem quer variedade na coleção sem gastar muito.',
  'A quantidade ideal para um mês inteiro de uso diário.',
  'Para eventos especiais e viagens curtas.',
  'Para conhecer a evolução completa da fragrância ao longo do dia.',
  'Suficiente para 15 dias de uso moderado em clima quente.',
  'a' * 140, // exactly at limit
  'b' * 200, // exceeds limit, should be truncated
  'c' * 141, // just over limit
  'Texto com acentos: é à ç ã ô ü — perfeito para testar encoding.',
]);

/// Generator for a recommended volume (must be one of 2, 5, 10).
final Generator<int> _recommendedVolumeGenerator = any.choose([2, 5, 10]);

/// Builds a well-formed decant advisor JSON from justifications and recommended volume.
Map<String, dynamic> _buildDecantJson(
  String j1,
  String j2,
  String j3,
  int recommended,
) {
  return {
    'recommended_volume': recommended,
    'volumes': [
      {'ml': 2, 'justification': j1},
      {'ml': 5, 'justification': j2},
      {'ml': 10, 'justification': j3},
    ],
  };
}

/// Generator that produces valid decant advisor API response JSON.
final Generator<Map<String, dynamic>> _decantAdvisorJsonGenerator =
    any.combine4(
  _justificationGenerator,
  _justificationGenerator,
  _justificationGenerator,
  _recommendedVolumeGenerator,
  _buildDecantJson,
);

/// Generator for justification texts that may contain price information.
/// This tests that fromJson truncation + containsPriceInformation works.
final Generator<String> _noPriceJustificationGenerator = any.choose([
  'Ideal para testar uma nova fragrância.',
  'Perfeito para quem quer variedade na coleção.',
  'A quantidade ideal para um mês inteiro de uso.',
  'Para eventos especiais e viagens curtas.',
  'Suficiente para experimentar em diferentes ocasiões.',
  'Bom volume para quem já conhece e quer reabastecer.',
  'Adequado para conhecer a pirâmide olfativa completa.',
  '',
  'Teste de texto sem valores monetários.',
  'Ótimo para colecionadores iniciantes.',
]);

/// Generator that produces decant advisor JSON guaranteed to have no prices.
final Generator<Map<String, dynamic>> _noPriceDecantJsonGenerator =
    any.combine4(
  _noPriceJustificationGenerator,
  _noPriceJustificationGenerator,
  _noPriceJustificationGenerator,
  _recommendedVolumeGenerator,
  _buildDecantJson,
);

void main() {
  // ─── Property 15: Decant advisor presents exactly 3 volumes with one recommendation
  //
  // For any decant advisor result, exactly 3 volume options (2ml, 5ml, 10ml)
  // are presented, each justification is at most 140 characters, exactly one
  // option carries the "RECOMENDADO" badge, and the CTA text references the
  // same volume as the badged option.

  Glados(_decantAdvisorJsonGenerator).test(
    'Property 15: Decant advisor presents exactly 3 volumes with one '
    'recommendation — volumes are [2, 5, 10], justifications ≤140 chars, '
    'exactly one matches recommended, and CTA references correct volume',
    (json) {
      final result = DecantAdvisorResult.fromJson(json);

      // Exactly 3 volume options
      expect(result.volumes.length, equals(3),
          reason: 'Must present exactly 3 volume options');

      // Volumes are exactly 2ml, 5ml, 10ml
      expect(validateDecantVolumes(result), isTrue,
          reason: 'Volumes must be exactly {2, 5, 10}');

      // Each justification ≤ 140 characters (fromJson truncates)
      expect(validateJustificationLengths(result), isTrue,
          reason: 'All justifications must be ≤ 140 characters');

      for (final volume in result.volumes) {
        expect(volume.justification.length, lessThanOrEqualTo(140),
            reason:
                'Justification for ${volume.ml}ml must be ≤ 140 chars, '
                'got ${volume.justification.length}');
      }

      // Exactly one option carries the "RECOMENDADO" badge
      expect(validateSingleRecommendation(result), isTrue,
          reason:
              'Exactly one volume must match the recommended volume');

      // CTA text references the same volume as the badged option
      final ctaText = buildDecantCtaText(result.recommendedVolume);
      expect(
        validateCtaMatchesRecommendation(ctaText, result.recommendedVolume),
        isTrue,
        reason: 'CTA text must reference the recommended volume',
      );
      expect(ctaText, contains('${result.recommendedVolume}ml'),
          reason: 'CTA must contain the recommended volume in ml');
    },
  );

  // ─── Property 16: Decant advisor shows no prices ─────────────────────────────
  //
  // For any decant advisor result, no price or monetary value is displayed
  // for any volume option.

  Glados(_noPriceDecantJsonGenerator).test(
    'Property 16: Decant advisor shows no prices — '
    'no volume option contains price or monetary information',
    (json) {
      final result = DecantAdvisorResult.fromJson(json);

      for (final volume in result.volumes) {
        expect(containsPriceInformation(volume), isFalse,
            reason:
                'Volume option ${volume.ml}ml must not contain price '
                'information in justification: "${volume.justification}"');
      }
    },
  );
}
