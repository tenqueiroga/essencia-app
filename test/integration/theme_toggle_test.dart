import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/theme/theme_notifier.dart';
import 'package:frontend/app/theme/olfato_theme.dart';
import 'package:frontend/app/theme/olfato_tokens.dart';

/// Integration test: Theme toggle persists and applies correctly (end-to-end).
///
/// Validates: Requirements 3.5, 3.6
///
/// Tests the full flow:
/// 1. Start with light theme preference → verify light theme renders
/// 2. Toggle to dark → verify dark theme applies
/// 3. Re-instantiate (simulate restart) → verify dark persists
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme toggle integration', () {
    testWidgets('starts in light mode when SharedPreferences has light stored',
        (tester) async {
      SharedPreferences.setMockInitialValues({'olfato_theme_mode': 'light'});

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeProvider);
              final theme = mode == AppThemeMode.dark
                  ? OlfatoTheme.darkTheme
                  : OlfatoTheme.lightTheme;

              return MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: Text(
                    'Hello',
                    key: const Key('test-text'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the scaffold uses the light background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final context = tester.element(find.byType(Scaffold));
      final themeData = Theme.of(context);

      expect(themeData.brightness, equals(Brightness.light));
      expect(
        themeData.scaffoldBackgroundColor,
        equals(OlfatoTokens.backgroundLight),
      );
    });

    testWidgets('toggles to dark mode and applies dark theme', (tester) async {
      SharedPreferences.setMockInitialValues({'olfato_theme_mode': 'light'});

      late StateNotifierProvider<ThemeNotifier, AppThemeMode> localProvider;
      localProvider = themeProvider;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(localProvider);
              final theme = mode == AppThemeMode.dark
                  ? OlfatoTheme.darkTheme
                  : OlfatoTheme.lightTheme;

              return MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: ElevatedButton(
                    key: const Key('toggle-btn'),
                    onPressed: () {
                      ref.read(localProvider.notifier).setMode(AppThemeMode.dark);
                    },
                    child: const Text('Toggle'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial light theme
      var context = tester.element(find.byType(Scaffold));
      var themeData = Theme.of(context);
      expect(themeData.brightness, equals(Brightness.light));

      // Tap the toggle button to switch to dark mode
      await tester.tap(find.byKey(const Key('toggle-btn')));
      await tester.pumpAndSettle();

      // Verify dark theme is now applied
      context = tester.element(find.byType(Scaffold));
      themeData = Theme.of(context);
      expect(themeData.brightness, equals(Brightness.dark));
      expect(
        themeData.scaffoldBackgroundColor,
        equals(OlfatoTokens.backgroundDark),
      );
    });

    testWidgets('dark mode persists after re-instantiation (simulated restart)',
        (tester) async {
      // First, store dark in SharedPreferences (simulate previous toggle)
      SharedPreferences.setMockInitialValues({'olfato_theme_mode': 'dark'});

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeProvider);
              final theme = mode == AppThemeMode.dark
                  ? OlfatoTheme.darkTheme
                  : OlfatoTheme.lightTheme;

              return MaterialApp(
                theme: theme,
                home: const Scaffold(
                  body: Text('Restarted'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dark mode was loaded from persistence
      final context = tester.element(find.byType(Scaffold));
      final themeData = Theme.of(context);
      expect(themeData.brightness, equals(Brightness.dark));
      expect(
        themeData.scaffoldBackgroundColor,
        equals(OlfatoTokens.backgroundDark),
      );
    });

    testWidgets('full flow: light → toggle dark → restart → dark persists',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      // Step 1: Start fresh — defaults to light
      final notifier = ThemeNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state, equals(AppThemeMode.light));

      // Step 2: Toggle to dark
      await notifier.setMode(AppThemeMode.dark);
      expect(notifier.state, equals(AppThemeMode.dark));

      // Step 3: Simulate restart — create new notifier, should load dark
      final notifier2 = ThemeNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(notifier2.state, equals(AppThemeMode.dark));

      // Clean up
      notifier.dispose();
      notifier2.dispose();
    });
  });
}
