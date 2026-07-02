import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import 'glass_card.dart';
import 'perfume_pyramid.dart';

/// Opens the full perfume detail sheet from any page.
/// Pass a perfume map (from API) with at least 'id'.
/// If data is incomplete, fetches full data from API.
Future<void> openPerfumeDetailSheet(BuildContext context, dynamic perfume, {VoidCallback? onAdded}) async {
  // If we don't have full data, fetch it
  Map<String, dynamic> p;
  if (perfume is Map<String, dynamic> && perfume.containsKey('top_notes') && perfume['top_notes'] != null) {
    p = perfume;
  } else {
    try {
      final response = await ApiClient().dio.get('/perfumes/${perfume['id']}');
      p = response.data as Map<String, dynamic>;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao carregar perfume'), backgroundColor: AppColors.error));
      }
      return;
    }
  }

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => _FullPerfumeDetail(perfume: p, scrollController: scroll, onAdded: onAdded),
    ),
  );
}

class _FullPerfumeDetail extends StatelessWidget {
  final Map<String, dynamic> perfume;
  final ScrollController scrollController;
  final VoidCallback? onAdded;

  const _FullPerfumeDetail({required this.perfume, required this.scrollController, this.onAdded});

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'https://essencia.laravel.cloud/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _proxyUrl(perfume['image_url'] as String?);
    final topNotes = perfume['top_notes'] as List? ?? [];
    final heartNotes = perfume['heart_notes'] as List? ?? [];
    final baseNotes = perfume['base_notes'] as List? ?? [];
    final family = perfume['olfactory_family']?['name'] ?? '';
    final familyColor = perfume['olfactory_family']?['color_hex'];
    final price = perfume['average_price'];
    final rating = perfume['rating'];
    final ratingCount = perfume['rating_count'];
    final gender = perfume['gender'] as String?;
    final perfumer = perfume['perfumer'] as String?;
    final seasonData = perfume['season_data'] as List?;
    final timeOfDay = perfume['time_of_day'] as List?;
    final accordsData = perfume['accords_data'] as List?;
    final longevityData = perfume['longevity_data'] as List?;
    final sillageData = perfume['sillage_data'] as List?;
    final collectionName = perfume['collection_name'] as String?;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Image
          Container(
            width: 140, height: 180,
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.glassBorder)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
            ),
          ),
          const SizedBox(height: 16),

          // Name & brand
          Text(perfume['name'] ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(perfume['brand'] ?? '', style: const TextStyle(color: AppColors.gold, fontSize: 16)),
          if (perfumer != null && perfumer.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('por $perfumer', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),

          // Rating
          if (rating != null)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...List.generate(5, (i) => Icon(i < (double.tryParse(rating.toString()) ?? 0).round() ? Icons.star : Icons.star_border, color: AppColors.gold, size: 20)),
              const SizedBox(width: 6),
              Text('${double.tryParse(rating.toString())?.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              if (ratingCount != null) Text(' ($ratingCount)', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
          const SizedBox(height: 12),

          // Chips
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
            if (perfume['concentration'] != null) _chip(perfume['concentration']),
            if (perfume['year_launched'] != null) _chip('${perfume['year_launched']}'),
            if (family.isNotEmpty) _chip(family, color: _parseColor(familyColor)),
            if (gender != null) _chip(gender),
            if (collectionName != null && collectionName.isNotEmpty) _chip('Linha: $collectionName', color: Colors.purple),
          ]),

          // Price
          if (price != null || (perfume['prices'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _PriceSection(perfume: perfume),
          ],
          const SizedBox(height: 28),

          // Pyramid
          if (topNotes.isNotEmpty || heartNotes.isNotEmpty || baseNotes.isNotEmpty) ...[
            const Text('PIRÂMIDE OLFATIVA', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 12),
            PerfumePyramid(topNotes: topNotes, heartNotes: heartNotes, baseNotes: baseNotes),
            const SizedBox(height: 24),
          ],

          // Accords
          if (accordsData != null && accordsData.isNotEmpty) ...[
            Align(alignment: Alignment.centerLeft, child: Text('Acordes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            ...accordsData.take(6).map<Widget>((a) {
              final pct = (a['percentage'] as num?) ?? 0;
              final color = _parseColor(a['color'] as String?);
              return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
                SizedBox(width: 90, child: Text(a['name_pt'] ?? a['name_en'] ?? '', style: const TextStyle(fontSize: 12))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct / 100, backgroundColor: AppColors.surfaceLight, valueColor: AlwaysStoppedAnimation(color), minHeight: 8))),
                const SizedBox(width: 8),
                Text('$pct%', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]));
            }),
            const SizedBox(height: 20),
          ],

          // Performance
          if (longevityData != null && longevityData.isNotEmpty) ...[
            Align(alignment: Alignment.centerLeft, child: Text('Performance', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            const Text('⏱ Longevidade', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            _voteChart(longevityData, const Color(0xFF4CAF50)),
            const SizedBox(height: 10),
          ],
          if (sillageData != null && sillageData.isNotEmpty) ...[
            const Text('📡 Projeção', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            _voteChart(sillageData, const Color(0xFF2196F3)),
            const SizedBox(height: 20),
          ],

          // Seasons
          if (seasonData != null && seasonData.isNotEmpty) ...[
            Align(alignment: Alignment.centerLeft, child: Text('Quando Usar', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Row(children: seasonData.map<Widget>((s) {
              final icon = switch (s['name']) { 'Inverno' => '❄️', 'Verão' => '☀️', 'Primavera' => '🌸', 'Outono' => '🍂', _ => '📅' };
              final pct = (s['percentage'] as num?) ?? 0;
              return Expanded(child: Column(children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                Text(s['name'] ?? '', style: const TextStyle(fontSize: 10)),
                Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: pct > 50 ? AppColors.gold : AppColors.textMuted, fontWeight: pct > 50 ? FontWeight.bold : FontWeight.normal)),
              ]));
            }).toList()),
            if (timeOfDay != null && timeOfDay.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: timeOfDay.map<Widget>((t) {
                final icon = t['name'] == 'Dia' ? '🌤️' : '🌙';
                final pct = (t['percentage'] as num?) ?? 0;
                return Expanded(child: Column(children: [Text(icon, style: const TextStyle(fontSize: 18)), Text('${t['name']} ${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: pct > 50 ? AppColors.gold : AppColors.textMuted))]));
              }).toList()),
            ],
            const SizedBox(height: 24),
          ],

          // Add to collection (check if already in collection)
          _CollectionButton(perfumeId: perfume['id'] as String, perfumeName: perfume['name'] as String? ?? ''),
          const SizedBox(height: 12),

          // Similar perfumes button
          _SimilarButtonShared(perfumeId: perfume['id'] as String, perfumeName: perfume['name'] as String? ?? ''),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _placeholder() => const Center(child: Icon(Icons.local_florist, color: AppColors.gold, size: 40));

  Widget _chip(String text, {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(text, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
    );
  }

  Widget _voteChart(List<dynamic> data, Color color) {
    final sorted = List<Map<String, dynamic>>.from(data.map((d) => Map<String, dynamic>.from(d as Map)));
    sorted.sort((a, b) => ((b['percentage'] as num?) ?? 0).compareTo((a['percentage'] as num?) ?? 0));
    final maxPct = sorted.isNotEmpty ? (sorted.first['percentage'] as num?) ?? 1 : 1;
    return Column(children: sorted.map<Widget>((item) {
      final pct = (item['percentage'] as num?) ?? 0;
      final isTop = pct == maxPct;
      return Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(children: [
        SizedBox(width: 75, child: Text(item['name'] ?? '', style: TextStyle(fontSize: 11, fontWeight: isTop ? FontWeight.bold : FontWeight.normal, color: isTop ? color : AppColors.textSecondary))),
        Expanded(child: Stack(children: [
          Container(height: 16, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(3))),
          FractionallySizedBox(widthFactor: pct / 100, child: Container(height: 16, decoration: BoxDecoration(color: color.withValues(alpha: isTop ? 0.7 : 0.3), borderRadius: BorderRadius.circular(3)))),
        ])),
        const SizedBox(width: 6),
        SizedBox(width: 32, child: Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: isTop ? color : AppColors.textMuted), textAlign: TextAlign.right)),
      ]));
    }).toList());
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.gold;
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return AppColors.gold; }
  }
}


class _PriceSection extends StatelessWidget {
  final Map<String, dynamic> perfume;
  const _PriceSection({required this.perfume});

  String _sourceLabel(String source) {
    return switch (source) {
      'mercadolivre' => 'Mercado Livre',
      'epoca' => 'Época Cosméticos',
      'belezanaweb' => 'Beleza na Web',
      'sephora' => 'Sephora',
      _ => source,
    };
  }

  String _sourceIcon(String source) {
    return switch (source) {
      'mercadolivre' => '🟡',
      'epoca' => '🟣',
      'sephora' => '⚫',
      'belezanaweb' => '🔵',
      _ => '🏷️',
    };
  }

  @override
  Widget build(BuildContext context) {
    final prices = (perfume['prices'] as List?)
        ?.map((p) => Map<String, dynamic>.from(p as Map))
        .toList() ?? [];
    final averagePrice = perfume['average_price'];

    // If no detailed prices, show average
    if (prices.isEmpty && averagePrice != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sell_outlined, color: Colors.green, size: 16),
          const SizedBox(width: 6),
          Text('R\$ ${double.tryParse(averagePrice.toString())?.toStringAsFixed(2) ?? averagePrice}',
            style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      );
    }

    // Show all prices from different sources
    prices.sort((a, b) => ((a['price'] as num?) ?? 999999).compareTo((b['price'] as num?) ?? 999999));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ONDE COMPRAR', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        ...prices.map((p) {
          final price = (p['price'] as num?)?.toDouble();
          final source = p['source'] as String? ?? '';
          final url = p['url'] as String?;
          final isLowest = prices.indexOf(p) == 0 && prices.length > 1;

          return GestureDetector(
            onTap: url != null ? () => _openUrl(url) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isLowest ? Colors.green.withValues(alpha: 0.08) : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLowest ? Colors.green.withValues(alpha: 0.3) : AppColors.glassBorder),
              ),
              child: Row(children: [
                Text(_sourceIcon(source), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_sourceLabel(source),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      if (isLowest)
                        const Text('Menor preço', style: TextStyle(fontSize: 9, color: Colors.green)),
                    ],
                  ),
                ),
                Text(
                  price != null ? 'R\$ ${price.toStringAsFixed(2)}' : '—',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isLowest ? Colors.green : AppColors.textPrimary),
                ),
                if (url != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.open_in_new, size: 12, color: AppColors.textMuted),
                ],
              ]),
            ),
          );
        }),
      ],
    );
  }

  void _openUrl(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _CollectionButton extends StatefulWidget {
  final String perfumeId;
  final String perfumeName;

  const _CollectionButton({required this.perfumeId, required this.perfumeName});

  @override
  State<_CollectionButton> createState() => _CollectionButtonState();
}

class _CollectionButtonState extends State<_CollectionButton> {
  bool _inCollection = false;
  bool _inWishlist = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('/collection/ids'),
        ApiClient().dio.get('/wishlist/ids'),
      ]);
      final collectionIds = List<String>.from(responses[0].data as List);
      final wishlistIds = List<String>.from(responses[1].data as List);
      if (mounted) setState(() {
        _inCollection = collectionIds.contains(widget.perfumeId);
        _inWishlist = wishlistIds.contains(widget.perfumeId);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToCollection() async {
    try {
      await ApiClient().dio.post('/collection', data: {'perfume_id': widget.perfumeId});
      if (mounted) {
        setState(() => _inCollection = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.perfumeName} adicionado à coleção!'),
          backgroundColor: AppColors.accent));
      }
    } catch (_) {
      if (mounted) setState(() => _inCollection = true);
    }
  }

  Future<void> _addToWishlist() async {
    try {
      await ApiClient().dio.post('/wishlist', data: {'perfume_id': widget.perfumeId});
      if (mounted) {
        setState(() => _inWishlist = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.perfumeName} adicionado à lista de desejos!'),
          backgroundColor: AppColors.gold));
      }
    } catch (_) {
      if (mounted) setState(() => _inWishlist = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 48);
    }

    if (_inCollection) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text('Na sua coleção', style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Add to collection button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addToCollection,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar à Coleção'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(height: 10),
        // Add to wishlist button
        if (!_inWishlist)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addToWishlist,
              icon: const Icon(Icons.favorite_border, size: 18),
              label: const Text('Lista de Desejos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3))),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: AppColors.gold, size: 16),
                  SizedBox(width: 8),
                  Text('Na lista de desejos', style: TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}


class _SimilarButtonShared extends StatefulWidget {
  final String perfumeId;
  final String perfumeName;

  const _SimilarButtonShared({required this.perfumeId, required this.perfumeName});

  @override
  State<_SimilarButtonShared> createState() => _SimilarButtonSharedState();
}

class _SimilarButtonSharedState extends State<_SimilarButtonShared> {
  bool _loading = false;

  Future<void> _openSimilar() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('/perfumes/${widget.perfumeId}/similar'),
        ApiClient().dio.get('/collection/ids'),
      ]);
      final results = responses[0].data as List<dynamic>;
      final collectionIds = List<String>.from(responses[1].data as List);

      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _SimilarPage(
          perfumeName: widget.perfumeName,
          results: results,
          collectionIds: collectionIds,
        ),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao buscar similares'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _openSimilar,
        icon: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
          : const Icon(Icons.compare_arrows),
        label: Text(_loading ? 'Buscando...' : 'Ver Similares'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.glassBorder),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}

class _SimilarPage extends StatelessWidget {
  final String perfumeName;
  final List<dynamic> results;
  final List<String> collectionIds;

  const _SimilarPage({required this.perfumeName, required this.results, required this.collectionIds});

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) return 'https://essencia.laravel.cloud/api/image-proxy?url=${Uri.encodeComponent(url)}';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Similares a $perfumeName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
      ),
      body: results.isEmpty
        ? const Center(child: Text('Nenhum similar encontrado', style: TextStyle(color: AppColors.textMuted)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final s = results[index];
              final inCollection = collectionIds.contains(s['id']);
              final imageUrl = _proxyUrl(s['image_url'] as String?);

              return GestureDetector(
                onTap: () => openPerfumeDetailSheet(context, s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: inCollection ? Border.all(color: AppColors.gold, width: 1.5) : Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 50, height: 64, color: AppColors.surfaceLight,
                        child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_florist, color: AppColors.gold, size: 18))
                          : const Icon(Icons.local_florist, color: AppColors.gold, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(s['brand'] ?? '', style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                      if (s['olfactory_family']?['name'] != null)
                        Text(s['olfactory_family']['name'], style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ])),
                    if (inCollection)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Na coleção', style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
                  ]),
                ),
              );
            },
          ),
    );
  }
}
