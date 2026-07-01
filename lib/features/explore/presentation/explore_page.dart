import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/perfume_detail_sheet.dart';
import '../../../shared/widgets/perfume_pyramid.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

final _collectionIdsProvider = FutureProvider.autoDispose((ref) async {
  final response = await ApiClient().dio.get('/collection/ids');
  return List<String>.from(response.data as List);
});

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _exploreData;

  @override
  void initState() {
    super.initState();
    _loadExploreData();
  }

  Future<void> _loadExploreData() async {
    try {
      final response = await ApiClient().dio.get('/perfumes/explore');
      if (mounted) setState(() => _exploreData = response.data);
    } catch (_) {}
  }

  Future<void> _smartSearch(String query) async {
    if (query.length < 2) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }

    // Detect if it's a barcode (all digits, 8-14 chars)
    final isBarcode = RegExp(r'^\d{8,14}$').hasMatch(query.trim());

    if (isBarcode) {
      setState(() => _isSearching = true);
      try {
        final response = await ApiClient().dio.get('/perfumes/barcode/${query.trim()}');
        if (mounted) setState(() {
          _searchResults = [response.data];
          _isSearching = false;
        });
      } catch (_) {
        if (mounted) setState(() { _searchResults = []; _isSearching = false; });
      }
      return;
    }

    // Text search
    setState(() => _isSearching = true);
    try {
      final response = await ApiClient().dio.get('/perfumes/search', queryParameters: {'q': query});
      if (mounted) setState(() {
        _searchResults = response.data as List<dynamic>;
        _isSearching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchBarcode() async {
    final code = _searchController.text.trim();
    if (code.isEmpty) return;
    _smartSearch(code);
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Identificar Perfume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tire uma foto do frasco ou caixa e nossa IA identifica pra você',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // Photo identify button (primary)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(ctx); _identifyByPhoto(); },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar Foto'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Gallery option
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(ctx); _identifyFromGallery(); },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Escolher da Galeria'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Barcode option (secondary)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () { Navigator.pop(ctx); _openBarcodeScanner(); },
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Escanear Código de Barras'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _identifyByPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 85);
    if (image == null) return;
    await _sendImageForIdentification(image);
  }

  Future<void> _identifyFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (image == null) return;
    await _sendImageForIdentification(image);
  }

  Future<void> _sendImageForIdentification(XFile image) async {
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: Text('Identificando perfume...',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );

    try {
      final bytes = await File(image.path).readAsBytes();
      final base64 = base64Encode(bytes);

      final response = await ApiClient().dio.post('/perfumes/identify', data: {
        'image': base64,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final data = response.data as Map<String, dynamic>;
      if (data['identified'] == true && data['perfume'] != null) {
        openPerfumeDetailSheet(context, data['perfume']);
      } else {
        final msg = data['message'] as String? ?? 'Perfume não identificado';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.elevated,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro ao identificar. Tente novamente.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _openBarcodeScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('Escanear Código', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            Expanded(
              child: MobileScanner(
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: AppColors.textMuted, size: 48),
                          const SizedBox(height: 16),
                          const Text('Câmera indisponível',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Verifique se a permissão de câmera está habilitada.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    final code = barcodes.first.rawValue!;
                    Navigator.pop(ctx);
                    _handleBarcodeResult(code);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Aponte a câmera para o código de barras',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBarcodeResult(String code) async {
    try {
      final response = await ApiClient().dio.get('/perfumes/barcode/$code');
      if (mounted) _showPerfumeDetail(response.data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Perfume não encontrado para código: $code'),
          backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explorar',
                    style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nome, marca ou código de barras...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() { _searchResults = []; });
                              }),
                          IconButton(
                            icon: const Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.gold),
                            tooltip: 'Identificar perfume',
                            onPressed: _openScanner,
                          ),
                        ],
                      ),
                    ),
                    onChanged: _smartSearch,
                    onSubmitted: _smartSearch,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isSearching
                ? const Center(child: CircularProgressIndicator(
                    color: AppColors.gold))
                : _searchResults.isNotEmpty
                  ? _buildSearchResults()
                  : _buildExploreContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final collectionIds = ref.watch(_collectionIdsProvider).valueOrNull ?? [];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final p = _searchResults[index];
        final inCollection = collectionIds.contains(p['id']);
        return _PerfumeCard(
          perfume: p,
          inCollection: inCollection,
          onTap: () => _showPerfumeDetail(p),
          onAdd: () { _addToCollection(p); ref.invalidate(_collectionIdsProvider); },
        );
      },
    );
  }

  Widget _buildExploreContent() {
    final families = (_exploreData?['families'] as List?) ?? [];
    final latest = (_exploreData?['latest'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        Text('Famílias Olfativas',
          style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: families.map<Widget>((f) => ActionChip(
            avatar: CircleAvatar(
              backgroundColor: AppColors.gold, radius: 8),
            label: Text('${f['name']} (${f['perfumes_count']})'),
            backgroundColor: AppColors.surfaceLight,
            side: const BorderSide(color: AppColors.glassBorder),
            onPressed: () {
              _searchController.text = f['name'];
              _smartSearch(f['name']);
            },
          )).toList(),
        ),
        const SizedBox(height: 24),
        Text('Destaques',
          style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...latest.map<Widget>((p) => _PerfumeCard(
          perfume: p,
          inCollection: (ref.watch(_collectionIdsProvider).valueOrNull ?? []).contains(p['id']),
          onTap: () => _showPerfumeDetail(p),
          onAdd: () { _addToCollection(p); ref.invalidate(_collectionIdsProvider); },
        )),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showPerfumeDetail(dynamic perfume) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => _PerfumeDetailSheet(
          perfume: perfume,
          scrollController: scroll,
          onAdd: () { _addToCollection(perfume); Navigator.pop(ctx); },
        ),
      ),
    );
  }

  Future<void> _addToCollection(dynamic perfume) async {
    try {
      await ApiClient().dio.post('/collection',
        data: {'perfume_id': perfume['id']});
      ref.invalidate(_collectionIdsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${perfume['name']} adicionado à coleção!'),
          backgroundColor: AppColors.gold));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perfume já está na coleção'),
          backgroundColor: AppColors.error));
      }
    }
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
}

// --- Perfume Card Widget ---
class _PerfumeCard extends StatelessWidget {
  final dynamic perfume;
  final bool inCollection;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _PerfumeCard({required this.perfume, this.inCollection = false,
    required this.onTap, required this.onAdd});

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'https://essencia.laravel.cloud/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final topNotes = (perfume['top_notes'] as List?)?.take(3).join(', ') ?? '';
    final family = perfume['olfactory_family']?['name'] ?? '';
    final imageUrl = _proxyUrl(perfume['image_url'] as String?);
    final rating = perfume['rating'];
    final gender = perfume['gender'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: inCollection ? BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ) : null,
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 64, height: 80,
                  color: AppColors.surfaceLight,
                  child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.local_florist,
                            color: AppColors.gold, size: 24)))
                    : const Center(child: Icon(Icons.local_florist,
                        color: AppColors.gold, size: 24)),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(perfume['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(perfume['brand'] ?? '',
                      style: const TextStyle(color: AppColors.gold,
                        fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (family.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4)),
                          child: Text(family,
                            style: const TextStyle(color: AppColors.gold,
                              fontSize: 10)),
                        ),
                      if (gender != null) ...[
                        const SizedBox(width: 6),
                        Text(gender == 'Feminino' ? '♀' : gender == 'Masculino' ? '♂' : '⚥',
                          style: const TextStyle(fontSize: 12)),
                      ],
                      if (rating != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: AppColors.gold, size: 12),
                        Text(' ${double.tryParse(rating.toString())?.toStringAsFixed(1) ?? rating}',
                          style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                      ],
                      if (inCollection) ...[
                        const Spacer(),
                        const Icon(Icons.check_circle, color: AppColors.gold, size: 16),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    if (topNotes.isNotEmpty)
                      Text('♦ $topNotes',
                        style: const TextStyle(color: AppColors.textSecondary,
                          fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Add button
              if (!inCollection)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.gold, size: 28),
                  onPressed: onAdd,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Perfume Detail Bottom Sheet ---
class _PerfumeDetailSheet extends StatelessWidget {
  final dynamic perfume;
  final ScrollController scrollController;
  final VoidCallback onAdd;

  const _PerfumeDetailSheet({required this.perfume,
    required this.scrollController, required this.onAdd});

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
          // Handle
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Perfume image
          Container(
            width: 140, height: 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildPlaceholder())
                : _buildPlaceholder(),
            ),
          ),
          const SizedBox(height: 16),

          // Name & brand
          Text(perfume['name'] ?? '',
            style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(perfume['brand'] ?? '',
            style: const TextStyle(color: AppColors.gold, fontSize: 16)),

          // Perfumer
          if (perfumer != null && perfumer.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('por $perfumer',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12,
                fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),

          // Rating
          if (rating != null) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...List.generate(5, (i) {
                final r = double.tryParse(rating.toString()) ?? 0;
                return Icon(
                  i < r.round() ? Icons.star : Icons.star_border,
                  color: AppColors.gold, size: 20);
              }),
              const SizedBox(width: 6),
              Text('${double.tryParse(rating.toString())?.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              if (ratingCount != null)
                Text(' ($ratingCount votos)',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
          ],

          // Info chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8, runSpacing: 6,
            children: [
              if (perfume['concentration'] != null)
                _InfoChip(perfume['concentration']),
              if (perfume['year_launched'] != null)
                _InfoChip('${perfume['year_launched']}'),
              if (family.isNotEmpty)
                _InfoChip(family, color: _parseColor(familyColor)),
              if (gender != null)
                _InfoChip(gender),
              if (collectionName != null && collectionName.isNotEmpty)
                _InfoChip('Linha: $collectionName', color: Colors.purple),
            ],
          ),

          // Price
          if (price != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sell_outlined, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text('R\$ ${double.tryParse(price.toString())?.toStringAsFixed(2) ?? price}',
                    style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Pyramid
          if (topNotes.isNotEmpty || heartNotes.isNotEmpty || baseNotes.isNotEmpty) ...[
            Text('PIRÂMIDE OLFATIVA',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted,
                fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 12),
            PerfumePyramid(
              topNotes: topNotes,
              heartNotes: heartNotes,
              baseNotes: baseNotes,
            ),
            const SizedBox(height: 24),
          ],

          // Accords
          if (accordsData != null && accordsData.isNotEmpty) ...[
            Align(alignment: Alignment.centerLeft,
              child: Text('Acordes',
                style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            ...accordsData.take(6).map<Widget>((a) {
              final pct = (a['percentage'] as num?) ?? 0;
              final color = _parseColor(a['color'] as String?);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(width: 90, child: Text(
                    a['name_pt'] ?? a['name_en'] ?? '',
                    style: const TextStyle(fontSize: 12))),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8),
                  )),
                  const SizedBox(width: 8),
                  Text('$pct%', style: const TextStyle(fontSize: 11,
                    color: AppColors.textMuted)),
                ]),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Performance - Detailed Charts
          if (longevityData != null || sillageData != null) ...[
            Align(alignment: Alignment.centerLeft,
              child: Text('Performance',
                style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600))),
            const SizedBox(height: 12),
            if (longevityData != null && longevityData.isNotEmpty) ...[
              const Text('⏱ Longevidade', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              _DetailedVoteChart(data: longevityData, color: const Color(0xFF4CAF50)),
              const SizedBox(height: 14),
            ],
            if (sillageData != null && sillageData.isNotEmpty) ...[
              const Text('📡 Projeção (Sillage)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              _DetailedVoteChart(data: sillageData, color: const Color(0xFF2196F3)),
            ],
            const SizedBox(height: 20),
          ],

          // Seasons & Time of Day
          if (seasonData != null && seasonData.isNotEmpty) ...[
            Align(alignment: Alignment.centerLeft,
              child: Text('Quando Usar',
                style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Row(children: [
              ...seasonData.map<Widget>((s) {
                final icon = switch (s['name']) {
                  'Inverno' => '❄️',
                  'Verão' => '☀️',
                  'Primavera' => '🌸',
                  'Outono' => '🍂',
                  _ => '📅',
                };
                final pct = (s['percentage'] as num?) ?? 0;
                return Expanded(child: Column(children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(s['name'] ?? '', style: const TextStyle(fontSize: 10)),
                  Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 10,
                      color: pct > 50 ? AppColors.gold : AppColors.textMuted,
                      fontWeight: pct > 50 ? FontWeight.bold : FontWeight.normal)),
                ]));
              }),
            ]),
            if (timeOfDay != null && timeOfDay.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: timeOfDay.map<Widget>((t) {
                final icon = t['name'] == 'Dia' ? '🌤️' : '🌙';
                final pct = (t['percentage'] as num?) ?? 0;
                return Expanded(child: Column(children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  Text('${t['name']} ${pct.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11,
                      color: pct > 50 ? AppColors.gold : AppColors.textMuted)),
                ]));
              }).toList()),
            ],
            const SizedBox(height: 24),
          ],

          // Influencer Reviews
          _ReviewsSection(perfumeId: perfume['id']),

          // Add button
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar à Minha Coleção'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
          const SizedBox(height: 10),
          // Similar button
          SizedBox(width: double.infinity,
            child: _SimilarButton(perfumeId: perfume['id'], perfumeName: perfume['name'] ?? '')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist, color: AppColors.gold, size: 40),
            SizedBox(height: 4),
            Text('Sem foto', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.gold;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) { return AppColors.gold; }
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color? color;
  const _InfoChip(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(text, style: TextStyle(fontSize: 11, color: c,
        fontWeight: FontWeight.w500)),
    );
  }
}

class _SimilarButton extends StatefulWidget {
  final String perfumeId;
  final String perfumeName;

  const _SimilarButton({required this.perfumeId, required this.perfumeName});

  @override
  State<_SimilarButton> createState() => _SimilarButtonState();
}

class _SimilarButtonState extends State<_SimilarButton> {
  bool _loading = false;

  Future<void> _openSimilarPage() async {
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

      // Open full-screen page with results
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _SimilarPerfumesPage(
          perfumeName: widget.perfumeName,
          results: results,
          collectionIds: collectionIds,
        ),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao buscar similares'),
          backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _openSimilarPage,
      icon: _loading
        ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
        : const Icon(Icons.compare_arrows),
      label: Text(_loading ? 'Buscando...' : 'Ver Similares'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.glassBorder),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}

class _SimilarPerfumesPage extends StatelessWidget {
  final String perfumeName;
  final List<dynamic> results;
  final List<String> collectionIds;

  const _SimilarPerfumesPage({
    required this.perfumeName,
    required this.results,
    required this.collectionIds,
  });

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'https://essencia.laravel.cloud/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Similares a $perfumeName',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: results.isEmpty
        ? const Center(child: Text('Nenhum similar encontrado',
            style: TextStyle(color: AppColors.textMuted)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final s = results[index];
              final inCollection = collectionIds.contains(s['id']);
              final imageUrl = _proxyUrl(s['image_url'] as String?);
              final family = s['olfactory_family']?['name'] ?? '';
              final rating = s['rating'];
              final gender = s['gender'] as String?;

              return GestureDetector(
                onTap: () => openPerfumeDetailSheet(context, s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: inCollection ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ) : null,
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 56, height: 72,
                            color: AppColors.surfaceLight,
                            child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.local_florist, color: AppColors.gold, size: 20)))
                              : const Center(
                                  child: Icon(Icons.local_florist, color: AppColors.gold, size: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Text(s['brand'] ?? '',
                                style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(children: [
                                if (family.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4)),
                                    child: Text(family,
                                      style: const TextStyle(color: AppColors.gold, fontSize: 10)),
                                  ),
                                if (gender != null) ...[
                                  const SizedBox(width: 6),
                                  Text(gender == 'Feminino' ? '♀' : gender == 'Masculino' ? '♂' : '⚥',
                                    style: const TextStyle(fontSize: 12)),
                                ],
                                if (rating != null) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.star, color: AppColors.gold, size: 12),
                                  Text(' ${double.tryParse(rating.toString())?.toStringAsFixed(1) ?? rating}',
                                    style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                                ],
                              ]),
                            ],
                          ),
                        ),
                        // Status
                        Column(
                          children: [
                            if (inCollection)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6)),
                                child: const Text('Na coleção',
                                  style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(height: 4),
                            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}

class _DetailedVoteChart extends StatelessWidget {
  final List<dynamic> data;
  final Color color;

  const _DetailedVoteChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    // Sort by percentage descending
    final sorted = List<Map<String, dynamic>>.from(
      data.map((d) => Map<String, dynamic>.from(d as Map)));
    sorted.sort((a, b) => ((b['percentage'] as num?) ?? 0)
        .compareTo((a['percentage'] as num?) ?? 0));

    final maxPct = sorted.isNotEmpty
      ? (sorted.first['percentage'] as num?) ?? 1
      : 1;

    return Column(
      children: sorted.map<Widget>((item) {
        final pct = (item['percentage'] as num?) ?? 0;
        final name = item['name'] ?? '';
        final isTop = pct == maxPct;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(width: 75, child: Text(name,
                style: TextStyle(fontSize: 11,
                  fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                  color: isTop ? color : AppColors.textSecondary))),
              Expanded(
                child: Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4)),
                    ),
                    // Filled bar
                    FractionallySizedBox(
                      widthFactor: pct / 100,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isTop ? 0.7 : 0.3),
                          borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 36, child: Text('${pct.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11,
                  fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                  color: isTop ? color : AppColors.textMuted),
                textAlign: TextAlign.right)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PerformanceBar({required this.label, required this.value,
    required this.icon});

  @override
  Widget build(BuildContext context) {
    double level = 0.5;
    if (value == 'longa' || value == 'forte') level = 0.9;
    else if (value == 'moderada' || value == 'média') level = 0.6;
    else if (value == 'curta' || value == 'íntima') level = 0.3;

    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: AppColors.gold),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11,
              color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: level,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              minHeight: 4),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


// --- Reviews Section (Influencer) ---
class _ReviewsSection extends StatefulWidget {
  final String perfumeId;
  const _ReviewsSection({required this.perfumeId});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  List<dynamic>? _reviews;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final response = await ApiClient().dio.get('/perfumes/${widget.perfumeId}/reviews');
      if (mounted) setState(() => _reviews = response.data as List<dynamic>);
    } catch (_) {
      if (mounted) setState(() => _reviews = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reviews == null || _reviews!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎬 Reviews do Influencer', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._reviews!.map<Widget>((r) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.roseGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    (r['type'] ?? 'review').toString().toUpperCase(),
                    style: const TextStyle(color: AppColors.roseGold, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(r['title'] ?? 'Review',
                  style: const TextStyle(fontSize: 12))),
                GestureDetector(
                  onTap: () {
                    final url = r['instagram_url'] as String?;
                    if (url != null) {
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                    child: const Text('▶ Assistir',
                      style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}
