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
/// Looks for patterns like:
/// - `**Name** - Brand - XX% [id:UUID]`
/// - `**Name** - Brand - XX%`
/// - `Name (Brand) - XX%`
/// - `1. Name - Brand - XX%`
///
/// Extracts optional `[id:VALUE]` token for direct navigation.
/// Only suggestions with scores in [0, 100] and non-empty name/house are included.
List<PerfumeSuggestion> parsePerfumeSuggestions(String content) {
  final suggestions = <PerfumeSuggestion>[];

  // Pattern to extract optional [id:VALUE] token
  final idPattern = RegExp(r'\[id:([^\]]+)\]');

  // Pattern 1: **Name** - Brand - XX% [id:VALUE]
  final boldPattern = RegExp(
    r'\*\*(.+?)\*\*\s*[-–—]?\s*(?:(?:de|by)\s+)?(.+?)\s*[-–—]?\s*(\d{1,3})%(?:\s*\[id:([^\]]+)\])?',
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

  // Pattern 2: Name (Brand) - XX% [id:VALUE]
  final parenPattern = RegExp(
    r'([A-Z][^()\n]+?)\s*\(([^)]+)\)\s*[-–—]?\s*(\d{1,3})%(?:\s*\[id:([^\]]+)\])?',
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

  // Pattern 3: numbered list "1. Name - Brand - XX% [id:VALUE]"
  final numberedPattern = RegExp(
    r'\d+\.\s*(.+?)\s*[-–—]\s*(.+?)\s*[-–—]\s*(\d{1,3})%(?:\s*\[id:([^\]]+)\])?',
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

  return suggestions;
}

/// Removes perfume suggestion patterns and [id:...] tokens from content
/// so the text bubble displays clean prose without structured data.
String removePerfumePatterns(String content) {
  final lines = content.split('\n');
  final cleaned = lines.where((line) {
    final trimmed = line.trim();
    // Remove lines that are purely perfume entries
    if (RegExp(r'^\d+\.\s*.+[-–—].+[-–—]\s*\d{1,3}%').hasMatch(trimmed)) {
      return false;
    }
    if (RegExp(r'^\*\*.+\*\*\s*[-–—]?\s*.+\s*[-–—]?\s*\d{1,3}%')
        .hasMatch(trimmed)) {
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
