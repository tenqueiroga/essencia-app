import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';

// ─── Collection Item Type ─────────────────────────────────────────────────────

enum CollectionItemType { perfume, decant, amostra, jaTive }

extension CollectionItemTypeExt on CollectionItemType {
  String get label => switch (this) {
        CollectionItemType.perfume => 'Perfumes',
        CollectionItemType.decant => 'Decantes',
        CollectionItemType.amostra => 'Amostras',
        CollectionItemType.jaTive => 'Já Tive',
      };

  String get singularLabel => switch (this) {
        CollectionItemType.perfume => 'Perfume',
        CollectionItemType.decant => 'Decante',
        CollectionItemType.amostra => 'Amostra',
        CollectionItemType.jaTive => 'Já Tive',
      };

  String get apiValue => switch (this) {
        CollectionItemType.perfume => 'perfume',
        CollectionItemType.decant => 'decant',
        CollectionItemType.amostra => 'amostra',
        CollectionItemType.jaTive => 'ja_tive',
      };
}

CollectionItemType? parseCollectionItemType(String? value) {
  if (value == null) return null;
  return switch (value) {
    'perfume' => CollectionItemType.perfume,
    'decant' => CollectionItemType.decant,
    'amostra' => CollectionItemType.amostra,
    'ja_tive' => CollectionItemType.jaTive,
    _ => null,
  };
}

// ─── Pure filtering logic (exported for testing) ──────────────────────────────

/// Counts items per type. Returns a map with keys: perfume, decant, amostra, jaTive.
Map<CollectionItemType, int> computeCollectionStats(List<dynamic> items) {
  final counts = {
    CollectionItemType.perfume: 0,
    CollectionItemType.decant: 0,
    CollectionItemType.amostra: 0,
    CollectionItemType.jaTive: 0,
  };
  for (final item in items) {
    final type = parseCollectionItemType(item['type'] as String?) ??
        CollectionItemType.perfume;
    counts[type] = (counts[type] ?? 0) + 1;
  }
  return counts;
}

/// Filters collection items by type and family (AND logic).
/// If typeFilter is null, all types pass. If familyFilter is null/empty, all families pass.
List<dynamic> filterCollectionItems(
  List<dynamic> items, {
  CollectionItemType? typeFilter,
  String? familyFilter,
  String? searchQuery,
}) {
  return items.where((item) {
    // Type filter
    if (typeFilter != null) {
      final itemType = parseCollectionItemType(item['type'] as String?) ??
          CollectionItemType.perfume;
      if (itemType != typeFilter) return false;
    }

    final perfume = item['perfume'] as Map<String, dynamic>?;
    if (perfume == null) return false;

    // Family filter
    if (familyFilter != null && familyFilter.isNotEmpty) {
      final family =
          (perfume['olfactory_family']?['name'] as String?)?.toLowerCase() ?? '';
      if (family != familyFilter.toLowerCase()) return false;
    }

    // Search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final name = (perfume['name'] as String?)?.toLowerCase() ?? '';
      final brand = (perfume['brand'] as String?)?.toLowerCase() ?? '';
      if (!name.contains(query) && !brand.contains(query)) return false;
    }

    return true;
  }).toList();
}

/// Extracts unique olfactory families from collection items.
List<String> extractFamilies(List<dynamic> items) {
  final families = <String>{};
  for (final item in items) {
    final perfume = item['perfume'] as Map<String, dynamic>?;
    final family = perfume?['olfactory_family']?['name'] as String?;
    if (family != null && family.isNotEmpty) {
      families.add(family);
    }
  }
  final sorted = families.toList()..sort();
  return sorted;
}

// ─── Providers ────────────────────────────────────────────────────────────────

final collectionProvider = FutureProvider.autoDispose((ref) async {
  final response = await ApiClient().dio.get('/collection');
  return response.data['data'] as List<dynamic>;
});

// ─── CollectionPage ───────────────────────────────────────────────────────────

class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  CollectionItemType? _selectedType; // null = "Todos"
  String? _selectedFamily;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'https://essencia.laravel.cloud/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);

    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      body: SafeArea(
        child: collectionAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: OlfatoTokens.plum),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: OlfatoTokens.error, size: 48),
                const SizedBox(height: 12),
                Text('Erro ao carregar coleção',
                    style: GoogleFonts.inter(color: OlfatoTokens.gray)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(collectionProvider),
                  child: Text('Tentar novamente',
                      style: GoogleFonts.inter(color: OlfatoTokens.plum)),
                ),
              ],
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _buildEmptyState();
            }
            return _buildContent(items);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_outlined,
                size: 80, color: OlfatoTokens.plum.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(
              'Sua coleção está vazia',
              style: GoogleFonts.ebGaramond(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: OlfatoTokens.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Comece adicionando seus perfumes favoritos.\n'
              'Explore, escaneie ou busque para começar!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: OlfatoTokens.gray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.search, size: 18),
              label: Text('Explorar Perfumes',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: OlfatoTokens.plum,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(OlfatoTokens.radiusControl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<dynamic> items) {
    final stats = computeCollectionStats(items);
    final families = extractFamilies(items);
    final filteredItems = filterCollectionItems(
      items,
      typeFilter: _selectedType,
      familyFilter: _selectedFamily,
      searchQuery: _searchQuery,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + Wishlist + Refresh
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Text(
                'Minha Coleção',
                style: GoogleFonts.ebGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: OlfatoTokens.ink,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: OlfatoTokens.gray, size: 20),
                onPressed: () {
                  Share.share('🧴 Confira minha coleção de perfumes no Olfato!\nhttps://essencia.laravel.cloud/app/collection');
                },
              ),
              _WishlistButton(onTap: () => context.push('/wishlist')),
            ],
          ),
        ),

        // Stats bar
        _CollectionStatsBar(stats: stats),

        // Search input
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.ink),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou marca...',
              hintStyle: GoogleFonts.inter(
                  fontSize: 14, color: OlfatoTokens.gray),
              prefixIcon:
                  const Icon(Icons.search, color: OlfatoTokens.gray, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: OlfatoTokens.gray, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: OlfatoTokens.mist,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(OlfatoTokens.radiusControl),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Type filter tabs
        const SizedBox(height: 16),
        _TypeFilterTabs(
          selected: _selectedType,
          onSelected: (type) => setState(() => _selectedType = type),
        ),

        // Family filter chips
        if (families.isNotEmpty) ...[
          const SizedBox(height: 12),
          _FamilyFilterChips(
            families: families,
            selected: _selectedFamily,
            onSelected: (family) => setState(() => _selectedFamily = family),
          ),
        ],

        // Grid content
        const SizedBox(height: 16),
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list_off,
                          size: 48,
                          color: OlfatoTokens.gray.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum item encontrado',
                        style: GoogleFonts.inter(
                            color: OlfatoTokens.gray, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : _CollectionGrid(
                  items: filteredItems,
                  proxyUrl: _proxyUrl,
                  onItemTap: (item) =>
                      context.push('/perfume/${item['perfume']['id']}'),
                ),
        ),
      ],
    );
  }
}

// ─── CollectionStatsBar ───────────────────────────────────────────────────────

class _CollectionStatsBar extends StatelessWidget {
  final Map<CollectionItemType, int> stats;
  const _CollectionStatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final perfumes = stats[CollectionItemType.perfume] ?? 0;
    final decants = stats[CollectionItemType.decant] ?? 0;
    final amostras = stats[CollectionItemType.amostra] ?? 0;
    final jaTive = stats[CollectionItemType.jaTive] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(count: perfumes, label: 'Perfumes'),
            _divider(),
            _StatItem(count: decants, label: 'Decantes'),
            _divider(),
            _StatItem(count: amostras, label: 'Amostras'),
            _divider(),
            _StatItem(count: jaTive, label: 'Já Tive'),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: OlfatoTokens.gray.withValues(alpha: 0.2),
      );
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: GoogleFonts.ebGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: OlfatoTokens.plum,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: OlfatoTokens.gray,
          ),
        ),
      ],
    );
  }
}

// ─── TypeFilterTabs ───────────────────────────────────────────────────────────

class _TypeFilterTabs extends StatelessWidget {
  final CollectionItemType? selected;
  final ValueChanged<CollectionItemType?> onSelected;

  const _TypeFilterTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (null, 'Todos'),
      (CollectionItemType.perfume, 'Perfumes'),
      (CollectionItemType.decant, 'Decantes'),
      (CollectionItemType.amostra, 'Amostras'),
      (CollectionItemType.jaTive, 'Já Tive'),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (type, label) = tabs[index];
          final isActive = selected == type;

          return GestureDetector(
            onTap: () => onSelected(type),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? OlfatoTokens.plum : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(OlfatoTokens.radiusControl),
                border: Border.all(
                  color: isActive
                      ? OlfatoTokens.plum
                      : OlfatoTokens.gray.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : OlfatoTokens.gray,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── FamilyFilterChips ────────────────────────────────────────────────────────

class _FamilyFilterChips extends StatelessWidget {
  final List<String> families;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FamilyFilterChips({
    required this.families,
    required this.selected,
    required this.onSelected,
  });

  IconData _familyIcon(String family) {
    final lower = family.toLowerCase();
    if (lower.contains('floral')) return Icons.local_florist;
    if (lower.contains('oriental')) return Icons.auto_awesome;
    if (lower.contains('amadeirad')) return Icons.park;
    if (lower.contains('cítric')) return Icons.wb_sunny;
    if (lower.contains('aquátic') || lower.contains('fresh')) return Icons.water_drop;
    if (lower.contains('aromátic')) return Icons.spa;
    if (lower.contains('gourmand')) return Icons.cookie;
    if (lower.contains('frut')) return Icons.apple;
    if (lower.contains('chipre') || lower.contains('chypre')) return Icons.eco;
    return Icons.blur_circular;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: families.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final family = families[index];
          final isActive = selected == family;

          return GestureDetector(
            onTap: () => onSelected(isActive ? null : family),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? OlfatoTokens.plum.withValues(alpha: 0.12)
                    : OlfatoTokens.mist,
                borderRadius:
                    BorderRadius.circular(OlfatoTokens.radiusControl),
                border: Border.all(
                  color: isActive
                      ? OlfatoTokens.plum
                      : OlfatoTokens.borderLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _familyIcon(family),
                    size: 14,
                    color: isActive ? OlfatoTokens.plum : OlfatoTokens.gray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    family,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isActive ? OlfatoTokens.plum : OlfatoTokens.gray,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── CollectionGrid ───────────────────────────────────────────────────────────

class _CollectionGrid extends StatelessWidget {
  final List<dynamic> items;
  final String Function(String?) proxyUrl;
  final ValueChanged<dynamic> onItemTap;

  const _CollectionGrid({
    required this.items,
    required this.proxyUrl,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _CollectionGridItem(
          item: item,
          proxyUrl: proxyUrl,
          onTap: () => onItemTap(item),
        );
      },
    );
  }
}

// ─── CollectionGridItem ───────────────────────────────────────────────────────

class _CollectionGridItem extends StatelessWidget {
  final dynamic item;
  final String Function(String?) proxyUrl;
  final VoidCallback onTap;

  const _CollectionGridItem({
    required this.item,
    required this.proxyUrl,
    required this.onTap,
  });

  String _seasonLabel(Map<String, dynamic>? perfume) {
    final seasonData = perfume?['season_data'] as List?;
    if (seasonData == null || seasonData.isEmpty) return '';
    // Find the season with highest percentage
    String best = '';
    num bestPct = 0;
    for (final s in seasonData) {
      final pct = (s['percentage'] as num?) ?? 0;
      if (pct > bestPct) {
        bestPct = pct;
        best = s['name'] as String? ?? '';
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final perfume = item['perfume'] as Map<String, dynamic>?;
    final imageUrl = proxyUrl(perfume?['image_url'] as String?);
    final name = perfume?['name'] as String? ?? '';
    final brand = perfume?['brand'] as String? ?? '';
    final family = perfume?['olfactory_family']?['name'] as String? ?? '';
    final volume = perfume?['volume'] as String? ?? '';
    final season = _seasonLabel(perfume);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          boxShadow: [OlfatoTokens.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(OlfatoTokens.radiusCard),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(OlfatoTokens.radiusCard),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.local_florist,
                                color: OlfatoTokens.plum, size: 28),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.local_florist,
                              color: OlfatoTokens.plum, size: 28),
                        ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OlfatoTokens.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      brand,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: OlfatoTokens.plum,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Volume + Family + Season row
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        if (volume.isNotEmpty)
                          _miniChip(volume),
                        if (family.isNotEmpty)
                          _miniChip(family),
                        if (season.isNotEmpty)
                          _miniChip(season),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: OlfatoTokens.plum.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          color: OlfatoTokens.gray,
        ),
      ),
    );
  }
}


// ─── Wishlist Button ──────────────────────────────────────────────────────────

class _WishlistButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WishlistButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ver Wishlist',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.favorite_border_rounded,
              color: OlfatoTokens.pitanga,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
