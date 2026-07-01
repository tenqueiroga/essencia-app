import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    {'path': '/', 'icon': Icons.home_rounded, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
    {'path': '/explore', 'icon': Icons.search_rounded, 'activeIcon': Icons.search_rounded, 'label': 'Explorar'},
    {'path': '/collection', 'icon': Icons.favorite_border_rounded, 'activeIcon': Icons.favorite_rounded, 'label': 'Coleção'},
    {'path': '/chat', 'icon': Icons.auto_awesome_outlined, 'activeIcon': Icons.auto_awesome, 'label': 'Essence'},
    {'path': '/profile', 'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Perfil'},
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabs.indexWhere((t) => t['path'] == location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final isActive = currentIndex == i;
                return GestureDetector(
                  onTap: () => context.go(_tabs[i]['path'] as String),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.accentGlow : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            (isActive ? _tabs[i]['activeIcon'] : _tabs[i]['icon']) as IconData,
                            color: isActive ? AppColors.accent : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tabs[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? AppColors.accent : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
