import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/theme/olfato_theme.dart';
import 'app/theme/theme_notifier.dart';
import 'app/app_router.dart';
import 'core/network/api_client.dart';

void main() {
  initializeDateFormatting('pt_BR', null).then((_) {
    // Set up auth lost handler — redirect to login when tokens expire
    ApiClient().onAuthLost = () {
      appRouter.go('/login');
    };
    runApp(const ProviderScope(child: PerfumeCollectionApp()));
  });
}

class PerfumeCollectionApp extends ConsumerWidget {
  const PerfumeCollectionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'PerfumIA',
      debugShowCheckedModeBanner: false,
      theme: OlfatoTheme.lightTheme,
      darkTheme: OlfatoTheme.darkTheme,
      themeMode: themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
