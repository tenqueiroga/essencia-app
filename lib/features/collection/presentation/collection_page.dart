import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/perfume_detail_sheet.dart';

final collectionProvider = FutureProvider.autoDispose((ref) async {
  final response = await ApiClient().dio.get('/collection');
  return response.data['data'] as List<dynamic>;
});

final collectionProfileProvider = FutureProvider.autoDispose((ref) async {
  final response = await ApiClient().dio.get('/collection/profile');
  return response.data as Map<String, dynamic>;
});

class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'http://localhost:8000/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text('Minha Coleção',
                    style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.textMuted, size: 20),
                    onPressed: () {
                      ref.invalidate(collectionProvider);
                      ref.invalidate(collectionProfileProvider);
                    },
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.gold,
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Perfumes'),
                Tab(text: 'Estatísticas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPerfumesList(collectionAsync),
                  _buildStats(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => context.go('/explore'),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }

  Widget _buildPerfumesList(AsyncValue<List<dynamic>> collectionAsync) {
    return collectionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(child: Text('Erro ao carregar', style: TextStyle(color: AppColors.error))),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.collections_bookmark_outlined,
            title: 'Sua coleção está vazia',
            subtitle: 'Busque perfumes na aba Explorar\nou use o Scan para adicionar',
            buttonText: 'Explorar Perfumes',
            onButtonPressed: () => context.go('/explore'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => _CollectionItem(
            item: items[index],
            proxyUrl: _proxyUrl,
            onTap: () => openPerfumeDetailSheet(context, items[index]['perfume']),
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    final profileAsync = ref.watch(collectionProfileProvider);
    final collectionAsync = ref.watch(collectionProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => const Center(child: Text('Erro ao carregar estatísticas')),
      data: (profile) {
        final families = (profile['families'] as List?) ?? [];
        final total = profile['total_perfumes'] ?? 0;

        // Compute extra stats from collection data
        final items = collectionAsync.valueOrNull ?? [];
        final seasonCount = <String, int>{};
        final timeCount = <String, int>{'Dia': 0, 'Noite': 0};
        final genderCount = <String, int>{};

        for (final item in items) {
          final perfume = item['perfume'];
          // Seasons from perfume data
          final sd = perfume?['season_data'] as List?;
          if (sd != null) {
            for (final s in sd) {
              final pct = (s['percentage'] as num?) ?? 0;
              if (pct > 50) {
                seasonCount[s['name']] = (seasonCount[s['name']] ?? 0) + 1;
              }
            }
          }
          // Time of day
          final td = perfume?['time_of_day'] as List?;
          if (td != null) {
            for (final t in td) {
              final pct = (t['percentage'] as num?) ?? 0;
              if (pct > 50) {
                timeCount[t['name']] = (timeCount[t['name']] ?? 0) + 1;
              }
            }
          }
          // Gender
          final g = perfume?['gender'] as String?;
          if (g != null) {
            genderCount[g] = (genderCount[g] ?? 0) + 1;
          }
        }

        if (total == 0) {
          return const EmptyState(
            icon: Icons.bar_chart,
            title: 'Sem dados ainda',
            subtitle: 'Adicione perfumes para ver suas estatísticas',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Total badge
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)),
              child: Text('$total perfumes na coleção',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 24),

            // Family distribution chart
            Text('Famílias Olfativas', style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...families.map<Widget>((f) {
              final pct = (f['percentage'] as num?) ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(width: 80, child: Text(f['family'] ?? '',
                    style: const TextStyle(fontSize: 12))),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                      minHeight: 16),
                  )),
                  const SizedBox(width: 8),
                  SizedBox(width: 40, child: Text('${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
                  SizedBox(width: 20, child: Text('${f['count']}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ]),
              );
            }),
            const SizedBox(height: 24),

            // Time of day
            if (timeCount.values.any((v) => v > 0)) ...[
              Text('Dia vs Noite', style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              GlassCard(child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCircle('🌤️', 'Dia', timeCount['Dia'] ?? 0, total),
                  _StatCircle('🌙', 'Noite', timeCount['Noite'] ?? 0, total),
                ],
              )),
              const SizedBox(height: 24),
            ],

            // Season distribution
            if (seasonCount.isNotEmpty) ...[
              Text('Estações', style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              GlassCard(child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCircle('🌸', 'Primavera', seasonCount['Primavera'] ?? 0, total),
                  _StatCircle('☀️', 'Verão', seasonCount['Verão'] ?? 0, total),
                  _StatCircle('🍂', 'Outono', seasonCount['Outono'] ?? 0, total),
                  _StatCircle('❄️', 'Inverno', seasonCount['Inverno'] ?? 0, total),
                ],
              )),
              const SizedBox(height: 24),
            ],

            // Gender
            if (genderCount.isNotEmpty) ...[
              Text('Gênero', style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              GlassCard(child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: genderCount.entries.map((e) => Column(children: [
                  Text(e.key == 'Feminino' ? '♀' : e.key == 'Masculino' ? '♂' : '⚥',
                    style: const TextStyle(fontSize: 24)),
                  Text('${e.value}', style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.gold)),
                  Text(e.key, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ])).toList(),
              )),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _StatCircle(String emoji, String label, int count, int total) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold, fontSize: 18)),
      Text('$pct%', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }

  void _showDetail(dynamic item) {
    final perfume = item['perfume'];
    final userRating = item['rating'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Header
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 70, height: 90,
                  color: AppColors.surfaceLight,
                  child: _proxyUrl(perfume['image_url']).isNotEmpty
                    ? Image.network(_proxyUrl(perfume['image_url']),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_florist, color: AppColors.gold, size: 28))
                    : const Icon(Icons.local_florist, color: AppColors.gold, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(perfume['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(perfume['brand'] ?? '',
                    style: const TextStyle(color: AppColors.gold)),
                  if (perfume['perfumer'] != null)
                    Text('por ${perfume['perfumer']}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              )),
            ]),
            const SizedBox(height: 20),

            // User rating - tap to rate
            const Text('Sua Avaliação', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: List.generate(5, (i) => GestureDetector(
              onTap: () async {
                await ApiClient().dio.put('/collection/${item['id']}/rating',
                  data: {'rating': i + 1});
                ref.invalidate(collectionProvider);
                if (mounted) Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  i < (userRating ?? 0) ? Icons.star : Icons.star_border,
                  color: AppColors.gold, size: 32),
              ),
            ))),
            const SizedBox(height: 20),

            // Notes preview
            if (perfume['top_notes'] != null && (perfume['top_notes'] as List).isNotEmpty) ...[
              const Text('Notas de Topo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(spacing: 4, runSpacing: 4, children:
                (perfume['top_notes'] as List).take(5).map<Widget>((n) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3))),
                  child: Text(n.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFFFFD700))),
                )).toList()),
              const SizedBox(height: 16),
            ],

            // Actions
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  await ApiClient().dio.delete('/collection/${item['id']}');
                  ref.invalidate(collectionProvider);
                  ref.invalidate(collectionProfileProvider);
                  if (mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remover', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Navigate to explore and search for this perfume
                  context.go('/explore');
                },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Ver Ficha', style: TextStyle(fontSize: 12)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}


class _CollectionItem extends StatelessWidget {
  final dynamic item;
  final String Function(String?) proxyUrl;
  final VoidCallback onTap;

  const _CollectionItem({required this.item, required this.proxyUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final perfume = item['perfume'];
    final userRating = item['rating'] as int?;
    final imageUrl = proxyUrl(perfume?['image_url'] as String?);
    final family = perfume?['olfactory_family']?['name'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 52, height: 66,
                  color: AppColors.surfaceLight,
                  child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_florist, color: AppColors.gold, size: 20))
                    : const Icon(Icons.local_florist, color: AppColors.gold, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(perfume?['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(perfume?['brand'] ?? '',
                    style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    if (userRating != null)
                      ...List.generate(5, (i) => Icon(
                        i < userRating ? Icons.star : Icons.star_border,
                        color: AppColors.gold, size: 13))
                    else
                      const Text('Toque para avaliar', style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10, fontStyle: FontStyle.italic)),
                    const Spacer(),
                    if (family.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4)),
                        child: Text(family,
                          style: const TextStyle(color: AppColors.gold, fontSize: 9)),
                      ),
                  ]),
                ],
              )),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
