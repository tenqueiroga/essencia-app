import 'package:flutter_test/flutter_test.dart' hide test, expect;
import 'package:glados/glados.dart';
import 'package:frontend/features/home/presentation/home_page.dart';

// Feature: olfato-rebranding, Property 2: Time-of-day emoji mapping
// Feature: olfato-rebranding, Property 3: Temperature-to-family suggestion mapping
// Feature: olfato-rebranding, Property 4: Avatar displays first character of name
// **Validates: Requirements 5.1, 5.2, 5.7**

/// Generator for valid hours (0–23).
final Generator<int> _hourGenerator = any.intInRange(0, 24); // [0, 24) => 0..23

/// Generator for temperature values in a realistic range (-40 to 50).
final Generator<double> _tempGenerator =
    any.doubleInRange(-40.0, 50.0);

/// Generator for non-empty strings (at least 1 character).
final Generator<String> _nonEmptyStringGenerator = any.nonEmptyLetterOrDigits;

void main() {
  // ─── Property 2: Time-of-day emoji mapping ────────────────────────────────
  //
  // For any hour of day in [0, 23], the greeting function should return:
  // ☀️ for hours 5–11, 🌤️ for hours 12–17, and 🌙 for hours 18–4 (wrapping).

  Glados(_hourGenerator).test(
    'Property 2: Time-of-day emoji mapping — '
    'for any hour in [0, 23], getTimeOfDayEmoji returns the correct emoji',
    (hour) {
      final emoji = getTimeOfDayEmoji(hour);

      if (hour >= 5 && hour <= 11) {
        expect(emoji, equals('☀️'));
      } else if (hour >= 12 && hour <= 17) {
        expect(emoji, equals('🌤️'));
      } else {
        // hours 18–23 and 0–4
        expect(emoji, equals('🌙'));
      }
    },
  );

  // ─── Property 3: Temperature-to-family suggestion mapping ─────────────────
  //
  // For any temperature value, the weather widget should return the correct
  // perfume family string per the defined ranges:
  //   ≥30°C → Cítrica/Aquática
  //   25–29 → Fresca/Cítrica
  //   20–24 → Floral/Aromática
  //   15–19 → Amadeirada/Oriental
  //   <15   → Oriental/Gourmand

  Glados(_tempGenerator).test(
    'Property 3: Temperature-to-family suggestion mapping — '
    'for any temperature, getWeatherFamily returns the correct family',
    (temp) {
      final family = getWeatherFamily(temp);

      if (temp >= 30) {
        expect(family, equals('Cítrica/Aquática'));
      } else if (temp >= 25) {
        expect(family, equals('Fresca/Cítrica'));
      } else if (temp >= 20) {
        expect(family, equals('Floral/Aromática'));
      } else if (temp >= 15) {
        expect(family, equals('Amadeirada/Oriental'));
      } else {
        expect(family, equals('Oriental/Gourmand'));
      }
    },
  );

  // ─── Property 4: Avatar displays first character of name ──────────────────
  //
  // For any non-empty user name string, the avatar widget should display the
  // first character (uppercased) of that string.

  Glados(_nonEmptyStringGenerator).test(
    'Property 4: Avatar displays first character of name — '
    'for any non-empty name, getAvatarLetter returns the uppercased first char',
    (name) {
      final letter = getAvatarLetter(name);

      expect(letter, equals(name[0].toUpperCase()));
    },
  );
}
