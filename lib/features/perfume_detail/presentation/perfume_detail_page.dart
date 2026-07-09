import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import '../../collection/presentation/type_selection_dialog.dart';
import '../../wishlist/presentation/wishlist_provider.dart';

/// Clamps a scent description to at most 150 characters.
/// If longer, truncates to 147 characters and appends "...".
String clampScentSummary(String description) {
  if (description.length > 150) {
    return '${description.substring(0, 147)}...';
  }
  return description;
}

/// Clamps a performance metric value to the range [0, 100].
int clampPerformanceValue(int value) {
  return value.clamp(0, 100);
}

/// Returns at most 10 items from a list of similares.
List<T> boundSimilares<T>(List<T> similares) {
  return similares.take(10).toList();
}

/// Full-screen perfume detail page accessed via `/perfume/:id`.
///
/// Displays header (image, name, brand, price, rating, compatibility),
/// scent summary, tabbed content (Notas, Performance, Sobre),
/// similar perfumes section, and "Conversar com Aura" CTA.
class PerfumeDetailPage extends ConsumerStatefulWidget {
  final String perfumeId;

  const PerfumeDetailPage({super.key, required this.perfumeId});

  @override
  ConsumerState<PerfumeDetailPage> createState() => _PerfumeDetailPageState();
}

class _PerfumeDetailPageState extends ConsumerState<PerfumeDetailPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _perfume;
  List<dynamic> _similares = [];
  List<dynamic> _dupes = [];
  bool _loading = true;
  bool _hasError = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final perfumeResponse =
          await ApiClient().dio.get('/perfumes/${widget.perfumeId}');

      // Fetch similar perfumes separately — don't fail the page if this errors
      List<dynamic> similares = [];
      try {
        final similarResponse =
            await ApiClient().dio.get('/perfumes/${widget.perfumeId}/similar');
        final simData = similarResponse.data;
        similares = simData is List ? simData : [];
      } catch (_) {
        // Silently ignore — similares are optional
      }

      // Fetch dupes separately — don't fail the page if this errors
      List<dynamic> dupes = [];
      try {
        final dupesResponse =
            await ApiClient().dio.get('/perfumes/${widget.perfumeId}/dupes');
        final dupesData = dupesResponse.data as Map<String, dynamic>;
        dupes = (dupesData['dupes'] as List?) ?? [];
      } catch (_) {
        // Silently ignore — dupes are optional
      }

      if (mounted) {
        setState(() {
          _perfume = perfumeResponse.data as Map<String, dynamic>;
          _similares = similares;
          _dupes = dupes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'https://perfumia.com.br/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  bool _hasPrice() {
    if (_perfume == null) return false;
    final prices = _perfume!['prices'] as List?;
    if (prices != null && prices.isNotEmpty) return true;
    final avgPrice = _perfume!['average_price'];
    if (avgPrice != null) {
      final val = double.tryParse(avgPrice.toString());
      if (val != null && val > 0) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final wishlistIds = ref.watch(wishlistIdsProvider);
    final isInWishlist = wishlistIds.contains(widget.perfumeId);

    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OlfatoTokens.ink),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: isInWishlist ? OlfatoTokens.pitanga : OlfatoTokens.gray,
            ),
            onPressed: () async {
              final notifier = ref.read(wishlistIdsProvider.notifier);
              bool success;
              if (isInWishlist) {
                success = await notifier.remove(widget.perfumeId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Removido da wishlist'),
                    backgroundColor: OlfatoTokens.gray,
                  ));
                }
              } else {
                success = await notifier.add(widget.perfumeId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Adicionado à wishlist ❤️'),
                    backgroundColor: OlfatoTokens.plum,
                  ));
                }
              }
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Erro ao atualizar wishlist'),
                  backgroundColor: OlfatoTokens.error,
                ));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: OlfatoTokens.gray, size: 22),
            onPressed: () async {
              if (_perfume != null) {
                final name = _perfume!['name'] as String? ?? '';
                final brand = _perfume!['brand'] as String? ?? '';
                final text = '🧴 $name — $brand\n\nConfira no Olfato: https://perfumia.com.br/app/perfume/${widget.perfumeId}';

                // Try Web Share API first
                final navigator = html.window.navigator;
                if (js_util.hasProperty(navigator, 'share')) {
                  try {
                    final shareData = js_util.newObject<Object>();
                    js_util.setProperty(shareData, 'text', text);
                    js_util.setProperty(shareData, 'title', '$name — $brand');
                    await js_util.promiseToFuture(js_util.callMethod(navigator, 'share', [shareData]));
                  } catch (_) {
                    // User cancelled or error — fallback to clipboard
                    await Clipboard.setData(ClipboardData(text: text));
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado! 📋'), backgroundColor: OlfatoTokens.plum));
                  }
                } else {
                  // No Web Share API — copy to clipboard
                  await Clipboard.setData(ClipboardData(text: text));
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado! 📋'), backgroundColor: OlfatoTokens.plum));
                }
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: OlfatoTokens.plum),
      );
    }

    if (_hasError || _perfume == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PerfumeHeader(perfume: _perfume!, proxyUrl: _proxyUrl),
          if (_perfume!['is_dupe_of'] != null) ...[
            const SizedBox(height: 12),
            _DupeOfTag(dupeData: _perfume!['is_dupe_of'] as Map<String, dynamic>),
          ],
          const SizedBox(height: 16),
          _ScentSummary(perfume: _perfume!),
          const SizedBox(height: 20),
          _PerfumeTabSection(
            perfume: _perfume!,
            tabController: _tabController,
          ),
          const SizedBox(height: 20),
          if (_hasPrice()) _PriceSection(perfume: _perfume!),
          const SizedBox(height: 28),
          // Reviews section
          if ((_perfume!['reviews'] as List?)?.isNotEmpty ?? false)
            _ReviewsSection(reviews: _perfume!['reviews'] as List),
          if (_similares.isNotEmpty)
            _SimilaresSection(
              similares: _similares,
              proxyUrl: _proxyUrl,
            ),
          if (_dupes.isNotEmpty)
            _DupesSection(dupes: _dupes, proxyUrl: _proxyUrl),
          const SizedBox(height: 24),
          _CollectionButton(perfumeId: widget.perfumeId, perfumeName: _perfume!['name'] as String? ?? ''),
          const SizedBox(height: 12),
          // Compare button — navigates to comparador VS with search for second perfume
          _CompareButton(
            currentPerfumeId: widget.perfumeId,
            similares: _similares,
          ),
          const SizedBox(height: 16),
          _AuraCTA(perfume: _perfume!),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: OlfatoTokens.gray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar os detalhes do perfume.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: OlfatoTokens.gray,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── PerfumeHeader ────────────────────────────────────────────────────────────

class _PerfumeHeader extends StatelessWidget {
  final Map<String, dynamic> perfume;
  final String Function(String?) proxyUrl;

  const _PerfumeHeader({required this.perfume, required this.proxyUrl});

  @override
  Widget build(BuildContext context) {
    final imageUrl = proxyUrl(perfume['image_url'] as String?);
    final name = perfume['name'] as String? ?? '';
    final brand = perfume['brand'] as String? ?? '';
    final price = perfume['average_price'];
    final rating = perfume['rating'];
    final ratingCount = perfume['rating_count'];
    // Compatibility score may come from user context — omit if null
    final compatibility = perfume['compatibility_score'] as num?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Perfume image
          Container(
            width: 160,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
              border: Border.all(color: OlfatoTokens.borderLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, e, s) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.ebGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
          const SizedBox(height: 4),

          // Brand
          Text(
            brand,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: OlfatoTokens.plum,
            ),
          ),
          const SizedBox(height: 12),

          // Price
          if (price != null) ...[
            _buildPrice(price),
            const SizedBox(height: 10),
          ],

          // Rating
          if (rating != null) _buildRating(rating, ratingCount),

          // Compatibility (omit if null — don't show 0)
          if (compatibility != null && compatibility > 0) ...[
            const SizedBox(height: 10),
            _buildCompatibility(compatibility.toInt()),
          ],
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Center(
      child: Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 48),
    );
  }

  Widget _buildPrice(dynamic price) {
    final priceVal = double.tryParse(price.toString());
    if (priceVal == null || priceVal <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: OlfatoTokens.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'R\$ ${priceVal.toStringAsFixed(2)}',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: OlfatoTokens.green,
        ),
      ),
    );
  }

  Widget _buildRating(dynamic rating, dynamic ratingCount) {
    final ratingVal = double.tryParse(rating.toString()) ?? 0;
    final fullStars = ratingVal.round().clamp(0, 5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(
          5,
          (i) => Icon(
            i < fullStars ? Icons.star_rounded : Icons.star_border_rounded,
            color: OlfatoTokens.amber,
            size: 20,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          ratingVal.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: OlfatoTokens.amber,
          ),
        ),
        if (ratingCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($ratingCount)',
            style: GoogleFonts.inter(fontSize: 11, color: OlfatoTokens.gray),
          ),
        ],
      ],
    );
  }

  Widget _buildCompatibility(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: OlfatoTokens.plum.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: OlfatoTokens.plum, size: 14),
          const SizedBox(width: 6),
          Text(
            '$score% compatível',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: OlfatoTokens.plum,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── ScentSummary ─────────────────────────────────────────────────────────────

class _ScentSummary extends StatelessWidget {
  final Map<String, dynamic> perfume;

  const _ScentSummary({required this.perfume});

  @override
  Widget build(BuildContext context) {
    // Prefer PT description, fallback to EN
    final descriptionPt = perfume['description_pt'] as String?;
    final descriptionEn = perfume['description'] as String?;
    final description = (descriptionPt != null && descriptionPt.isNotEmpty)
        ? descriptionPt
        : descriptionEn;
    if (description == null || description.isEmpty) return const SizedBox.shrink();

    final isLong = description.length > 300;
    final summary = isLong ? '${description.substring(0, 297)}...' : description;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: isLong
            ? () => _showFullDescription(context, description)
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: OlfatoTokens.mist,
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
            border: Border.all(color: OlfatoTokens.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: OlfatoTokens.ink,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isLong) ...[
                const SizedBox(height: 8),
                Text(
                  'Ler mais',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OlfatoTokens.plum,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFullDescription(BuildContext context, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: OlfatoTokens.vanilla,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OlfatoTokens.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Sobre o perfume',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: OlfatoTokens.ink,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: OlfatoTokens.gray, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: OlfatoTokens.borderLight),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.7,
                      color: OlfatoTokens.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── PerfumeTabSection ────────────────────────────────────────────────────────

class _PerfumeTabSection extends StatefulWidget {
  final Map<String, dynamic> perfume;
  final TabController tabController;

  const _PerfumeTabSection({
    required this.perfume,
    required this.tabController,
  });

  @override
  State<_PerfumeTabSection> createState() => _PerfumeTabSectionState();
}

class _PerfumeTabSectionState extends State<_PerfumeTabSection> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!widget.tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.tabController.index;

    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: OlfatoTokens.mist,
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
          child: TabBar(
            controller: widget.tabController,
            labelColor: OlfatoTokens.ink,
            unselectedLabelColor: OlfatoTokens.gray,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
              boxShadow: [OlfatoTokens.cardShadow],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Notas'),
              Tab(text: 'Performance'),
              Tab(text: 'Sobre'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Render active tab content inline — no nested scroll
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (activeIndex) {
            0 => _NotasTab(perfume: widget.perfume),
            1 => _PerformanceTab(perfume: widget.perfume),
            2 => _SobreTab(perfume: widget.perfume),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

// ─── NotasTab ─────────────────────────────────────────────────────────────────

class _NotasTab extends StatelessWidget {
  final Map<String, dynamic> perfume;

  const _NotasTab({required this.perfume});

  @override
  Widget build(BuildContext context) {
    final topNotes = perfume['top_notes'] as List? ?? [];
    final heartNotes = perfume['heart_notes'] as List? ?? [];
    final baseNotes = perfume['base_notes'] as List? ?? [];
    final accords = perfume['accords_data'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Olfactory pyramid
          if (topNotes.isNotEmpty || heartNotes.isNotEmpty || baseNotes.isNotEmpty) ...[
            Text(
              'Pirâmide Olfativa',
              style: GoogleFonts.ebGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 12),
            if (topNotes.isNotEmpty) _buildNoteRow('Topo', topNotes, OlfatoTokens.pitanga),
            if (heartNotes.isNotEmpty)
              _buildNoteRow('Coração', heartNotes, OlfatoTokens.plum),
            if (baseNotes.isNotEmpty) _buildNoteRow('Base', baseNotes, OlfatoTokens.amber),
            const SizedBox(height: 20),
          ],

          // Accords
          if (accords.isNotEmpty) ...[
            Text(
              'Acordes',
              style: GoogleFonts.ebGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...accords.take(8).map<Widget>((accord) {
              final name = accord['name_pt'] ?? accord['name_en'] ?? '';
              final pct = (accord['percentage'] as num?)?.toInt() ?? 0;
              final colorHex = accord['color'] as String?;
              final barColor = _parseColor(colorHex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: OlfatoTokens.ink,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0, 100) / 100,
                          backgroundColor: OlfatoTokens.mist,
                          valueColor: AlwaysStoppedAnimation(barColor),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$pct%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: OlfatoTokens.gray,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteRow(String label, List<dynamic> notes, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: notes.map<Widget>((note) {
              final noteName = note is String ? note : (note as Map)['name'] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(
                  noteName.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return OlfatoTokens.plum;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return OlfatoTokens.plum;
    }
  }
}


// ─── PerformanceTab ───────────────────────────────────────────────────────────

class _PerformanceTab extends StatelessWidget {
  final Map<String, dynamic> perfume;

  const _PerformanceTab({required this.perfume});

  @override
  Widget build(BuildContext context) {
    final longevityData = perfume['longevity_data'] as List?;
    final sillageData = perfume['sillage_data'] as List?;
    final seasonData = perfume['season_data'] as List?;
    final timeOfDay = perfume['time_of_day'] as List?;

    final fixacao = _derivePercentage(longevityData);
    final projecaoRastro = _derivePercentage(sillageData);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
          const SizedBox(height: 20),
          _PerformanceBar(label: 'Fixação', value: fixacao, color: OlfatoTokens.green),
          const SizedBox(height: 16),
          _PerformanceBar(label: 'Projeção / Rastro', value: projecaoRastro, color: OlfatoTokens.plum),

          // Season
          if (seasonData != null && seasonData.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Estação',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: OlfatoTokens.gray,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: seasonData.map<Widget>((s) {
                final name = s['name'] as String? ?? '';
                final pct = (s['percentage'] as num?)?.toInt() ?? 0;
                final icon = switch (name) {
                  'Inverno' => '❄️',
                  'Verão' => '☀️',
                  'Primavera' => '🌸',
                  'Outono' => '🍂',
                  _ => '📅',
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: OlfatoTokens.borderLight),
                  ),
                  child: Text(
                    '$icon $name $pct%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: pct > 50 ? OlfatoTokens.ink : OlfatoTokens.gray,
                      fontWeight: pct > 50 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Time of day
          if (timeOfDay != null && timeOfDay.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Horário',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: OlfatoTokens.gray,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timeOfDay.map<Widget>((t) {
                final name = t['name'] as String? ?? '';
                final pct = (t['percentage'] as num?)?.toInt() ?? 0;
                final icon = name == 'Dia' ? '🌤️' : '🌙';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: OlfatoTokens.borderLight),
                  ),
                  child: Text(
                    '$icon $name $pct%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: pct > 50 ? OlfatoTokens.ink : OlfatoTokens.gray,
                      fontWeight: pct > 50 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  int _derivePercentage(List<dynamic>? data) {
    if (data == null || data.isEmpty) return 0;
    double weightedSum = 0;
    double totalPct = 0;
    final count = data.length;
    for (int i = 0; i < count; i++) {
      final pct = (data[i]['percentage'] as num?)?.toDouble() ?? 0;
      final weight = ((i + 1) / count) * 100;
      weightedSum += pct * weight;
      totalPct += pct;
    }
    if (totalPct <= 0) return 0;
    return (weightedSum / totalPct).round().clamp(0, 100);
  }
}

class _PerformanceBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _PerformanceBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: OlfatoTokens.ink,
              ),
            ),
            Text(
              '$clampedValue%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clampedValue / 100,
            backgroundColor: OlfatoTokens.mist,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}


// ─── SobreTab ─────────────────────────────────────────────────────────────────

class _SobreTab extends StatelessWidget {
  final Map<String, dynamic> perfume;

  const _SobreTab({required this.perfume});

  @override
  Widget build(BuildContext context) {
    final concentration = perfume['concentration'] as String?;
    final year = perfume['year_launched'];
    final perfumer = perfume['perfumer'] as String?;
    final family = perfume['olfactory_family']?['name'] as String?;
    final gender = perfume['gender'] as String?;
    final collectionName = perfume['collection_name'] as String?;
    final reviewsCount = perfume['reviews_count'];
    final topNotes = perfume['top_notes'] as List? ?? [];
    final heartNotes = perfume['heart_notes'] as List? ?? [];
    final baseNotes = perfume['base_notes'] as List? ?? [];
    final totalNotes = topNotes.length + heartNotes.length + baseNotes.length;
    final rating = perfume['rating'];
    final ratingCount = perfume['rating_count'];
    final haveCount = perfume['have_count'] as int?;
    final hadCount = perfume['had_count'] as int?;
    final wantCount = perfume['want_count'] as int?;
    final priceValue = perfume['price_value_avg'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sobre',
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
          const SizedBox(height: 16),
          if (concentration != null && concentration.isNotEmpty)
            _infoRow('Concentração', concentration),
          if (year != null) _infoRow('Ano de lançamento', '$year'),
          if (perfumer != null && perfumer.isNotEmpty)
            _infoRow('Perfumista', perfumer),
          if (family != null && family.isNotEmpty)
            _infoRow('Família olfativa', family),
          if (gender != null && gender.isNotEmpty) _infoRow('Gênero', gender),
          if (collectionName != null && collectionName.isNotEmpty)
            _infoRow('Linha / Coleção', collectionName),

          // Avaliação
          if (rating != null) ...[
            const SizedBox(height: 8),
            _infoRow('Avaliação', '${double.tryParse(rating.toString())?.toStringAsFixed(1) ?? rating}/5${ratingCount != null ? ' ($ratingCount votos)' : ''}'),
          ],

          // Custo-benefício
          if (priceValue != null) ...[
            _infoRow('Custo-benefício', _formatPriceValue(priceValue)),
          ],

          // Popularidade
          if (haveCount != null || wantCount != null) ...[
            const SizedBox(height: 12),
            Text(
              'Popularidade',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: OlfatoTokens.gray,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (haveCount != null && haveCount > 0)
                  _popularityChip('👃', 'Têm', haveCount),
                if (hadCount != null && hadCount > 0)
                  _popularityChip('📦', 'Já tiveram', hadCount),
                if (wantCount != null && wantCount > 0)
                  _popularityChip('💜', 'Querem', wantCount),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (reviewsCount != null && reviewsCount > 0)
            _infoRow('Avaliações', '$reviewsCount avaliações'),
          if (totalNotes > 0)
            _infoRow('Composição', '$totalNotes notas (${topNotes.length} topo, ${heartNotes.length} coração, ${baseNotes.length} base)'),
        ],
      ),
    );
  }

  String _formatPriceValue(dynamic value) {
    final val = double.tryParse(value.toString()) ?? 0;
    if (val >= 4.0) return '⭐ Excelente (${val.toStringAsFixed(1)}/5)';
    if (val >= 3.0) return '👍 Bom (${val.toStringAsFixed(1)}/5)';
    if (val >= 2.0) return '😐 Regular (${val.toStringAsFixed(1)}/5)';
    return '👎 Baixo (${val.toStringAsFixed(1)}/5)';
  }

  Widget _popularityChip(String icon, String label, int count) {
    final formatted = count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: OlfatoTokens.mist,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OlfatoTokens.borderLight),
      ),
      child: Text(
        '$icon $label: $formatted',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: OlfatoTokens.ink,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: OlfatoTokens.gray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: OlfatoTokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─── ReviewsSection ───────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final List reviews;

  const _ReviewsSection({required this.reviews});

  String _typeLabel(String? type) {
    return switch (type) {
      'review' => '📝 Review',
      'comparativo' => '⚖️ Comparativo',
      'shorts' => '🎬 Shorts',
      'unboxing' => '📦 Unboxing',
      _ => '🎥 Vídeo',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Reviews',
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...reviews.map<Widget>((r) {
          final title = r['title'] as String? ?? '';
          final url = r['instagram_url'] as String? ?? '';
          final type = r['type'] as String?;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: GestureDetector(
              onTap: () async {
                if (url.isNotEmpty) {
                  final uri = Uri.tryParse(url);
                  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: OlfatoTokens.mist,
                  borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
                  border: Border.all(color: OlfatoTokens.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: OlfatoTokens.pitanga.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_circle_outline, color: OlfatoTokens.pitanga, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: OlfatoTokens.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(_typeLabel(type), style: GoogleFonts.inter(fontSize: 11, color: OlfatoTokens.gray)),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 16, color: OlfatoTokens.gray),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── SimilaresSection ─────────────────────────────────────────────────────────

class _SimilaresSection extends StatelessWidget {
  final List<dynamic> similares;
  final String Function(String?) proxyUrl;

  const _SimilaresSection({required this.similares, required this.proxyUrl});

  @override
  Widget build(BuildContext context) {
    // Show up to 10 similar perfumes
    final items = similares.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Similares',
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              final perfume = item is Map<String, dynamic> ? item : <String, dynamic>{};
              final name = perfume['name'] as String? ?? '';
              final brand = perfume['brand'] as String? ?? '';
              final imageUrl = proxyUrl(perfume['image_url'] as String?);
              // Similarity score — may come as 'similarity', 'score', or 'similarity_score'
              final similarity = (perfume['similarity'] ??
                      perfume['score'] ??
                      perfume['similarity_score']) as num?;
              final perfumeId = perfume['id']?.toString() ?? '';

              return GestureDetector(
                onTap: () {
                  if (perfumeId.isNotEmpty) {
                    context.go('/perfume/$perfumeId');
                  }
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
                    border: Border.all(color: OlfatoTokens.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(OlfatoTokens.radiusCard),
                        ),
                        child: Container(
                          height: 90,
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.all(6),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, e, s) => const Icon(
                                    Icons.local_florist,
                                    color: OlfatoTokens.plum,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_florist,
                                  color: OlfatoTokens.plum,
                                ),
                        ),
                      ),
                      // Info
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: OlfatoTokens.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              brand,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: OlfatoTokens.gray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (similarity != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: OlfatoTokens.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${similarity.toInt().clamp(0, 100)}% similar',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: OlfatoTokens.green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


// ─── PriceSection (Onde Comprar) ──────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  final Map<String, dynamic> perfume;

  const _PriceSection({required this.perfume});

  String _sourceLabel(String source) {
    return switch (source.toLowerCase()) {
      'mercadolivre' => '🟡 Mercado Livre',
      'epoca' => '🟣 Época Cosméticos',
      'belezanaweb' => '🔵 Beleza na Web',
      'sephora' => '⚫ Sephora',
      _ => '🏷️ $source',
    };
  }

  @override
  Widget build(BuildContext context) {
    final rawPrices = perfume['prices'] as List? ?? [];
    final prices = <Map<String, dynamic>>[];
    for (final p in rawPrices) {
      if (p is Map) {
        final map = Map<String, dynamic>.from(p);
        final priceVal = double.tryParse(map['price']?.toString() ?? '');
        if (priceVal != null && priceVal > 0) {
          prices.add(map);
        }
      }
    }

    if (prices.isEmpty) {
      // Fallback to average_price
      final avgPrice = double.tryParse((perfume['average_price'] ?? '').toString());
      if (avgPrice == null || avgPrice <= 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ONDE COMPRAR',
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OlfatoTokens.mist,
                borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
                border: Border.all(color: OlfatoTokens.borderLight),
              ),
              child: Row(
                children: [
                  const Text('🏷️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preço médio',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: OlfatoTokens.ink,
                      ),
                    ),
                  ),
                  Text(
                    'R\$ ${avgPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: OlfatoTokens.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Sort by price ascending, limit to 5
    final sorted = List<Map<String, dynamic>>.from(prices)
      ..sort((a, b) {
        final pa = double.tryParse(a['price']?.toString() ?? '') ?? double.infinity;
        final pb = double.tryParse(b['price']?.toString() ?? '') ?? double.infinity;
        return pa.compareTo(pb);
      });

    final displayPrices = sorted.take(5).toList();
    final lowestPrice = double.tryParse(displayPrices.first['price']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ONDE COMPRAR',
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...displayPrices.map((store) {
            final source = store['source'] as String? ?? '';
            final price = double.tryParse(store['price']?.toString() ?? '');
            final url = store['url'] as String?;
            final isLowest = price == lowestPrice && sorted.length > 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () async {
                  if (url != null && url.isNotEmpty) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isLowest
                        ? OlfatoTokens.green.withValues(alpha: 0.06)
                        : OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
                    border: Border.all(
                      color: isLowest
                          ? OlfatoTokens.green.withValues(alpha: 0.3)
                          : OlfatoTokens.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sourceLabel(source),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: OlfatoTokens.ink,
                              ),
                            ),
                            if (isLowest) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Menor preço',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: OlfatoTokens.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (price != null)
                        Text(
                          'R\$ ${price.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isLowest ? OlfatoTokens.green : OlfatoTokens.ink,
                          ),
                        ),
                      if (url != null && url.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: OlfatoTokens.gray,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}


// ─── DupesSection ─────────────────────────────────────────────────────────────

class _DupesSection extends StatelessWidget {
  final List<dynamic> dupes;
  final String Function(String?) proxyUrl;

  const _DupesSection({required this.dupes, required this.proxyUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Dupes',
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: dupes.length,
            itemBuilder: (_, index) {
              final dupe = dupes[index] as Map<String, dynamic>;
              final dupeName = dupe['dupe_name'] as String? ?? '';
              final dupeBrand = dupe['dupe_brand'] as String? ?? '';
              final accuracy = (dupe['accuracy_score'] as num?)?.toInt();
              final source = dupe['source'] as String? ?? '';
              final perfumeData = dupe['perfume'] as Map<String, dynamic>?;
              final imageUrl = perfumeData != null
                  ? proxyUrl(perfumeData['image_url'] as String?)
                  : '';
              final perfumeId = perfumeData?['id']?.toString();

              return GestureDetector(
                onTap: () {
                  if (perfumeId != null && perfumeId.isNotEmpty) {
                    context.go('/perfume/$perfumeId');
                  }
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
                    border: Border.all(color: OlfatoTokens.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image area
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(OlfatoTokens.radiusCard),
                        ),
                        child: Container(
                          height: 80,
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.all(6),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.local_florist,
                                    color: OlfatoTokens.plum,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_florist,
                                  color: OlfatoTokens.plum,
                                ),
                        ),
                      ),
                      // Info
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dupeName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: OlfatoTokens.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dupeBrand,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: OlfatoTokens.gray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (accuracy != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: OlfatoTokens.pitanga.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$accuracy/10',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: OlfatoTokens.pitanga,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


// ─── Aura CTA ─────────────────────────────────────────────────────────────────

/// Predefined contextual suggestion pool for the Aura AI assistant.
const kAuraSuggestions = <String>[
  'Pergunte à Aura sobre os melhores ambientes para usar ele',
  'Compare com a Aura ele com seu DUPE mais conhecido',
  'Pergunte à Aura se ele é um bom presente',
  'Pergunte à Aura se ele se encaixa na sua coleção',
];

class _AuraCTA extends StatefulWidget {
  final Map<String, dynamic> perfume;

  const _AuraCTA({required this.perfume});

  @override
  State<_AuraCTA> createState() => _AuraCTAState();
}

class _AuraCTAState extends State<_AuraCTA> {
  late List<String> _selectedSuggestions;

  @override
  void initState() {
    super.initState();
    final shuffled = List<String>.from(kAuraSuggestions)..shuffle();
    final count = (DateTime.now().millisecond % 2) + 1; // 1 or 2
    _selectedSuggestions = shuffled.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.perfume['name'] as String? ?? '';
    final brand = widget.perfume['brand'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: OlfatoTokens.plum, size: 16),
              const SizedBox(width: 6),
              Text(
                'Pergunte à Aura',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: OlfatoTokens.plum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._selectedSuggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                final message = '$suggestion — $name ($brand)';
                context.push('/chat?initialMessage=${Uri.encodeComponent(message)}');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: OlfatoTokens.plum.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
                  border: Border.all(
                    color: OlfatoTokens.plum.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: OlfatoTokens.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: OlfatoTokens.plum,
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}


// ─── Collection Button ────────────────────────────────────────────────────────

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
  String? _userPerfumeId;
  String? _currentType;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final response = await ApiClient().dio.get('/collection');
      final items = response.data['data'] as List;
      final match = items.firstWhere(
        (item) => item['perfume']?['id'] == widget.perfumeId || item['perfume_id'] == widget.perfumeId,
        orElse: () => null,
      );
      if (mounted) {
        setState(() {
          _inCollection = match != null;
          _userPerfumeId = match?['id']?.toString();
          _currentType = match?['type'] as String?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToCollection() async {
    final selectedType = await showTypeSelectionDialog(context);
    if (selectedType == null) return;

    try {
      final response = await ApiClient().dio.post('/collection', data: {
        'perfume_id': widget.perfumeId,
        'type': selectedType.apiValue,
      });
      if (mounted) {
        setState(() {
          _inCollection = true;
          _userPerfumeId = response.data['id']?.toString();
          _currentType = selectedType.apiValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.perfumeName} adicionado como ${selectedType.label.toLowerCase()}!'),
          backgroundColor: OlfatoTokens.plum,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao adicionar. Tente novamente.'),
          backgroundColor: OlfatoTokens.error,
        ));
      }
    }
  }

  Future<void> _removeFromCollection() async {
    if (_userPerfumeId == null) return;
    try {
      await ApiClient().dio.delete('/collection/$_userPerfumeId');
      if (mounted) {
        setState(() {
          _inCollection = false;
          _userPerfumeId = null;
          _currentType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.perfumeName} removido da coleção'),
          backgroundColor: OlfatoTokens.gray,
        ));
      }
    } catch (_) {}
  }

  Future<void> _markAsJaTive() async {
    if (_userPerfumeId == null) return;
    try {
      await ApiClient().dio.put('/collection/$_userPerfumeId/rating', data: {'type': 'ja_tive'});
      if (mounted) {
        setState(() => _currentType = 'ja_tive');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Marcado como "já tive"'),
          backgroundColor: OlfatoTokens.amber,
        ));
      }
    } catch (_) {}
  }

  String _typeDisplayLabel(String? type) {
    return switch (type) {
      'perfume' => 'Perfume',
      'decant' => 'Decante',
      'amostra' => 'Amostra',
      'ja_tive' => 'Já Tive',
      _ => 'Perfume',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 56);

    if (_inCollection) {
      final isJaTive = _currentType == 'ja_tive';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isJaTive
                ? OlfatoTokens.amber.withValues(alpha: 0.1)
                : OlfatoTokens.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
            border: Border.all(
              color: isJaTive
                  ? OlfatoTokens.amber.withValues(alpha: 0.3)
                  : OlfatoTokens.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isJaTive ? Icons.history : Icons.check_circle,
                      color: isJaTive ? OlfatoTokens.amber : OlfatoTokens.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isJaTive
                          ? 'Já Tive ✓'
                          : 'Na sua coleção (${_typeDisplayLabel(_currentType)})',
                      style: GoogleFonts.inter(
                        color: isJaTive ? OlfatoTokens.amber : OlfatoTokens.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 1,
                color: isJaTive
                    ? OlfatoTokens.amber.withValues(alpha: 0.2)
                    : OlfatoTokens.green.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _removeFromCollection,
                        style: TextButton.styleFrom(
                          foregroundColor: OlfatoTokens.error,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          'Remover',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (!isJaTive) ...[
                      Container(
                        width: 1,
                        height: 24,
                        color: OlfatoTokens.gray.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _markAsJaTive,
                          style: TextButton.styleFrom(
                            foregroundColor: OlfatoTokens.amber,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            'Marcar como já tive',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _addToCollection,
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'Adicionar à Coleção',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: OlfatoTokens.plum,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
            ),
          ),
        ),
      ),
    );
  }
}


// ─── DupeOfTag ────────────────────────────────────────────────────────────────

/// Shows a tag when this perfume is a dupe of another, with the original name,
/// brand, and accuracy score. Tapping navigates to the original perfume.
class _DupeOfTag extends StatelessWidget {
  final Map<String, dynamic> dupeData;

  const _DupeOfTag({required this.dupeData});

  @override
  Widget build(BuildContext context) {
    final originalName = dupeData['original_name'] as String? ?? '';
    final originalBrand = dupeData['original_brand'] as String? ?? '';
    final accuracyScore = dupeData['accuracy_score'] as num?;
    final originalPerfume = dupeData['perfume'] as Map<String, dynamic>?;
    final originalId = originalPerfume?['id']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          if (originalId != null && originalId.isNotEmpty) {
            context.push('/perfume/$originalId');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: OlfatoTokens.pitanga.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
            border: Border.all(color: OlfatoTokens.pitanga.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.content_copy, size: 16, color: OlfatoTokens.pitanga),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dupe de $originalName ($originalBrand)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OlfatoTokens.pitanga,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (accuracyScore != null && accuracyScore > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: OlfatoTokens.pitanga.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(accuracyScore.toInt() * 10)}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: OlfatoTokens.pitanga,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 12, color: OlfatoTokens.pitanga),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CompareButton ────────────────────────────────────────────────────────────

/// Button that navigates to the comparador VS with this perfume pre-loaded
/// and an empty slot for the user to search for the second perfume.
class _CompareButton extends StatelessWidget {
  final String currentPerfumeId;
  final List<dynamic> similares;

  const _CompareButton({required this.currentPerfumeId, required this.similares});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: () {
          context.push('/compare?perfume1=$currentPerfumeId');
        },
        icon: const Icon(Icons.compare_arrows),
        label: const Text('Comparar com outro'),
        style: OutlinedButton.styleFrom(
          foregroundColor: OlfatoTokens.plum,
          side: BorderSide(color: OlfatoTokens.plum.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
