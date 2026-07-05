/// Pure helper functions for the Comparador VS feature.
///
/// These are extracted from the compare page widgets to enable
/// property-based testing without widget dependencies.

/// Resolves the display value for a comparison field.
///
/// Returns the original [value] if it is non-null and non-empty,
/// otherwise returns 'Indisponível'. Never returns null or empty string.
String resolveComparisonFieldDisplay(String? value) {
  return (value != null && value.isNotEmpty) ? value : 'Indisponível';
}
