import 'package:flutter_test/flutter_test.dart' hide test, expect, group;
import 'package:glados/glados.dart';
import 'package:frontend/features/scan/presentation/scan_result_page.dart';

// Feature: olfato-rebranding, Property 5: Compatibility scores are always in [0, 100]
// Feature: olfato-rebranding, Property 6: Scan result constraints
// **Validates: Requirements 6.3, 5.4**

/// Helper to build a JSON map for ScanResultData.fromJson with given params.
Map<String, dynamic> _buildJson({
  int? compatibilityScore,
  String description = '',
  List<String> tags = const [],
}) {
  return {
    'name': 'Test Perfume',
    'house': 'Test House',
    'volume': '100ml',
    if (compatibilityScore != null) 'compatibility_score': compatibilityScore,
    'description': description,
    'tags': tags,
  };
}

void main() {
  // ─── Property 5: Compatibility scores are always in [0, 100] ──────────────
  //
  // For any perfume suggestion, the displayed percentage is an integer
  // in the range [0, 100].

  Glados(any.intInRange(-500, 600)).test(
    'Property 5: Compatibility scores are always in [0, 100] — '
    'for any int input, ScanResultData.fromJson clamps the score to [0, 100]',
    (score) {
      final json = _buildJson(compatibilityScore: score);
      final result = ScanResultData.fromJson(json);

      expect(result.compatibilityScore, isNotNull);
      expect(result.compatibilityScore!, greaterThanOrEqualTo(0));
      expect(result.compatibilityScore!, lessThanOrEqualTo(100));
    },
  );

  // ─── Property 6: Scan result constraints ──────────────────────────────────
  //
  // For any scan identification result, the editorial description is at most
  // 300 characters and the tags list contains at most 5 items.

  Glados(any.intInRange(0, 1000)).test(
    'Property 6a: Description is truncated to at most 300 characters — '
    'for any string length, fromJson enforces description ≤ 300 chars',
    (length) {
      final description = 'A' * length;
      final json = _buildJson(description: description);
      final result = ScanResultData.fromJson(json);

      expect(result.description.length, lessThanOrEqualTo(300));
    },
  );

  Glados(any.intInRange(0, 20)).test(
    'Property 6b: Tags list contains at most 5 items — '
    'for any list length, fromJson enforces tags ≤ 5 items',
    (count) {
      final tags = List.generate(count, (i) => 'tag_$i');
      final json = _buildJson(tags: tags);
      final result = ScanResultData.fromJson(json);

      expect(result.tags.length, lessThanOrEqualTo(5));
    },
  );

  // ─── Edge cases ───────────────────────────────────────────────────────────

  Glados(any.choose([null])).test(
    'Edge case: null score returns null (hidden)',
    (_) {
      final json = _buildJson(compatibilityScore: null);
      final result = ScanResultData.fromJson(json);

      expect(result.compatibilityScore, isNull);
    },
  );

  Glados(any.choose([0])).test(
    'Edge case: empty description is preserved',
    (_) {
      final json = _buildJson(description: '');
      final result = ScanResultData.fromJson(json);

      expect(result.description, equals(''));
    },
  );

  Glados(any.choose([0])).test(
    'Edge case: empty tags list is preserved',
    (_) {
      final json = _buildJson(tags: []);
      final result = ScanResultData.fromJson(json);

      expect(result.tags, isEmpty);
    },
  );
}
