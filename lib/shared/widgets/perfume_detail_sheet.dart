import 'package:flutter/material.dart';
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
      return 'http://localhost:8000/api/image-proxy?url=${Uri.encodeComponent(url)}';
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
          if (price != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.sell_outlined, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text('R\$ ${double.tryParse(price.toString())?.toStringAsFixed(2) ?? price}', style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
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


class _CollectionButton extends StatefulWidget {
  final String perfumeId;
  final String perfumeName;

  const _CollectionButton({required this.perfumeId, required this.perfumeName});

  @override
  State<_CollectionButton> createState() => _CollectionButtonState();
}

class _CollectionButtonState extends State<_CollectionButton> {
  bool _inCollection = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkCollection();
  }

  Future<void> _checkCollection() async {
    try {
      final response = await ApiClient().dio.get('/collection/ids');
      final ids = List<String>.from(response.data as List);
      if (mounted) setState(() {
        _inCollection = ids.contains(widget.perfumeId);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    try {
      await ApiClient().dio.post('/collection', data: {'perfume_id': widget.perfumeId});
      if (mounted) {
        setState(() => _inCollection = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.perfumeName} adicionado!'),
          backgroundColor: AppColors.accent));
      }
    } catch (_) {
      if (mounted) setState(() => _inCollection = true); // probably already there
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

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar à Coleção'),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }
}
