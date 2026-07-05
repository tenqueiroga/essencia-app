import 'package:flutter_test/flutter_test.dart' hide test, expect;
import 'package:glados/glados.dart';
import 'package:frontend/features/perfume_detail/presentation/perfume_detail_page.dart';

// Feature: olfato-rebranding, Property 7: Scent summary length constraint
// Feature: olfato-rebranding, Property 8: Performance metrics clamped to [0, 100]
// Feature: olfato-rebranding, Property 9: Similares list bounded to 10 items
// **Validates: Requirements 7.2, 7.4, 7.5**

/// Generator for arbitrary strings (including long ones).
final Generator<String> _descriptionGenerator = any.letterOrDigits;

/// Generator for arbitrary integers (wide range to test clamping).
final Generator<int> _performanceValueGenerator = any.intInRange(-500, 600);

/// Generator for lists of varying length (0 to 30 items).
final Generator<List<int>> _similaresListGenerator =
    any.listWithLengthInRange(0, 30, any.intInRange(0, 100));

void main() {
  // ─── Property 7: Scent summary length constraint ──────────────────────────
  //
  // For any perfume scent summary, the displayed text is at most 150 characters.

  Glados(_descriptionGenerator).test(
    'Property 7: Scent summary length constraint — '
    'for any description string, clampScentSummary returns ≤ 150 chars',
    (description) {
      final summary = clampScentSummary(description);

      expect(summary.length, lessThanOrEqualTo(150));
    },
  );

  // ─── Property 8: Performance metrics clamped to [0, 100] ─────────────────
  //
  // For any perfume performance data (Fixação, Projeção, Rastro), the rendered
  // bar value is clamped to [0, 100].

  Glados(_performanceValueGenerator).test(
    'Property 8: Performance metrics clamped to [0, 100] — '
    'for any int value, clampPerformanceValue returns value in [0, 100]',
    (value) {
      final clamped = clampPerformanceValue(value);

      expect(clamped, greaterThanOrEqualTo(0));
      expect(clamped, lessThanOrEqualTo(100));
    },
  );

  // ─── Property 9: Similares list bounded to 10 items ───────────────────────
  //
  // For any perfume with similar entries, the section displays at most 10 items.

  Glados(_similaresListGenerator).test(
    'Property 9: Similares list bounded to 10 items — '
    'for any list of any length, boundSimilares returns ≤ 10 items',
    (similares) {
      final bounded = boundSimilares(similares);

      expect(bounded.length, lessThanOrEqualTo(10));
    },
  );
}
