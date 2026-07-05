import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents the app's theme mode.
enum AppThemeMode { light, dark }

/// Manages the active theme mode with persistence via SharedPreferences.
///
/// Defaults to [AppThemeMode.light] when no preference is stored.
/// Persists the user's choice under the key `olfato_theme_mode`.
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const _key = 'olfato_theme_mode';

  ThemeNotifier() : super(AppThemeMode.light) {
    _load();
  }

  /// Loads the persisted theme preference from SharedPreferences.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'dark') {
      state = AppThemeMode.dark;
    }
  }

  /// Sets the theme mode and persists it to SharedPreferences.
  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == AppThemeMode.dark ? 'dark' : 'light');
  }

  /// Toggles between light and dark modes.
  void toggle() {
    setMode(
      state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light,
    );
  }
}

/// Riverpod provider for the app's theme state.
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
