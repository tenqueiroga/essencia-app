import 'package:flutter_test/flutter_test.dart' hide test, expect;
import 'package:glados/glados.dart';
import 'package:frontend/features/compare/presentation/compare_helpers.dart';

// Feature: olfato-rebranding, Property 14: Comparison renders all fields or "Indisponível"
// **Validates: Requirements 10.2, 10.6**

// ─── Generators ─────────────────────────────────────────────────────────────

/// Generator for nullable strings that includes null, empty, and arbitrary text.
final Generator<String?> _nullableStringGenerator = any.choose<String?>([
  null,
  '',
  ' ',
  'curta',
  'média',
  'longa',
  'íntima',
  'moderada',
  'forte',
  'R\$ 299.90',
  'Fresco e cítrico com notas de bergamota',
  'A principal diferença está na projeção',
  'abc123',
  'Um valor qualquer de texto para teste',
]);

void main() {
  // ─── Property 14: Comparison renders all fields or "Indisponível" ───────────
  //
  // For any nullable string (including null, empty, and random text),
  // resolveComparisonFieldDisplay returns either the original non-empty value
  // or exactly "Indisponível" — never blank, never null.

  Glados(_nullableStringGenerator).test(
    'Property 14: Comparison renders all fields or "Indisponível" — '
    'result is never null or empty; it is either the value or "Indisponível"',
    (value) {
      final result = resolveComparisonFieldDisplay(value);

      // Result must never be empty
      expect(result.isNotEmpty, isTrue,
          reason: 'Display value must never be empty');

      // Result must be either the original value or "Indisponível"
      if (value != null && value.isNotEmpty) {
        expect(result, equals(value),
            reason:
                'When value is non-null and non-empty, result must equal the value');
      } else {
        expect(result, equals('Indisponível'),
            reason:
                'When value is null or empty, result must be "Indisponível"');
      }
    },
  );
}
