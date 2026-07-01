import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/theme/app_theme.dart';
import 'app/app_router.dart';

void main() {
  initializeDateFormatting('pt_BR', null).then((_) {
    runApp(const ProviderScope(child: PerfumeCollectionApp()));
  });
}

class PerfumeCollectionApp extends StatelessWidget {
  const PerfumeCollectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Perfume Collection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
