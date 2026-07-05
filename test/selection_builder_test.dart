import 'package:flutter_test/flutter_test.dart' hide test, expect;
import 'package:glados/glados.dart';
import 'package:frontend/features/selection_builder/presentation/selection_helpers.dart';

// Feature: olfato-rebranding, Property 17: Monte uma Seleção input validation
// Feature: olfato-rebranding, Property 18: Monte uma Seleção result structure (3–5 perfumes)
// **Validates: Requirements 12.2, 12.3, 12.6, 12.7**

// ─── Generators ─────────────────────────────────────────────────────────────

/// Generator for strings shorter than the minimum description length (< 10 chars).
/// Includes empty string and strings of length 1 through 9.
final Generator<String> _shortStringGenerator = any.choose([
  '',
  ' ',
  '   ',
  'a',
  'ab',
  'abc',
  'abcd',
  'abcde',
  'abcdef',
  'abcdefg',
  'abcdefgh',
  'abcdefghi', // 9 chars
  '  abc  ', // trimmed = 3 chars
  '    a    ', // trimmed = 1 char
  'oi tudo', // 7 chars
  'buscando', // 8 chars
  'perfumes', // 8 chars
  '12345678', // 8 chars
  '123456789', // 9 chars
]);

/// Generator for valid-length description strings (10 to 500 chars).
final Generator<String> _validLengthStringGenerator = any.choose([
  'abcdefghij', // exactly 10 chars
  'Preciso de algo discreto', // 24 chars
  'Busco um perfume fresco para o verão e trabalho remoto.', // > 10
  'Quero presentear minha mãe com algo floral e suave para o dia a dia.',
  'Procuro algo marcante para encontros noturnos que dure bastante.',
  'Algo versátil para uso diário em ambiente corporativo.',
  'Um perfume oriental intenso para noites frias de inverno.',
  'Gosto de notas cítricas e aquáticas para atividades ao ar livre.',
  'Presente para meu pai, ele prefere perfumes amadeirados e discretos.',
  'a' * 10, // exactly min
  'b' * 50,
  'c' * 100,
  'd' * 250,
  'e' * 499,
  'f' * 500, // exactly max
]);

/// Generator for strings that exceed the maximum description length (> 500 chars).
final Generator<String> _tooLongStringGenerator = any.choose([
  'a' * 501,
  'b' * 600,
  'c' * 700,
  'd' * 800,
  'e' * 1000,
  'f' * 501, // just over limit
  'g' * 550,
]);

/// Generator for perfume recommendation names.
final Generator<String> _nameGenerator = any.choose([
  'Light Blue',
  'Sauvage',
  'La Vie Est Belle',
  'Bleu de Chanel',
  'Acqua di Giò',
  'Good Girl',
  'Libre',
  'Ombré Nomade',
  'Baccarat Rouge 540',
  'Dolce & Gabbana The One',
]);

/// Generator for brand names.
final Generator<String> _brandGenerator = any.choose([
  'Dior',
  'Chanel',
  'Lancôme',
  'Carolina Herrera',
  'Armani',
  'YSL',
  'Tom Ford',
  'Maison Francis Kurkdjian',
  'Dolce & Gabbana',
  'Versace',
]);

/// Generator for volume descriptions.
final Generator<String> _volumeGenerator = any.choose([
  '50ml',
  '100ml',
  '75ml',
  '30ml',
  '125ml',
  '200ml',
  '40ml',
  '90ml',
]);

/// Generator for justification text.
final Generator<String> _justificationGenerator = any.choose([
  'Perfeito para o clima quente e ocasiões ao ar livre.',
  'Combina com o estilo descrito e tem ótima projeção.',
  'Ideal para ambientes corporativos, discreto mas marcante.',
  'Excelente escolha para encontros noturnos.',
  'Versátil e sofisticado, funciona em qualquer contexto.',
  'Um clássico moderno com excelente custo-benefício.',
  'Fragrância única que se destaca em qualquer ambiente.',
]);

/// Generator for a well-formed perfume recommendation map.
final Generator<Map<String, dynamic>> _perfumeRecommendationGenerator =
    any.combine4(
  _nameGenerator,
  _brandGenerator,
  _volumeGenerator,
  _justificationGenerator,
  (name, brand, volume, justification) => <String, dynamic>{
    'name': name,
    'brand': brand,
    'volume': volume,
    'justification': justification,
  },
);

/// Generator for a valid result list (exactly 3, 4, or 5 items).
/// Uses combine4 to build lists of 3 items with an optional count extension.
final Generator<List<Map<String, dynamic>>> _validResultListGenerator =
    any.combine4(
  _perfumeRecommendationGenerator,
  _perfumeRecommendationGenerator,
  _perfumeRecommendationGenerator,
  any.choose([0, 1, 2]),
  (item1, item2, item3, extra) {
    final list = [item1, item2, item3];
    for (var i = 0; i < extra; i++) {
      list.add(<String, dynamic>{
        'name': 'Extra Perfume ${i + 1}',
        'brand': 'Brand ${i + 1}',
        'volume': '100ml',
        'justification': 'Uma opção adicional excelente.',
      });
    }
    return list;
  },
);

/// Generator for result list counts with too few items (0 to 2).
final Generator<int> _tooFewCountGenerator = any.choose([0, 1, 2]);

/// Generator for result list counts with too many items (6 to 10).
final Generator<int> _tooManyCountGenerator = any.choose([6, 7, 8, 9, 10]);

void main() {
  // ─── Property 17: Monte uma Seleção input validation ──────────────────────
  //
  // For any input string with length less than 10 characters (including empty),
  // the form displays a validation message and does not submit.
  // For any input string exceeding 500 characters, the form prevents submission.

  Glados(_shortStringGenerator).test(
    'Property 17: Input shorter than 10 chars returns validation error',
    (text) {
      final result = validateSelectionInput(text);
      expect(result, isNotNull,
          reason:
              'Input with trimmed length ${text.trim().length} should fail validation');
      expect(result, equals(kValidationErrorMessage),
          reason: 'Error message should match expected validation message');
    },
  );

  Glados(_validLengthStringGenerator).test(
    'Property 17: Input between 10 and 500 chars returns null (valid)',
    (text) {
      final result = validateSelectionInput(text);
      expect(result, isNull,
          reason:
              'Input with trimmed length ${text.trim().length} should pass validation');
    },
  );

  Glados(_tooLongStringGenerator).test(
    'Property 17: Input exceeding 500 chars returns validation error',
    (text) {
      final result = validateSelectionInput(text);
      expect(result, isNotNull,
          reason:
              'Input with length ${text.trim().length} should fail validation');
      expect(result, equals(kValidationErrorMessage),
          reason: 'Error message should match expected validation message');
    },
  );

  // ─── Property 18: Monte uma Seleção result structure (3–5 perfumes) ───────
  //
  // For any valid submission, the Aura response contains between 3 and 5
  // perfume recommendations, each including name, brand, volume, and
  // justification text.

  Glados(_validResultListGenerator).test(
    'Property 18: Valid result with 3-5 well-formed items passes structure check',
    (results) {
      expect(isValidResultStructure(results), isTrue,
          reason:
              'A list of ${results.length} well-formed items should be valid');
    },
  );

  Glados(_tooFewCountGenerator).test(
    'Property 18: Result with fewer than 3 items fails structure check',
    (count) {
      final results = List.generate(
        count,
        (i) => <String, dynamic>{
          'name': 'Perfume $i',
          'brand': 'Brand $i',
          'volume': '100ml',
          'justification': 'Justification $i',
        },
      );
      expect(isValidResultStructure(results), isFalse,
          reason:
              'A list with $count items (< 3) should fail structure check');
    },
  );

  Glados(_tooManyCountGenerator).test(
    'Property 18: Result with more than 5 items fails structure check',
    (count) {
      final results = List.generate(
        count,
        (i) => <String, dynamic>{
          'name': 'Perfume $i',
          'brand': 'Brand $i',
          'volume': '100ml',
          'justification': 'Justification $i',
        },
      );
      expect(isValidResultStructure(results), isFalse,
          reason:
              'A list with $count items (> 5) should fail structure check');
    },
  );
}
