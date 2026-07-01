import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ],
        child: const PerfumeCollectionApp(),
      ),
    );
    await tester.pump();

    // Should show login page with app title
    expect(find.text('Perfume Collection'), findsOneWidget);
    expect(find.text('Seu assistente pessoal de perfumes'), findsOneWidget);
  });

  testWidgets('Login page has Google sign-in button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ],
        child: const PerfumeCollectionApp(),
      ),
    );
    await tester.pump();

    // Should have an elevated button
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier() : super() {
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}
