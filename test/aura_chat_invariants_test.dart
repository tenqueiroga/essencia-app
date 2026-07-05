import 'package:glados/glados.dart';
import 'package:frontend/features/chat/presentation/chat_helpers.dart';

// Feature: olfato-rebranding, Property 13: Inline perfume suggestion cards contain required fields
// Feature: olfato-rebranding, Property 5 (chat context): Compatibility scores are always in [0, 100]
// **Validates: Requirements 9.3**

/// Generates a random Aura response string in **Name** - Brand - XX% format.
String _buildBoldPatternResponse(String name, String house, int score) {
  return '**$name** - $house - $score% compatível com seu perfil';
}

/// Generates a random Aura response string in Name (Brand) - XX% format.
String _buildParenPatternResponse(String name, String house, int score) {
  // Name must start with uppercase for Pattern 2 to match.
  final capitalName = name.isEmpty ? 'A' : name[0].toUpperCase() + name.substring(1);
  return '$capitalName ($house) - $score% compatível';
}

/// Generates a random Aura response string in numbered list format.
String _buildNumberedPatternResponse(String name, String house, int score) {
  return '1. $name - $house - $score%';
}

/// Generates a response with out-of-range scores that should be rejected.
String _buildOutOfRangeResponse(String name, String house, int score) {
  return '**$name** - $house - $score%';
}

void main() {
  // ─── Property 13: Inline perfume suggestion cards contain required fields ──
  //
  // For any Aura chat response containing perfume suggestions, each inline card
  // displays the perfume name, house, and a compatibility percentage integer
  // in [0, 100].

  Glados2(any.nonEmptyLetterOrDigits, any.nonEmptyLetterOrDigits).test(
    'Property 13 (bold pattern): Each parsed suggestion has non-empty name, non-empty house, '
    'and compatibility in [0, 100]',
    (name, house) {
      // Use a fixed valid score to ensure parsing succeeds
      final response = _buildBoldPatternResponse(name, house, 75);
      final suggestions = parsePerfumeSuggestions(response);

      for (final s in suggestions) {
        expect(s.name, isNotEmpty, reason: 'Suggestion name must be non-empty');
        expect(s.house, isNotEmpty, reason: 'Suggestion house must be non-empty');
        expect(s.compatibility, greaterThanOrEqualTo(0));
        expect(s.compatibility, lessThanOrEqualTo(100));
      }
    },
  );

  Glados(any.intInRange(0, 101)).test(
    'Property 13 (bold pattern): For any valid score in [0, 100], parser produces '
    'suggestions with compatibility in [0, 100]',
    (score) {
      // Clamp to [0, 100] for the input since intInRange is exclusive on upper bound
      final validScore = score.clamp(0, 100);
      final response = _buildBoldPatternResponse('Sauvage', 'Dior', validScore);
      final suggestions = parsePerfumeSuggestions(response);

      expect(suggestions, isNotEmpty);
      for (final s in suggestions) {
        expect(s.name, isNotEmpty);
        expect(s.house, isNotEmpty);
        expect(s.compatibility, equals(validScore));
        expect(s.compatibility, greaterThanOrEqualTo(0));
        expect(s.compatibility, lessThanOrEqualTo(100));
      }
    },
  );

  Glados(any.intInRange(0, 101)).test(
    'Property 13 (paren pattern): For any valid score in [0, 100], parser produces '
    'suggestions with compatibility in [0, 100]',
    (score) {
      final validScore = score.clamp(0, 100);
      final response = _buildParenPatternResponse('Aventus', 'Creed', validScore);
      final suggestions = parsePerfumeSuggestions(response);

      expect(suggestions, isNotEmpty);
      for (final s in suggestions) {
        expect(s.name, isNotEmpty);
        expect(s.house, isNotEmpty);
        expect(s.compatibility, equals(validScore));
        expect(s.compatibility, greaterThanOrEqualTo(0));
        expect(s.compatibility, lessThanOrEqualTo(100));
      }
    },
  );

  Glados(any.intInRange(0, 101)).test(
    'Property 13 (numbered pattern): For any valid score in [0, 100], parser produces '
    'suggestions with compatibility in [0, 100]',
    (score) {
      final validScore = score.clamp(0, 100);
      final response = _buildNumberedPatternResponse('Light Blue', 'Dolce & Gabbana', validScore);
      final suggestions = parsePerfumeSuggestions(response);

      expect(suggestions, isNotEmpty);
      for (final s in suggestions) {
        expect(s.name, isNotEmpty);
        expect(s.house, isNotEmpty);
        expect(s.compatibility, equals(validScore));
        expect(s.compatibility, greaterThanOrEqualTo(0));
        expect(s.compatibility, lessThanOrEqualTo(100));
      }
    },
  );

  // ─── Property 5 (chat context): Compatibility scores are always in [0, 100] ─
  //
  // The parser rejects scores > 100 or < 0 — it checks score >= 0 && score <= 100
  // before adding a suggestion.

  Glados(any.intInRange(101, 1000)).test(
    'Property 5: Scores > 100 are rejected by the parser',
    (score) {
      final response = _buildOutOfRangeResponse('Test Perfume', 'Test House', score);
      final suggestions = parsePerfumeSuggestions(response);

      // Either no suggestions are returned, or all scores are in [0, 100]
      for (final s in suggestions) {
        expect(s.compatibility, greaterThanOrEqualTo(0));
        expect(s.compatibility, lessThanOrEqualTo(100));
      }
    },
  );

  Glados(any.intInRange(-999, 0)).test(
    'Property 5: Negative scores are rejected by the parser',
    (score) {
      // Negative scores won't match \\d{1,3} regex, but verify the invariant holds
      final response = '**Test Perfume** - Test House - $score%';
      final suggestions = parsePerfumeSuggestions(response);

      for (final s in suggestions) {
        expect(s.compatibility, greaterThanOrEqualTo(0));
        expect(s.compatibility, lessThanOrEqualTo(100));
      }
    },
  );
}
