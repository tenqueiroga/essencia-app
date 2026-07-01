import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/collection/presentation/collection_page.dart';
import '../features/explore/presentation/explore_page.dart';
import '../features/scan/presentation/scan_page.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/journal/presentation/journal_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
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
        GoRoute(path: '/explore', builder: (_, __) => const ExplorePage()),
        GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
        GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        GoRoute(path: '/collection', builder: (_, __) => const CollectionPage()),
        GoRoute(path: '/journal', builder: (_, __) => const JournalPage()),
      ],
    ),
  ],
);
