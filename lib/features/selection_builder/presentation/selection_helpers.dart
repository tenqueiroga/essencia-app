/// Pure helper functions for the Monte uma Seleção feature.
///
/// These are extracted from the selection builder page to enable
/// property-based testing without widget dependencies.

/// Minimum allowed length for the description input.
const int kMinDescriptionLength = 10;

/// Maximum allowed length for the description input.
const int kMaxDescriptionLength = 500;

/// Validation error message displayed when input is too short.
const String kValidationErrorMessage = 'Descreva com mais detalhes o que busca.';

/// Minimum number of perfume recommendations in a valid result.
const int kMinResultCount = 3;

/// Maximum number of perfume recommendations in a valid result.
const int kMaxResultCount = 5;

/// Required fields that every perfume recommendation must contain.
const List<String> kRequiredResultFields = [
  'name',
  'brand',
  'volume',
  'justification',
];

/// Validates the selection input text.
///
/// Returns an error message string if the input is invalid:
/// - Empty or shorter than [kMinDescriptionLength] → returns [kValidationErrorMessage]
/// - Longer than [kMaxDescriptionLength] → returns [kValidationErrorMessage]
///
/// Returns `null` if the input is valid (length in [kMinDescriptionLength, kMaxDescriptionLength]).
String? validateSelectionInput(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.length < kMinDescriptionLength) {
    return kValidationErrorMessage;
  }
  if (trimmed.length > kMaxDescriptionLength) {
    return kValidationErrorMessage;
  }
  return null;
}

/// Validates that a list of perfume recommendation maps has the correct
/// structure for a Monte uma Seleção result.
///
/// Returns `true` if:
/// - The list contains between [kMinResultCount] and [kMaxResultCount] items (3–5)
/// - Each item contains non-empty values for all [kRequiredResultFields]
///
/// Returns `false` otherwise.
bool isValidResultStructure(List<Map<String, dynamic>> results) {
  if (results.length < kMinResultCount || results.length > kMaxResultCount) {
    return false;
  }
  for (final item in results) {
    for (final field in kRequiredResultFields) {
      final value = item[field];
      if (value == null) return false;
      if (value is String && value.isEmpty) return false;
    }
  }
  return true;
}
