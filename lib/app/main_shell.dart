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
    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (isDesktop) {
      return _DesktopLayout(child: child, currentIndex: currentIndex);
    }
    return _MobileLayout(child: child, currentIndex: currentIndex);
  }
}

class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  const _MobileLayout({required this.child, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
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
              children: List.generate(MainShell._tabs.length, (i) {
                final isActive = currentIndex == i;
                return GestureDetector(
                  onTap: () => context.go(MainShell._tabs[i]['path'] as String),
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
                            (isActive ? MainShell._tabs[i]['activeIcon'] : MainShell._tabs[i]['icon']) as IconData,
                            color: isActive ? AppColors.accent : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MainShell._tabs[i]['label'] as String,
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

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  const _DesktopLayout({required this.child, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation
          Container(
            width: 220,
            color: AppColors.surface,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AppColors.accent, AppColors.gold]),
                      ),
                      child: const Center(child: Text('E', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.background))),
                    ),
                    const SizedBox(width: 10),
                    const Text('ESSÊNCIA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ]),
                ),
                const SizedBox(height: 40),
                // Nav items
                ...List.generate(MainShell._tabs.length, (i) {
                  final isActive = currentIndex == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Material(
                      color: isActive ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => context.go(MainShell._tabs[i]['path'] as String),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(children: [
                            Icon(
                              (isActive ? MainShell._tabs[i]['activeIcon'] : MainShell._tabs[i]['icon']) as IconData,
                              color: isActive ? AppColors.accent : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              MainShell._tabs[i]['label'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive ? AppColors.accent : AppColors.textSecondary,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Divider
          Container(width: 1, color: AppColors.border),
          // Content area (constrained width)
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
