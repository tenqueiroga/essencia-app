/// Pure helper functions for the Consultor de Decantes feature.
///
/// These are extracted from the decant advisor page to enable
/// property-based testing without widget dependencies.

/// The fixed set of valid decant volumes.
const List<int> kDecantVolumes = [2, 5, 10];

/// Maximum allowed length for volume justification text.
const int kMaxJustificationLength = 140;

/// Model representing a validated volume option for the decant advisor.
class DecantVolumeOption {
  final int ml;
  final String justification;

  const DecantVolumeOption({required this.ml, required this.justification});

  /// Creates a [DecantVolumeOption] from a JSON map, truncating justification
  /// to [kMaxJustificationLength] characters.
  factory DecantVolumeOption.fromJson(Map<String, dynamic> json) {
    final rawJustification = (json['justification'] as String?) ?? '';
    final justification = rawJustification.length > kMaxJustificationLength
        ? rawJustification.substring(0, kMaxJustificationLength)
        : rawJustification;
    return DecantVolumeOption(
      ml: (json['ml'] as num?)?.toInt() ?? 0,
      justification: justification,
    );
  }
}

/// Result of parsing and validating a decant advisor API response.
class DecantAdvisorResult {
  final List<DecantVolumeOption> volumes;
  final int recommendedVolume;

  const DecantAdvisorResult({
    required this.volumes,
    required this.recommendedVolume,
  });

  /// Parses a decant advisor API response JSON into a validated result.
  factory DecantAdvisorResult.fromJson(Map<String, dynamic> json) {
    final volumesJson = json['volumes'] as List? ?? [];
    final volumes = volumesJson
        .map((v) => DecantVolumeOption.fromJson(v as Map<String, dynamic>))
        .toList();
    final recommendedVolume =
        (json['recommended_volume'] as num?)?.toInt() ?? 0;
    return DecantAdvisorResult(
      volumes: volumes,
      recommendedVolume: recommendedVolume,
    );
  }
}

/// Validates that a decant advisor result contains exactly 3 volume options
/// with the expected values (2ml, 5ml, 10ml).
///
/// Returns `true` if valid, `false` otherwise.
bool validateDecantVolumes(DecantAdvisorResult result) {
  if (result.volumes.length != 3) return false;
  final mlValues = result.volumes.map((v) => v.ml).toSet();
  return mlValues.containsAll(kDecantVolumes) && mlValues.length == 3;
}

/// Validates that all justification texts are within the maximum length.
///
/// Returns `true` if all justifications are ≤ [kMaxJustificationLength] chars.
bool validateJustificationLengths(DecantAdvisorResult result) {
  return result.volumes
      .every((v) => v.justification.length <= kMaxJustificationLength);
}

/// Validates that exactly one volume matches the recommended volume.
///
/// Returns `true` if exactly one volume option's `ml` equals [result.recommendedVolume].
bool validateSingleRecommendation(DecantAdvisorResult result) {
  final matchCount =
      result.volumes.where((v) => v.ml == result.recommendedVolume).length;
  return matchCount == 1;
}

/// Generates the CTA text for the decant advisor.
///
/// Returns the string "Melhor escolha para você: Xml" where X is the
/// recommended volume.
String buildDecantCtaText(int recommendedVolume) {
  return 'Melhor escolha para você: ${recommendedVolume}ml';
}

/// Validates that the CTA text references the same volume as the
/// recommended (badged) option.
///
/// Returns `true` if the CTA text contains the recommended volume.
bool validateCtaMatchesRecommendation(
    String ctaText, int recommendedVolume) {
  return ctaText.contains('${recommendedVolume}ml');
}

/// Checks if a volume option's display data contains any price or
/// monetary information.
///
/// Returns `true` if price/currency patterns are detected.
bool containsPriceInformation(DecantVolumeOption option) {
  final pricePatterns = [
    RegExp(r'R\$'),
    RegExp(r'\$'),
    RegExp(r'€'),
    RegExp(r'£'),
    RegExp(r'\d+[.,]\d{2}\b'), // e.g., 29.90 or 29,90
    RegExp(r'reais', caseSensitive: false),
    RegExp(r'preço', caseSensitive: false),
    RegExp(r'price', caseSensitive: false),
    RegExp(r'cust[oa]', caseSensitive: false),
  ];

  for (final pattern in pricePatterns) {
    if (pattern.hasMatch(option.justification)) {
      return true;
    }
  }
  return false;
}
