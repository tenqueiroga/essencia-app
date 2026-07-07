import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/collection/presentation/collection_page.dart';
import '../features/collection/presentation/shared_collection_page.dart';
import '../features/explore/presentation/explore_page.dart';
import '../features/scan/presentation/scan_page.dart';
import '../features/scan/presentation/scan_result_page.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/journal/presentation/journal_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/perfume_detail/presentation/perfume_detail_page.dart';
import '../features/compare/presentation/compare_page.dart';
import '../features/decant_advisor/presentation/decant_advisor_page.dart';
import '../features/selection_builder/presentation/selection_builder_page.dart';
import '../features/wishlist/presentation/wishlist_page.dart';
import 'main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/explore', builder: (_, state) {
          final family = state.uri.queryParameters['family'];
          final scan = state.uri.queryParameters['scan'] == 'true';
          return ExplorePage(initialFamily: family, openScan: scan);
        }),
        GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
        GoRoute(
          path: '/scan/result',
          builder: (_, state) {
            final data = state.extra as ScanResultData?;
            return ScanResultPage(resultData: data);
          },
        ),
        GoRoute(
          path: '/chat',
          builder: (_, state) {
            final initialMessage = state.uri.queryParameters['initialMessage'];
            return ChatPage(initialMessage: initialMessage);
          },
        ),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        GoRoute(path: '/collection', builder: (_, __) => const CollectionPage()),
        GoRoute(path: '/shared/:token', builder: (_, state) => SharedCollectionPage(token: state.pathParameters['token']!)),
        GoRoute(path: '/wishlist', builder: (_, __) => const WishlistPage()),
        GoRoute(path: '/journal', builder: (_, __) => const JournalPage()),
        GoRoute(
          path: '/perfume/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return PerfumeDetailPage(perfumeId: id);
          },
        ),
        GoRoute(
          path: '/compare',
          builder: (_, state) {
            final perfume1Id = state.uri.queryParameters['perfume1'];
            final perfume2Id = state.uri.queryParameters['perfume2'];
            return ComparePage(perfume1Id: perfume1Id, perfume2Id: perfume2Id);
          },
        ),
        GoRoute(
          path: '/decant-advisor',
          builder: (_, state) {
            final perfumeId = state.uri.queryParameters['perfume_id'];
            return DecantAdvisorPage(perfumeId: perfumeId);
          },
        ),
        GoRoute(path: '/selection-builder', builder: (_, __) => const SelectionBuilderPage()),
      ],
    ),
  ],
);
