// Testable helper functions for Aura chat parsing logic.

/// Model for a parsed perfume suggestion found in an Aura response.
class PerfumeSuggestion {
  final String name;
  final String house;
  final int compatibility;
  final String? id;

  const PerfumeSuggestion({
    required this.name,
    required this.house,
    required this.compatibility,
    this.id,
  });
}

/// Parses Aura response content to detect perfume recommendations.
///
/// Looks for patterns like:
/// - `**Name** - Brand - XX%`
/// - `Name (Brand) - XX%`
/// - `1. Name - Brand - XX%`
///
/// Only suggestions with scores in [0, 100] and non-empty name/house are included.
List<PerfumeSuggestion> parsePerfumeSuggestions(String content) {
  final suggestions = <PerfumeSuggestion>[];

  // Pattern 1: **Name** - Brand - XX% or **Name** (Brand) XX%
  final boldPattern = RegExp(
    r'\*\*(.+?)\*\*\s*[-–—]?\s*(?:(?:de|by)\s+)?(.+?)\s*[-–—]?\s*(\d{1,3})%',
  );
  for (final match in boldPattern.allMatches(content)) {
    final name = match.group(1)!.trim();
    final house = match.group(2)!.trim();
    final score = int.tryParse(match.group(3)!) ?? -1;
    if (score >= 0 && score <= 100 && name.isNotEmpty && house.isNotEmpty) {
      suggestions.add(PerfumeSuggestion(
        name: name,
        house: house,
        compatibility: score,
      ));
    }
  }
  if (suggestions.isNotEmpty) return suggestions;

  // Pattern 2: Name (Brand) - XX% compatível
  final parenPattern = RegExp(
    r'([A-Z][^()\n]+?)\s*\(([^)]+)\)\s*[-–—]?\s*(\d{1,3})%',
  );
  for (final match in parenPattern.allMatches(content)) {
    final name = match.group(1)!.trim();
    final house = match.group(2)!.trim();
    final score = int.tryParse(match.group(3)!) ?? -1;
    if (score >= 0 && score <= 100 && name.isNotEmpty && house.isNotEmpty) {
      suggestions.add(PerfumeSuggestion(
        name: name,
        house: house,
        compatibility: score,
      ));
    }
  }
  if (suggestions.isNotEmpty) return suggestions;

  // Pattern 3: numbered list "1. Name - Brand - XX%"
  final numberedPattern = RegExp(
    r'\d+\.\s*(.+?)\s*[-–—]\s*(.+?)\s*[-–—]\s*(\d{1,3})%',
  );
  for (final match in numberedPattern.allMatches(content)) {
    final name = match.group(1)!.trim();
    final house = match.group(2)!.trim();
    final score = int.tryParse(match.group(3)!) ?? -1;
    if (score >= 0 && score <= 100 && name.isNotEmpty && house.isNotEmpty) {
      suggestions.add(PerfumeSuggestion(
        name: name,
        house: house,
        compatibility: score,
      ));
    }
  }

  return suggestions;
}
