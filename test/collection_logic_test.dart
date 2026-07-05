import 'package:flutter_test/flutter_test.dart' hide test, expect;
import 'package:glados/glados.dart';
import 'package:frontend/features/collection/presentation/collection_page.dart';

// Feature: olfato-rebranding, Property 10: Collection stats count correctly per type
// Feature: olfato-rebranding, Property 11: Collection filter correctness
// Feature: olfato-rebranding, Property 12: Collection never shows prices
// **Validates: Requirements 8.1, 8.2, 8.5, 8.6, 8.8**

// ─── Generators ─────────────────────────────────────────────────────────────

/// Valid collection item type strings.
final _typeValues = ['perfume', 'decant', 'amostra'];

/// Olfactory family names for testing.
final _familyNames = [
  'Floral',
  'Oriental',
  'Amadeirada',
  'Cítrica',
  'Aquática',
  'Aromática',
  'Gourmand',
  'Fougère',
];

/// Generator for a valid type string.
final Generator<String> _typeGenerator = any.choose(_typeValues);

/// Generator for a family name.
final Generator<String> _familyGenerator = any.choose(_familyNames);

/// Generator for a single collection item map (no price keys).
final Generator<Map<String, dynamic>> _collectionItemGenerator =
    any.combine3(_typeGenerator, _familyGenerator, any.nonEmptyLetterOrDigits,
        (String type, String family, String name) {
  return <String, dynamic>{
    'type': type,
    'perfume': <String, dynamic>{
      'name': name,
      'brand': 'Brand $name',
      'olfactory_family': {'name': family},
    },
  };
});

/// Generator for a non-empty list of collection items (1+).
final Generator<List<Map<String, dynamic>>> _collectionListGenerator =
    any.nonEmptyList(_collectionItemGenerator);

/// Generator for a CollectionItemType filter (including null for "Todos").
final Generator<CollectionItemType?> _optionalTypeFilterGenerator = any.choose([
  null,
  CollectionItemType.perfume,
  CollectionItemType.decant,
  CollectionItemType.amostra,
]);

/// Generator for an optional family filter (null or a known family).
final Generator<String?> _optionalFamilyFilterGenerator = any.choose([
  null,
  'Floral',
  'Oriental',
  'Amadeirada',
  'Cítrica',
  'Aquática',
  'Aromática',
  'Gourmand',
  'Fougère',
]);

void main() {
  // ─── Property 10: Collection stats count correctly per type ─────────────────
  //
  // For any list of collection items with assorted types, the stats widget
  // displays counts where the sum of (perfumes + decantes + amostras) equals
  // the total collection size.

  Glados(_collectionListGenerator).test(
    'Property 10: Collection stats count correctly per type — '
    'sum of per-type counts equals total collection size',
    (items) {
      final stats = computeCollectionStats(items);

      final sum = (stats[CollectionItemType.perfume] ?? 0) +
          (stats[CollectionItemType.decant] ?? 0) +
          (stats[CollectionItemType.amostra] ?? 0);

      expect(sum, equals(items.length));
    },
  );

  // ─── Property 11: Collection filter correctness ─────────────────────────────
  //
  // For any collection, type filter, and olfactory family filter combination,
  // all displayed items satisfy both filter predicates.

  Glados3(_collectionListGenerator, _optionalTypeFilterGenerator,
          _optionalFamilyFilterGenerator)
      .test(
    'Property 11: Collection filter correctness — '
    'all filtered items match both type and family predicates',
    (items, typeFilter, familyFilter) {
      final filtered = filterCollectionItems(
        items,
        typeFilter: typeFilter,
        familyFilter: familyFilter,
      );

      for (final item in filtered) {
        // Type predicate
        if (typeFilter != null) {
          final itemType = parseCollectionItemType(item['type'] as String?) ??
              CollectionItemType.perfume;
          expect(itemType, equals(typeFilter));
        }

        // Family predicate
        if (familyFilter != null && familyFilter.isNotEmpty) {
          final perfume = item['perfume'] as Map<String, dynamic>;
          final family =
              (perfume['olfactory_family']?['name'] as String?)?.toLowerCase() ??
                  '';
          expect(family, equals(familyFilter.toLowerCase()));
        }
      }
    },
  );

  // ─── Property 12: Collection never shows prices ─────────────────────────────
  //
  // For any collection item rendered, no price information is displayed.
  // The item data should not contain price-related keys or currency formatting.

  Glados(_collectionListGenerator).test(
    'Property 12: Collection never shows prices — '
    'no item in the rendered data contains price-related keys or formatting',
    (items) {
      final priceKeys = ['price', 'preco', 'valor', 'cost', 'custo'];
      final currencyPatterns = [
        RegExp(r'R\$'),
        RegExp(r'\$'),
        RegExp(r'€'),
        RegExp(r'£'),
      ];

      for (final item in items) {
        // Check top-level keys
        for (final key in priceKeys) {
          expect(item.containsKey(key), isFalse,
              reason: 'Item should not have "$key" key');
        }

        // Check perfume sub-map keys
        final perfume = item['perfume'] as Map<String, dynamic>?;
        if (perfume != null) {
          for (final key in priceKeys) {
            expect(perfume.containsKey(key), isFalse,
                reason: 'Perfume data should not have "$key" key');
          }

          // Check all string values in perfume map for currency patterns
          for (final entry in perfume.entries) {
            if (entry.value is String) {
              for (final pattern in currencyPatterns) {
                expect(pattern.hasMatch(entry.value as String), isFalse,
                    reason:
                        'Perfume field "${entry.key}" should not contain currency symbol');
              }
            }
          }
        }
      }
    },
  );
}
