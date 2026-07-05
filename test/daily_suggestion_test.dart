import 'package:flutter_test/flutter_test.dart' hide test, expect;
import 'package:glados/glados.dart';
import 'package:frontend/features/chat/models/daily_suggestion.dart';

// Feature: olfato-rebranding, Property 20: Daily suggestion model invariants
// Feature: olfato-rebranding, Property 21: Daily suggestion prioritizes collection
// Feature: olfato-rebranding, Property 22: Daily suggestion ownership label
// **Validates: Requirements 13.2, 13.3, 13.4**

void main() {
  // ─── Property 20: Daily suggestion model invariants ─────────────────────────
  //
  // For any daily suggestion, the compatibility_score is in [0, 100]
  // and the justification text is at most 280 characters.

  Glados(any.intInRange(-100, 200)).test(
    'Property 20a: compatibility_score is clamped to [0, 100] — '
    'for any int input in [-100, 200], fromJson clamps to [0, 100]',
    (score) {
      final json = <String, dynamic>{
        'perfume_name': 'Test Perfume',
        'compatibility_score': score,
        'justification': 'A good match for today.',
        'is_owned': true,
      };

      final suggestion = DailySuggestion.fromJson(json);

      expect(suggestion.compatibilityScore, greaterThanOrEqualTo(0));
      expect(suggestion.compatibilityScore, lessThanOrEqualTo(100));
    },
  );

  Glados(any.intInRange(0, 600)).test(
    'Property 20b: justification is truncated to ≤ 280 characters — '
    'for any string length, fromJson enforces justification ≤ 280 chars',
    (length) {
      final justification = 'X' * length;
      final json = <String, dynamic>{
        'perfume_name': 'Test Perfume',
        'compatibility_score': 85,
        'justification': justification,
        'is_owned': true,
      };

      final suggestion = DailySuggestion.fromJson(json);

      expect(suggestion.justification.length, lessThanOrEqualTo(280));
    },
  );

  // ─── Property 22: Daily suggestion ownership label ──────────────────────────
  //
  // For any daily suggestion where the perfume is not in the user's collection,
  // the suggestion is marked as not-owned.

  Glados(any.choose([true, false])).test(
    'Property 22: isOwned flag is preserved correctly — '
    'for any boolean isOwned value, the model preserves it',
    (isOwned) {
      final json = <String, dynamic>{
        'perfume_name': 'Test Perfume',
        'compatibility_score': 70,
        'justification': 'Great for the weather today.',
        'is_owned': isOwned,
      };

      final suggestion = DailySuggestion.fromJson(json);

      expect(suggestion.isOwned, equals(isOwned));
    },
  );

  // ─── Property 21: Daily suggestion prioritizes collection ───────────────────
  //
  // This property tests that when isOwned is false, the model correctly flags
  // the suggestion as not-owned (frontend model level verification).
  // The actual prioritization logic lives on the backend; here we verify the
  // frontend model correctly represents ownership status from the API response.

  Glados(any.choose([true, false])).test(
    'Property 21: ownership status from API is correctly represented — '
    'when is_owned is false, suggestion.isOwned is false (not-owned label applies)',
    (isOwned) {
      final json = <String, dynamic>{
        'perfume_name': 'Suggested Perfume',
        'compatibility_score': 55,
        'justification': 'Matches current weather profile.',
        'is_owned': isOwned,
        'perfume_id': 'perfume-123',
      };

      final suggestion = DailySuggestion.fromJson(json);

      if (!isOwned) {
        expect(suggestion.isOwned, isFalse,
            reason: 'Non-owned perfumes must be flagged as not-owned');
      } else {
        expect(suggestion.isOwned, isTrue,
            reason: 'Owned perfumes must be flagged as owned');
      }
    },
  );
}
