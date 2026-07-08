import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/olfato_tokens.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  /// Tab definitions: Home, Explorar, Scan (center elevated), Coleção, Aura.
  /// Profile tab removed — accessed via avatar in Home header.
  static const _tabs = [
    {'path': '/', 'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
    {'path': '/explore', 'icon': Icons.search_rounded, 'activeIcon': Icons.search_rounded, 'label': 'Explorar'},
    {'path': '/scan', 'icon': Icons.crop_free, 'activeIcon': Icons.crop_free, 'label': 'Scan'},
    {'path': '/collection', 'icon': Icons.collections_bookmark_outlined, 'activeIcon': Icons.collections_bookmark, 'label': 'Coleção'},
    {'path': '/chat', 'icon': Icons.auto_awesome_outlined, 'activeIcon': Icons.auto_awesome, 'label': 'Aura'},
  ];

  /// Index of the elevated center Scan tab.
  static const int _scanTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabs.indexWhere((t) => t['path'] == location);
    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (isDesktop) {
      return _DesktopLayout(currentIndex: currentIndex, child: child);
    }
    return _MobileLayout(
      currentIndex: currentIndex,
      child: child,
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const _MobileLayout({
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: OlfatoTokens.borderLight, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(MainShell._tabs.length, (i) {
                final isActive = currentIndex == i;
                final isScanTab = i == MainShell._scanTabIndex;

                if (isScanTab) {
                  return _ElevatedScanTab(
                    isActive: isActive,
                    onTap: () => context.go(
                      MainShell._tabs[i]['path'] as String,
                    ),
                  );
                }

                return _RegularTab(
                  tab: MainShell._tabs[i],
                  isActive: isActive,
                  onTap: () => context.go(
                    MainShell._tabs[i]['path'] as String,
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

/// Regular tab item (Home, Explorar, Coleção, Aura).
class _RegularTab extends StatelessWidget {
  final Map<String, Object> tab;
  final bool isActive;
  final VoidCallback onTap;

  const _RegularTab({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? OlfatoTokens.plum.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                      (isActive ? tab['activeIcon'] : tab['icon']) as IconData,
                      color: isActive ? OlfatoTokens.plum : OlfatoTokens.gray,
                      size: 20,
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              tab['label'] as String,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? OlfatoTokens.plum : OlfatoTokens.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elevated center Scan tab — styled as a raised circular FAB.
class _ElevatedScanTab extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _ElevatedScanTab({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive ? OlfatoTokens.auraGradient : null,
                  color: isActive ? null : OlfatoTokens.plum,
                  boxShadow: [
                    BoxShadow(
                      color: OlfatoTokens.plum.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.crop_free,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -8),
              child: Text(
                'Scan',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? OlfatoTokens.plum : OlfatoTokens.gray,
                ),
              ),
            ),
          ],
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
            color: OlfatoTokens.mist,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Olfato logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    _BrandLogo(),
                  ]),
                ),
                const SizedBox(height: 40),
                // Nav items — same 5 tabs
                ...List.generate(MainShell._tabs.length, (i) {
                  final isActive = currentIndex == i;
                  final isScanTab = i == MainShell._scanTabIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: Material(
                      color: isActive
                          ? OlfatoTokens.plum.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => context.go(
                          MainShell._tabs[i]['path'] as String,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(children: [
                            if (isScanTab)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: OlfatoTokens.plum,
                                ),
                                child: const Icon(
                                  Icons.crop_free,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              )
                            else
                              Icon(
                                (isActive
                                    ? MainShell._tabs[i]['activeIcon']
                                    : MainShell._tabs[i]['icon']) as IconData,
                                color: isActive
                                    ? OlfatoTokens.plum
                                    : OlfatoTokens.gray,
                                size: 20,
                              ),
                            const SizedBox(width: 12),
                            Text(
                              MainShell._tabs[i]['label'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive
                                    ? OlfatoTokens.plum
                                    : OlfatoTokens.gray,
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
          Container(width: 1, color: OlfatoTokens.borderLight),
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

/// Brand logo widget with image fallback.
/// Uses the colorida horizontal logo for clear rendering at sidebar size.
class _BrandLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/olfato_logo_horizontal.png',
      height: 50,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return const Text(
          'OLFATO',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: OlfatoTokens.plum,
          ),
        );
      },
    );
  }
}
