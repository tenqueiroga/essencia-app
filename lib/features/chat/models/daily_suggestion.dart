/// Model representing a daily perfume suggestion.
///
/// Enforces invariants:
/// - [compatibilityScore] is always clamped to [0, 100]
/// - [justification] is always at most 280 characters
/// - [isOwned] correctly reflects ownership status
class DailySuggestion {
  final String perfumeName;
  final int compatibilityScore;
  final String justification;
  final bool isOwned;
  final String? perfumeId;

  const DailySuggestion({
    required this.perfumeName,
    required this.compatibilityScore,
    required this.justification,
    required this.isOwned,
    this.perfumeId,
  });

  /// Creates a [DailySuggestion] from a JSON map, enforcing model invariants:
  /// - compatibility_score is clamped to [0, 100]
  /// - justification is truncated to 280 characters max
  factory DailySuggestion.fromJson(Map<String, dynamic> json) {
    final rawScore = (json['compatibility_score'] as num?)?.toInt() ?? 0;
    final clampedScore = rawScore.clamp(0, 100);

    final rawJustification = (json['justification'] as String?) ?? '';
    final truncatedJustification = rawJustification.length > 280
        ? rawJustification.substring(0, 280)
        : rawJustification;

    final isOwned = json['is_owned'] as bool? ?? false;

    return DailySuggestion(
      perfumeName:
          json['perfume_name'] ?? json['perfume']?['name'] ?? '',
      compatibilityScore: clampedScore,
      justification: truncatedJustification,
      isOwned: isOwned,
      perfumeId: json['perfume_id'] as String?,
    );
  }
}
