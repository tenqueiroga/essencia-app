import 'package:flutter_test/flutter_test.dart' hide test, expect, group;
import 'package:glados/glados.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/theme/theme_notifier.dart';

// Feature: olfato-rebranding, Property 1: Theme persistence round-trip
// **Validates: Requirements 3.6**

/// Generator for AppThemeMode — produces random light/dark values.
/// Values toward the front of the list are simpler (used during shrinking).
final Generator<AppThemeMode> _appThemeModeGenerator = any.choose([
  AppThemeMode.light,
  AppThemeMode.dark,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Property 1: Theme persistence round-trip
  //
  // For any AppThemeMode value (light or dark), persisting the theme preference
  // to storage and then loading it back should return the same mode value.
  Glados(_appThemeModeGenerator).test(
    'Property 1: Theme persistence round-trip — '
    'for any AppThemeMode, setMode then re-instantiating ThemeNotifier '
    'loads back the same mode',
    (mode) async {
      // Set up SharedPreferences mock with empty initial values
      SharedPreferences.setMockInitialValues({});

      // Create first notifier and persist the mode
      final notifier1 = ThemeNotifier();
      // Wait for initial _load() to complete
      await Future<void>.delayed(Duration.zero);
      // Persist the given mode
      await notifier1.setMode(mode);

      // Verify the mode was set on the first notifier
      expect(notifier1.state, equals(mode));

      // Re-instantiate a new ThemeNotifier (simulates app restart)
      // SharedPreferences retains the stored value from notifier1
      final notifier2 = ThemeNotifier();
      // Wait for _load() to complete in the new notifier
      await Future<void>.delayed(Duration.zero);

      // The loaded mode should match what was persisted
      expect(notifier2.state, equals(mode));

      // Clean up
      notifier1.dispose();
      notifier2.dispose();
    },
  );
}
