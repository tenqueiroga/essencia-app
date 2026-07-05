import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/main_shell.dart';

// Feature: olfato-rebranding, Task 3.3: Navigation structure unit tests
// **Validates: Requirements 4.1, 4.2, 4.4, 4.5**

/// Creates a testable GoRouter that renders MainShell with a child page.
GoRouter _buildTestRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home Page')),
          ),
          GoRoute(
            path: '/explore',
            builder: (_, __) => const Scaffold(body: Text('Explore Page')),
          ),
          GoRoute(
            path: '/scan',
            builder: (_, __) => const Scaffold(body: Text('Scan Page')),
          ),
          GoRoute(
            path: '/collection',
            builder: (_, __) => const Scaffold(body: Text('Collection Page')),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) => const Scaffold(body: Text('Aura Page')),
          ),
        ],
      ),
    ],
  );
}

/// Wraps the test app with MaterialApp.router.
Widget _buildTestApp({String initialLocation = '/'}) {
  final router = _buildTestRouter(initialLocation: initialLocation);
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('Navigation Structure - Tab Order (Req 4.1)', () {
    testWidgets(
        'displays exactly 5 tabs in correct order: Home, Explorar, Scan, Coleção, Aura',
        (tester) async {
      // Set mobile screen size (< 768) to ensure mobile layout renders
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Find all tab labels in the bottom navigation
      final homeLabel = find.text('Home');
      final explorarLabel = find.text('Explorar');
      final scanLabel = find.text('Scan');
      final colecaoLabel = find.text('Coleção');
      final auraLabel = find.text('Aura');

      expect(homeLabel, findsOneWidget);
      expect(explorarLabel, findsOneWidget);
      expect(scanLabel, findsOneWidget);
      expect(colecaoLabel, findsOneWidget);
      expect(auraLabel, findsOneWidget);

      // Verify order by comparing horizontal positions (left to right)
      final homePos = tester.getCenter(homeLabel).dx;
      final explorarPos = tester.getCenter(explorarLabel).dx;
      final scanPos = tester.getCenter(scanLabel).dx;
      final colecaoPos = tester.getCenter(colecaoLabel).dx;
      final auraPos = tester.getCenter(auraLabel).dx;

      expect(homePos, lessThan(explorarPos));
      expect(explorarPos, lessThan(scanPos));
      expect(scanPos, lessThan(colecaoPos));
      expect(colecaoPos, lessThan(auraPos));
    });

    testWidgets('has exactly 5 tab items (no more, no less)', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final tabLabels = ['Home', 'Explorar', 'Scan', 'Coleção', 'Aura'];
      for (final label in tabLabels) {
        expect(find.text(label), findsOneWidget);
      }

      // Confirm no extra tabs
      expect(find.text('Profile'), findsNothing);
      expect(find.text('Perfil'), findsNothing);
    });
  });

  group('Navigation Structure - No Profile Tab (Req 4.4)', () {
    testWidgets('does NOT display a Profile tab in the bottom navigation bar',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Profile / Perfil should not appear as a navigation tab
      expect(find.text('Profile'), findsNothing);
      expect(find.text('Perfil'), findsNothing);

      // Also verify the profile icon is not in the bottom bar
      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(find.byIcon(Icons.person), findsNothing);
    });
  });

  group('Navigation Structure - Elevated Scan Tab (Req 4.2)', () {
    testWidgets('Scan tab is rendered with elevated FAB-style styling',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // The elevated Scan tab uses Transform.translate with a negative Y offset
      // to raise it above the tab bar baseline.
      final translateWidgets = find.byWidgetPredicate((widget) {
        if (widget is Transform) {
          final ty = widget.transform.getTranslation().y;
          return ty < 0; // Negative Y = raised above baseline
        }
        return false;
      });

      // There should be Transform widgets with negative offset (the elevated scan button + label)
      expect(translateWidgets, findsAtLeastNWidgets(1));

      // The Scan tab has a circular container with BoxDecoration(shape: BoxShape.circle)
      final circularDecoratedBoxes = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.shape == BoxShape.circle &&
              (decoration.color != null || decoration.gradient != null);
        }
        return false;
      });

      expect(circularDecoratedBoxes, findsAtLeastNWidgets(1));
    });

    testWidgets('Scan tab is at center position (index 2)', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Get horizontal positions of all tabs
      final homeX = tester.getCenter(find.text('Home')).dx;
      final explorarX = tester.getCenter(find.text('Explorar')).dx;
      final scanX = tester.getCenter(find.text('Scan')).dx;
      final colecaoX = tester.getCenter(find.text('Coleção')).dx;
      final auraX = tester.getCenter(find.text('Aura')).dx;

      // Scan should be between Explorar and Coleção
      expect(scanX, greaterThan(explorarX));
      expect(scanX, lessThan(colecaoX));

      // Scan should be roughly in the center between Home and Aura
      final midpoint = (homeX + auraX) / 2;
      expect(scanX, closeTo(midpoint, 30));
    });
  });

  group('Navigation Structure - Desktop vs Mobile Layout (Req 4.5)', () {
    testWidgets('renders mobile layout with bottom tab bar (width <= 768px)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Mobile layout uses GestureDetector for tab taps
      expect(find.byType(GestureDetector), findsAtLeastNWidgets(4));

      // Should have tab labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explorar'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Coleção'), findsOneWidget);
      expect(find.text('Aura'), findsOneWidget);

      // Mobile layout should NOT show InkWell (desktop nav items use InkWell)
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets(
        'renders desktop layout with side navigation (width > 768px)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Desktop layout uses InkWell for navigation items
      expect(find.byType(InkWell), findsAtLeastNWidgets(5));

      // Should still show all 5 navigation labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explorar'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Coleção'), findsOneWidget);
      expect(find.text('Aura'), findsOneWidget);
    });

    testWidgets('at exactly 768px, renders mobile layout (> 768 is desktop)',
        (tester) async {
      // The breakpoint condition is `width > 768`, so exactly 768 is mobile
      tester.view.physicalSize = const Size(768, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // At 768px, should render mobile layout (GestureDetectors, no InkWells)
      expect(find.byType(GestureDetector), findsAtLeastNWidgets(4));
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('at 769px, renders desktop layout', (tester) async {
      // At 769px (> 768), should switch to desktop layout
      tester.view.physicalSize = const Size(769, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Desktop layout uses InkWell for navigation items
      expect(find.byType(InkWell), findsAtLeastNWidgets(5));
    });
  });
}
