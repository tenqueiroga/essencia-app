// Testable helper functions for Aura chat parsing logic.

/// Model for a parsed perfume suggestion found in an Aura response.
class PerfumeSuggestion {
  final String name;
  final String house;
  final int compatibility;
  final String? id;
  final String? imageUrl;

  const PerfumeSuggestion({
    required this.name,
    required this.house,
    required this.compatibility,
    this.id,
    this.imageUrl,
  });
}

/// Parses Aura response content to detect perfume recommendations.
///
/// Very permissive — handles many GPT output variations:
/// - `**Name** - Brand - XX% [id:UUID]`
/// - `**Name** — Brand — 93% match`
/// - `**Name** - Brand - 85% compatível`
/// - `Name (Brand) — XX%`
/// - `1. Name - Brand - XX%`
/// - Lines with just `Name - Brand - XX%`
///
/// Strips trailing words like "match", "compatível", "de compatibilidade".
/// Only suggestions with scores in [0, 100] and non-empty name/house are included.
List<PerfumeSuggestion> parsePerfumeSuggestions(String content) {
  final suggestions = <PerfumeSuggestion>[];

  // Pattern 1: **Name** - Brand - XX% (with optional trailing text and [id:VALUE])
  // Accepts -, –, — as separators. Percentage can be followed by extra text.
  final boldPattern = RegExp(
    r'\*\*(.+?)\*\*\s*[-–—]\s*(.+?)\s*[-–—]\s*(\d{1,3})\s*%(?:\s*(?:match|compatível|de compatibilidade))?(?:\s*\[id:([^\]]+)\])?',
    caseSensitive: false,
  );
  for (final match in boldPattern.allMatches(content)) {
    final name = match.group(1)!.trim();
    final house = match.group(2)!.trim();
    final score = int.tryParse(match.group(3)!) ?? -1;
    final id = match.group(4)?.trim();
    if (score >= 0 && score <= 100 && name.isNotEmpty && house.isNotEmpty) {
      suggestions.add(PerfumeSuggestion(
        name: name,
        house: house,
        compatibility: score,
        id: id,
        imageUrl: id != null ? _resolveImageUrl(id) : null,
      ));
    }
  }
  if (suggestions.isNotEmpty) return suggestions;

  // Pattern 1b: **Name** (Brand) — XX% (brand in parentheses after bold name)
  final boldParenPattern = RegExp(
    r'\*\*(.+?)\*\*\s*\(([^)]+)\)\s*[-–—]?\s*(\d{1,3})\s*%(?:\s*(?:match|compatível))?(?:\s*\[id:([^\]]+)\])?',
    caseSensitive: false,
  );
  for (final match in boldParenPattern.allMatches(content)) {
    final name = match.group(1)!.trim();
    final house = match.group(2)!.trim();
    final score = int.tryParse(match.group(3)!) ?? -1;
    final id = match.group(4)?.trim();
    if (score >= 0 && score <= 100 && name.isNotEmpty && house.isNotEmpty) {
      suggestions.add(PerfumeSuggestion(
        name: name,
        house: house,
        compatibility: score,
        id: id,
        imageUrl: id != null ? _resolveImageUrl(id) : null,
      ));
    }
  }
  if (suggestions.isNotEmpty) return suggestions;

  // Pattern 2: Name (Brand) - XX%
  final parenPattern = RegExp(
    r'([A-Z][^()\n]+?)\s*\(([^)]+)\)\s*[-–—]?\s*(\d{1,3})\s*%(?:\s*(?:match|compatível))?(?:\s*\[id:([^\]]+)\])?',
    caseSensitive: false,
  );
  for (final match in parenPattern.allMatches(content)) {
    final name = match.group(1)!.trim();
    final house = match.group(2)!.trim();
    final score = int.tryParse(match.group(3)!) ?? -1;
    final id = match.group(4)?.trim();
    if (score >= 0 && score <= 100 && name.isNotEmpty && house.isNotEmpty) {
      suggestions.add(PerfumeSuggestion(
        name: name,
        house: house,
        compatibility: score,
        id: id,
        imageUrl: id != null ? _resolveImageUrl(id) : null,
      ));
    }
  }
  if (suggestions.isNotEmpty) return suggestions;

  // Pattern 3: numbered list "1. Name - Brand - XX%"
  final numberedPattern = RegExp(
    r'\d+\.\s*(.+?)\s*[-–—]\s*(.+?)\s*[-–—]\s*(\d{1,3})\s*%(?:\s*(?:match|compatível))?(?:\s*\[id:([^\]]+)\])?',
    caseSensitive: false,
  );
  for (final match in numberedPattern.allMatches(content)) {
    final name = match.group(1)!.trim();
    final house = match.group(2)!.trim();
    final score = int.tryParse(match.group(3)!) ?? -1;
    final id = match.group(4)?.trim();
    if (score >= 0 && score <= 100 && name.isNotEmpty && house.isNotEmpty) {
      suggestions.add(PerfumeSuggestion(
        name: name,
        house: house,
        compatibility: score,
        id: id,
        imageUrl: id != null ? _resolveImageUrl(id) : null,
      ));
    }
  }
  if (suggestions.isNotEmpty) return suggestions;

  // Pattern 4: Fallback — **Name** followed by "da/de" Brand (no % required)
  // Catches formats like "**Cool Water** da Davidoff" when GPT ignores format rules
  // Assigns a default 80% compatibility since GPT didn't provide one
  final noPercentPattern = RegExp(
    r'\*\*(.+?)\*\*\s*(?:[-–—]\s*|da\s+|de\s+|by\s+)([A-Z][A-Za-zÀ-ÿ& ]+)',
  );
  for (final match in noPercentPattern.allMatches(content)) {
    final name = match.group(1)!.trim();
    var house = match.group(2)!.trim();
    // Clean trailing common words
    house = house.replaceAll(RegExp(r'\s+(seria|também|é|pode|tem|combina).*', caseSensitive: false), '').trim();
    if (name.isNotEmpty && house.isNotEmpty && house.length < 40 && house.length > 2) {
      suggestions.add(PerfumeSuggestion(
        name: name,
        house: house,
        compatibility: 80, // default when GPT doesn't provide %
      ));
    }
  }

  return suggestions;
}

/// Removes perfume suggestion patterns and [id:...] tokens from content
/// so the text bubble displays clean prose without structured data.
String removePerfumePatterns(String content) {
  final lines = content.split('\n');
  final cleaned = lines.where((line) {
    final trimmed = line.trim();
    // Remove lines that match numbered perfume patterns with %
    if (RegExp(r'^\d+\.\s*.+[-–—].+[-–—]\s*\d{1,3}\s*%').hasMatch(trimmed)) {
      return false;
    }
    // Remove lines that are bold perfume entries with %
    if (RegExp(r'^\*\*.+\*\*\s*[-–—(]').hasMatch(trimmed) &&
        RegExp(r'\d{1,3}\s*%').hasMatch(trimmed)) {
      return false;
    }
    // Remove lines that are just "**Name** - Brand - XX%"
    if (RegExp(r'^\*\*.+\*\*\s*[-–—]\s*.+[-–—]\s*\d{1,3}\s*%').hasMatch(trimmed)) {
      return false;
    }
    return true;
  }).toList();

  // Also remove any remaining [id:...] tokens from text
  return cleaned.join('\n').replaceAll(RegExp(r'\[id:[^\]]+\]'), '').trim();
}

/// Resolve image URL from perfume ID.
String _resolveImageUrl(String perfumeId) {
  const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://essencia.laravel.cloud/api',
  );
  return '$baseUrl/perfumes/$perfumeId/image';
}
