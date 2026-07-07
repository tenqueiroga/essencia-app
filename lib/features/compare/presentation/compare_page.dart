import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';

/// Model representing one perfume's comparison data.
class _ComparisonPerfume {
  final String id;
  final String name;
  final String brand;
  final String? imageUrl;
  final String? familia;
  final String? genero;
  final String? notasTopo;
  final String? notasCoracao;
  final String? notasBase;
  final String? fixacao;
  final String? projecao;
  final String? preco;
  final String? cusBeneficio;
  final String? ano;
  final String? perfumista;
  final String? estacao;
  final String? horario;
  final double? rating;
  final int? ratingCount;

  const _ComparisonPerfume({
    required this.id,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.familia,
    this.genero,
    this.notasTopo,
    this.notasCoracao,
    this.notasBase,
    this.fixacao,
    this.projecao,
    this.preco,
    this.cusBeneficio,
    this.ano,
    this.perfumista,
    this.estacao,
    this.horario,
    this.rating,
    this.ratingCount,
  });

  factory _ComparisonPerfume.fromJson(Map<String, dynamic> json) {
    // Fixação
    String? fixacao;
    final longevityData = json['longevity_data'] as List?;
    if (longevityData != null && longevityData.isNotEmpty) {
      fixacao = _deriveLongevityCategory(longevityData);
    } else {
      fixacao = json['longevity'] as String?;
    }

    // Projeção
    String? projecao;
    final sillageData = json['sillage_data'] as List?;
    if (sillageData != null && sillageData.isNotEmpty) {
      projecao = _deriveSillageCategory(sillageData);
    } else {
      projecao = json['projection'] as String?;
    }

    // Price
    String? preco;
    final price = json['average_price'];
    if (price != null) {
      final priceVal = double.tryParse(price.toString());
      if (priceVal != null && priceVal > 0) {
        preco = 'R\$ ${priceVal.toStringAsFixed(2)}';
      }
    }

    // Custo-benefício
    String? cusBeneficio;
    final pv = json['price_value_avg'];
    if (pv != null) {
      final val = double.tryParse(pv.toString());
      if (val != null && val > 0) {
        cusBeneficio = '${val.toStringAsFixed(1)}/5';
      }
    }

    // Notas
    String? notasTopo;
    final topNotes = json['top_notes'] as List?;
    if (topNotes != null && topNotes.isNotEmpty) {
      notasTopo = topNotes.take(4).map((n) => n is String ? n : (n as Map)['name'] ?? '').join(', ');
    }

    String? notasCoracao;
    final heartNotes = json['heart_notes'] as List?;
    if (heartNotes != null && heartNotes.isNotEmpty) {
      notasCoracao = heartNotes.take(4).map((n) => n is String ? n : (n as Map)['name'] ?? '').join(', ');
    }

    String? notasBase;
    final baseNotes = json['base_notes'] as List?;
    if (baseNotes != null && baseNotes.isNotEmpty) {
      notasBase = baseNotes.take(4).map((n) => n is String ? n : (n as Map)['name'] ?? '').join(', ');
    }

    // Estação (dominant season)
    String? estacao;
    final seasonData = json['season_data'] as List?;
    if (seasonData != null && seasonData.isNotEmpty) {
      String bestSeason = '';
      num bestPct = 0;
      for (final s in seasonData) {
        final pct = (s['percentage'] as num?) ?? 0;
        if (pct > bestPct) { bestPct = pct; bestSeason = s['name'] as String? ?? ''; }
      }
      if (bestSeason.isNotEmpty) estacao = bestSeason;
    }

    // Horário (dominant time)
    String? horario;
    final timeData = json['time_of_day'] as List?;
    if (timeData != null && timeData.isNotEmpty) {
      String bestTime = '';
      num bestPct = 0;
      for (final t in timeData) {
        final pct = (t['percentage'] as num?) ?? 0;
        if (pct > bestPct) { bestPct = pct; bestTime = t['name'] as String? ?? ''; }
      }
      if (bestTime.isNotEmpty) horario = bestTime;
    }

    // Família
    final familia = json['olfactory_family']?['name'] as String? ??
        (json['olfactory_family'] is String ? json['olfactory_family'] as String : null);

    // Rating
    double? rating;
    final r = json['rating'];
    if (r != null) rating = double.tryParse(r.toString());

    return _ComparisonPerfume(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      familia: familia,
      genero: json['gender'] as String?,
      notasTopo: notasTopo,
      notasCoracao: notasCoracao,
      notasBase: notasBase,
      fixacao: fixacao,
      projecao: projecao,
      preco: preco,
      cusBeneficio: cusBeneficio,
      ano: json['year_launched']?.toString(),
      perfumista: json['perfumer'] as String?,
      estacao: estacao,
      horario: horario,
      rating: rating,
      ratingCount: json['rating_count'] as int?,
    );
  }

  static String _deriveLongevityCategory(List<dynamic> data) {
    String bestName = '';
    num bestPct = 0;
    for (final item in data) {
      final pct = (item['percentage'] as num?) ?? 0;
      if (pct > bestPct) {
        bestPct = pct;
        bestName = (item['name'] as String?) ?? '';
      }
    }
    final lower = bestName.toLowerCase();
    if (lower.contains('fraca') || lower.contains('curta')) return 'curta';
    if (lower.contains('moderada')) return 'média';
    return 'longa';
  }

  static String _deriveSillageCategory(List<dynamic> data) {
    String bestName = '';
    num bestPct = 0;
    for (final item in data) {
      final pct = (item['percentage'] as num?) ?? 0;
      if (pct > bestPct) {
        bestPct = pct;
        bestName = (item['name'] as String?) ?? '';
      }
    }
    final lower = bestName.toLowerCase();
    if (lower.contains('íntima') || lower.contains('intimate')) return 'íntima';
    if (lower.contains('moderada') || lower.contains('moderate')) return 'moderada';
    return 'forte';
  }
}

/// Comparador VS page — side-by-side perfume comparison at route `/compare`.
///
/// Receives perfume IDs via query parameters (`perfume1`, `perfume2`).
/// Compares: Cheiro, Fixação, Projeção, Preço, and Diferença principal
/// (AI-generated via `/api/chat/compare`).
class ComparePage extends StatefulWidget {
  final String? perfume1Id;
  final String? perfume2Id;

  const ComparePage({super.key, this.perfume1Id, this.perfume2Id});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  _ComparisonPerfume? _left;
  _ComparisonPerfume? _right;
  String? _diferencaPrincipal;
  bool _loading = true;
  bool _hasError = false;
  String? _perfume2Id;

  // Search for second perfume
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _perfume2Id = widget.perfume2Id;
    _loadComparison();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasPerfume1 =>
      widget.perfume1Id != null && widget.perfume1Id!.isNotEmpty;

  bool get _hasBothPerfumes =>
      _hasPerfume1 && _perfume2Id != null && _perfume2Id!.isNotEmpty;

  Future<void> _loadComparison() async {
    if (!_hasPerfume1) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
      _diferencaPrincipal = null;
    });

    try {
      // Always load perfume 1
      final leftResponse = await ApiClient().dio.get('/perfumes/${widget.perfume1Id}');
      final leftData = leftResponse.data as Map<String, dynamic>;
      final left = _ComparisonPerfume.fromJson(leftData);

      _ComparisonPerfume? right;
      if (_hasBothPerfumes) {
        final rightResponse = await ApiClient().dio.get('/perfumes/$_perfume2Id');
        final rightData = rightResponse.data as Map<String, dynamic>;
        right = _ComparisonPerfume.fromJson(rightData);
      }

      if (mounted) {
        setState(() {
          _left = left;
          _right = right;
          _loading = false;
        });
      }

      if (_hasBothPerfumes) _loadAiDifference();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadAiDifference() async {
    if (_left == null || _right == null) return;
    try {
      final response = await ApiClient()
          .dio
          .post('/chat/compare', data: {
            'perfume1_id': _left!.id,
            'perfume2_id': _right!.id,
          },
          options: Options(validateStatus: (status) => status != null && status < 600),
          )
          .timeout(const Duration(seconds: 25));
      
      final data = response.data as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        final reply = data['difference'] as String?;
        if (mounted && reply != null && reply.isNotEmpty) {
          setState(() => _diferencaPrincipal = reply);
          return;
        }
      }
      
      // Non-200 or no difference
      if (mounted) {
        final errorMsg = data['error']?['message'] as String? ?? 'Indisponível no momento.';
        setState(() => _diferencaPrincipal = errorMsg);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _diferencaPrincipal = 'Tempo esgotado. Tente comparar novamente.');
      }
    }
  }

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
      backgroundColor: OlfatoTokens.vanilla,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OlfatoTokens.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Comparador VS',
          style: GoogleFonts.ebGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: OlfatoTokens.ink,
          ),
        ),
        centerTitle: true,
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

    if (_hasError) {
      return _buildErrorState();
    }

    // Has perfume 1 but no perfume 2 — show left card + search for right
    if (_left != null && _right == null) {
      return _buildSelectSecondPerfume();
    }

    // No perfumes at all
    if (!_hasPerfume1) {
      return _buildEmptyState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_left == null || _right == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Side-by-side perfume header cards
          _ComparisonHeader(
            left: _left!,
            right: _right!,
            proxyUrl: _proxyUrl,
            onTapLeft: () => _navigateToDetail(_left!.id),
            onTapRight: () => _navigateToDetail(_right!.id),
          ),
          const SizedBox(height: 24),

          // Comparison — each row is a card with left and right columns
          _ComparisonRow(label: 'Notas de Topo', icon: Icons.air, left: _left!.notasTopo, right: _right!.notasTopo),
          _ComparisonRow(label: 'Notas de Coração', icon: Icons.favorite_outline, left: _left!.notasCoracao, right: _right!.notasCoracao),
          _ComparisonRow(label: 'Notas de Base', icon: Icons.landscape_outlined, left: _left!.notasBase, right: _right!.notasBase),
          _ComparisonRow(label: 'Família Olfativa', icon: Icons.spa_outlined, left: _left!.familia, right: _right!.familia),
          _ComparisonScaleRow(label: 'Fixação', icon: Icons.timer_outlined, leftVal: _left!.fixacao, rightVal: _right!.fixacao, categories: const ['curta', 'média', 'longa']),
          _ComparisonScaleRow(label: 'Projeção', icon: Icons.surround_sound_outlined, leftVal: _left!.projecao, rightVal: _right!.projecao, categories: const ['íntima', 'moderada', 'forte']),
          _ComparisonRow(label: 'Estação', icon: Icons.wb_sunny_outlined, left: _left!.estacao, right: _right!.estacao),
          _ComparisonRow(label: 'Horário', icon: Icons.schedule_outlined, left: _left!.horario, right: _right!.horario),
          _ComparisonRow(label: 'Avaliação', icon: Icons.star_rounded, left: _left!.rating != null ? '${_left!.rating!.toStringAsFixed(1)} (${_left!.ratingCount ?? 0})' : null, right: _right!.rating != null ? '${_right!.rating!.toStringAsFixed(1)} (${_right!.ratingCount ?? 0})' : null),
          _ComparisonRow(label: 'Preço', icon: Icons.attach_money, left: _left!.preco, right: _right!.preco),
          _ComparisonRow(label: 'Custo-Benefício', icon: Icons.trending_up, left: _left!.cusBeneficio, right: _right!.cusBeneficio),
          _ComparisonRow(label: 'Gênero', icon: Icons.person_outline, left: _left!.genero, right: _right!.genero),
          _ComparisonRow(label: 'Perfumista', icon: Icons.brush_outlined, left: _left!.perfumista, right: _right!.perfumista),
          _ComparisonRow(label: 'Ano', icon: Icons.calendar_today_outlined, left: _left!.ano, right: _right!.ano),

          // AI Difference
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OlfatoTokens.plum.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
              border: Border.all(color: OlfatoTokens.plum.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.auto_awesome, size: 14, color: OlfatoTokens.plum),
                  const SizedBox(width: 6),
                  Text('Diferença principal (IA)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: OlfatoTokens.plum)),
                ]),
                const SizedBox(height: 8),
                _diferencaPrincipal != null
                    ? Text(_diferencaPrincipal!, style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.ink, height: 1.4))
                    : Row(children: [
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: OlfatoTokens.plum, strokeWidth: 1.5)),
                        const SizedBox(width: 8),
                        Text('Analisando...', style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray, fontStyle: FontStyle.italic)),
                      ]),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // "Quero mais opções" CTA
          _buildAuraCTA(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 64,
              color: OlfatoTokens.plum.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Selecione dois perfumes para comparar',
              textAlign: TextAlign.center,
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Escolha dois perfumes da sua coleção ou explore para adicioná-los ao comparador.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: OlfatoTokens.gray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectSecondPerfume() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Show perfume 1 card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OlfatoTokens.mist,
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
              border: Border.all(color: OlfatoTokens.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 60,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  clipBehavior: Clip.antiAlias,
                  child: _left!.imageUrl != null && _proxyUrl(_left!.imageUrl).isNotEmpty
                      ? Image.network(_proxyUrl(_left!.imageUrl), fit: BoxFit.contain)
                      : const Icon(Icons.local_florist, color: OlfatoTokens.plum),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_left!.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: OlfatoTokens.ink)),
                      Text(_left!.brand, style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.plum)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: OlfatoTokens.green, size: 20),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // VS divider
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: OlfatoTokens.plum, shape: BoxShape.circle),
            child: Text('VS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),

          const SizedBox(height: 16),

          // Search for second perfume
          Text('Comparar com...', style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
          const SizedBox(height: 12),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar perfume por nome ou marca',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.gray),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.search, color: OlfatoTokens.plum, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl), borderSide: BorderSide(color: OlfatoTokens.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl), borderSide: BorderSide(color: OlfatoTokens.borderLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl), borderSide: BorderSide(color: OlfatoTokens.plum)),
              suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: OlfatoTokens.plum))) : null,
            ),
            style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.ink),
            onChanged: _onSearchChanged,
          ),

          const SizedBox(height: 12),

          // Search results
          ..._searchResults.map((p) => _buildSearchResultItem(p)),
        ],
      ),
    );
  }

  Timer? _searchDebounce;

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final response = await ApiClient().dio.get('/perfumes/search', queryParameters: {'q': query});
      final results = (response.data as List).map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) setState(() { _searchResults = results.take(8).toList(); _isSearching = false; });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Widget _buildSearchResultItem(Map<String, dynamic> perfume) {
    final name = perfume['name'] as String? ?? '';
    final brand = perfume['brand'] as String? ?? '';
    final imageUrl = _proxyUrl(perfume['image_url'] as String?);
    final perfumeId = perfume['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        setState(() {
          _perfume2Id = perfumeId;
          _searchResults = [];
          _searchController.clear();
        });
        _loadComparison();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 50,
              decoration: BoxDecoration(color: OlfatoTokens.mist, borderRadius: BorderRadius.circular(6)),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 18))
                  : const Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: OlfatoTokens.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(brand, style: GoogleFonts.inter(fontSize: 11, color: OlfatoTokens.gray)),
                ],
              ),
            ),
            Icon(Icons.compare_arrows, color: OlfatoTokens.plum, size: 18),
          ],
        ),
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
              'Não foi possível carregar a comparação.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: OlfatoTokens.gray,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadComparison,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: OlfatoTokens.plum,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a text value widget — shows "Indisponível" if the value is null/empty.
  Widget _buildTextValue(String? value) {
    final displayValue =
        (value != null && value.isNotEmpty) ? value : 'Indisponível';
    final isUnavailable = value == null || value.isEmpty;

    return Text(
      displayValue,
      style: GoogleFonts.inter(
        fontSize: 13,
        height: 1.4,
        color: isUnavailable ? OlfatoTokens.gray : OlfatoTokens.ink,
        fontStyle: isUnavailable ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  Widget _buildRating(double? rating, int? count) {
    if (rating == null) return _buildTextValue(null);
    return Row(
      children: [
        Icon(Icons.star_rounded, color: OlfatoTokens.amber, size: 14),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: OlfatoTokens.ink),
        ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text('($count)', style: GoogleFonts.inter(fontSize: 10, color: OlfatoTokens.gray)),
        ],
      ],
    );
  }

  Widget _buildLoadingOrEmpty() {
    return Row(
      children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: OlfatoTokens.plum, strokeWidth: 1.5)),
        const SizedBox(width: 8),
        Text('Analisando com IA...', style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray, fontStyle: FontStyle.italic)),
      ],
    );
  }

  /// Builds a categorical scale bar for Fixação/Projeção.
  /// Shows "Indisponível" if value is null.
  Widget _buildScaleBar({
    required String? value,
    required List<String> categories,
  }) {
    if (value == null || value.isEmpty) {
      return Text(
        'Indisponível',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: OlfatoTokens.gray,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final activeIndex = categories.indexOf(value.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scale bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: List.generate(categories.length, (i) {
              final isActive = i <= activeIndex && activeIndex >= 0;
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i < categories.length - 1 ? 2 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? OlfatoTokens.plum.withValues(alpha: 0.3 + (i * 0.3))
                        : OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        // Category labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.map((cat) {
            final isSelected = cat.toLowerCase() == value.toLowerCase();
            return Text(
              cat,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? OlfatoTokens.plum : OlfatoTokens.gray,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAuraCTA() {
    return GestureDetector(
      onTap: _openAuraWithContext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: OlfatoTokens.auraGradient,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          boxShadow: [OlfatoTokens.cardShadow],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Quero mais opções',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAuraWithContext() {
    final leftName = _left?.name ?? '';
    final rightName = _right?.name ?? '';
    final message =
        'Estou comparando $leftName e $rightName. Quero mais opções similares.';
    context.push('/chat?initialMessage=${Uri.encodeComponent(message)}');
  }

  void _navigateToDetail(String perfumeId) {
    context.push('/perfume/$perfumeId');
  }
}

// ─── ComparisonHeader ─────────────────────────────────────────────────────────

/// Displays two perfume cards side by side with name, brand, and image.
class _ComparisonHeader extends StatelessWidget {
  final _ComparisonPerfume left;
  final _ComparisonPerfume right;
  final String Function(String?) proxyUrl;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;

  const _ComparisonHeader({
    required this.left,
    required this.right,
    required this.proxyUrl,
    required this.onTapLeft,
    required this.onTapRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPerfumeCard(left, onTapLeft)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 40),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: OlfatoTokens.plum,
              shape: BoxShape.circle,
            ),
            child: Text(
              'VS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Expanded(child: _buildPerfumeCard(right, onTapRight)),
      ],
    );
  }

  Widget _buildPerfumeCard(_ComparisonPerfume perfume, VoidCallback onTap) {
    final imageUrl = proxyUrl(perfume.imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Column(
          children: [
            // Perfume image
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
                border: Border.all(color: OlfatoTokens.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            const SizedBox(height: 10),
            // Name
            Text(
              perfume.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ebGaramond(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 4),
            // Brand
            Text(
              perfume.brand,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: OlfatoTokens.plum,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Center(
      child: Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 32),
    );
  }
}

// ─── ComparisonField ──────────────────────────────────────────────────────────

/// A labeled comparison row with left and right values.
/// If [isFull] is true, [leftWidget] spans the full width (used for AI text).
class _ComparisonField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget leftWidget;
  final Widget? rightWidget;
  final bool isFull;

  const _ComparisonField({
    required this.label,
    required this.icon,
    required this.leftWidget,
    this.rightWidget,
    this.isFull = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Label row
          Row(
            children: [
              Icon(icon, size: 16, color: OlfatoTokens.plum),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: OlfatoTokens.plum,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Values
          if (isFull)
            leftWidget
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftWidget),
                const SizedBox(width: 16),
                Expanded(child: rightWidget ?? const SizedBox.shrink()),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── New comparison row: two separate cards side by side ──────────────────────

class _ComparisonRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? left;
  final String? right;

  const _ComparisonRow({required this.label, required this.icon, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(children: [
            Icon(icon, size: 13, color: OlfatoTokens.plum),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: OlfatoTokens.plum)),
          ]),
          const SizedBox(height: 6),
          // Two cards side by side
          Row(
            children: [
              Expanded(child: _valueCard(left)),
              const SizedBox(width: 8),
              Expanded(child: _valueCard(right)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueCard(String? value) {
    final hasValue = value != null && value.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OlfatoTokens.borderLight),
      ),
      child: Text(
        hasValue ? value! : '—',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: hasValue ? OlfatoTokens.ink : OlfatoTokens.gray,
          height: 1.3,
        ),
      ),
    );
  }
}

class _ComparisonScaleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? leftVal;
  final String? rightVal;
  final List<String> categories;

  const _ComparisonScaleRow({required this.label, required this.icon, this.leftVal, this.rightVal, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: OlfatoTokens.plum),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: OlfatoTokens.plum)),
          ]),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _scaleCard(leftVal)),
              const SizedBox(width: 8),
              Expanded(child: _scaleCard(rightVal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scaleCard(String? value) {
    final activeIndex = value != null ? categories.indexOf(value.toLowerCase()) : -1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OlfatoTokens.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(categories.length, (i) {
              final isActive = i <= activeIndex && activeIndex >= 0;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < categories.length - 1 ? 2 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? OlfatoTokens.plum.withValues(alpha: 0.3 + (i * 0.25)) : OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? '—',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: value != null ? OlfatoTokens.plum : OlfatoTokens.gray),
          ),
        ],
      ),
    );
  }
}
