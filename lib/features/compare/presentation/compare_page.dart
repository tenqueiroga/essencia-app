import 'dart:async';

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
  final String? cheiro;
  final String? fixacao; // categorical: curta, média, longa
  final String? projecao; // categorical: íntima, moderada, forte
  final String? preco;

  const _ComparisonPerfume({
    required this.id,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.cheiro,
    this.fixacao,
    this.projecao,
    this.preco,
  });

  factory _ComparisonPerfume.fromJson(Map<String, dynamic> json) {
    // Derive fixação category from longevity data
    String? fixacao;
    final longevityData = json['longevity_data'] as List?;
    if (longevityData != null && longevityData.isNotEmpty) {
      fixacao = _deriveLongevityCategory(longevityData);
    }

    // Derive projeção category from sillage data
    String? projecao;
    final sillageData = json['sillage_data'] as List?;
    if (sillageData != null && sillageData.isNotEmpty) {
      projecao = _deriveSillageCategory(sillageData);
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

    return _ComparisonPerfume(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      cheiro: json['description'] as String?,
      fixacao: fixacao,
      projecao: projecao,
      preco: preco,
    );
  }

  /// Maps longevity vote data to categorical labels.
  static String _deriveLongevityCategory(List<dynamic> data) {
    // Find the dominant category
    String bestName = '';
    num bestPct = 0;
    for (final item in data) {
      final pct = (item['percentage'] as num?) ?? 0;
      if (pct > bestPct) {
        bestPct = pct;
        bestName = (item['name'] as String?) ?? '';
      }
    }
    // Map to our three categories
    final lower = bestName.toLowerCase();
    if (lower.contains('fraca') || lower.contains('poor') || lower.contains('curta')) {
      return 'curta';
    } else if (lower.contains('moderada') || lower.contains('moderate') || lower.contains('média')) {
      return 'média';
    } else {
      return 'longa';
    }
  }

  /// Maps sillage vote data to categorical labels.
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
    if (lower.contains('intimate') || lower.contains('íntima') || lower.contains('soft')) {
      return 'íntima';
    } else if (lower.contains('moderate') || lower.contains('moderada')) {
      return 'moderada';
    } else {
      return 'forte';
    }
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

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  bool get _hasBothPerfumes =>
      widget.perfume1Id != null &&
      widget.perfume1Id!.isNotEmpty &&
      widget.perfume2Id != null &&
      widget.perfume2Id!.isNotEmpty;

  Future<void> _loadComparison() async {
    if (!_hasBothPerfumes) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      // Fetch both perfumes in parallel
      final results = await Future.wait([
        ApiClient().dio.get('/perfumes/${widget.perfume1Id}'),
        ApiClient().dio.get('/perfumes/${widget.perfume2Id}'),
      ]);

      final leftData = results[0].data as Map<String, dynamic>;
      final rightData = results[1].data as Map<String, dynamic>;

      final left = _ComparisonPerfume.fromJson(leftData);
      final right = _ComparisonPerfume.fromJson(rightData);

      // Fetch AI-generated difference (non-blocking — don't fail page if this errors)
      String? diferenca;
      try {
        final compareResponse = await ApiClient()
            .dio
            .post('/chat/compare', data: {
              'perfume1_id': widget.perfume1Id,
              'perfume2_id': widget.perfume2Id,
            })
            .timeout(const Duration(seconds: 10));
        diferenca = compareResponse.data['difference'] as String?;
      } catch (_) {
        // AI comparison is optional — show "Indisponível" if it fails
      }

      if (mounted) {
        setState(() {
          _left = left;
          _right = right;
          _diferencaPrincipal = diferenca;
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

    // Empty state: fewer than 2 perfumes selected
    if (!_hasBothPerfumes) {
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

          // Comparison fields
          _ComparisonField(
            label: 'Cheiro',
            icon: Icons.air,
            leftWidget: _buildTextValue(_left!.cheiro),
            rightWidget: _buildTextValue(_right!.cheiro),
          ),
          const SizedBox(height: 16),
          _ComparisonField(
            label: 'Fixação',
            icon: Icons.timer_outlined,
            leftWidget: _buildScaleBar(
              value: _left!.fixacao,
              categories: const ['curta', 'média', 'longa'],
            ),
            rightWidget: _buildScaleBar(
              value: _right!.fixacao,
              categories: const ['curta', 'média', 'longa'],
            ),
          ),
          const SizedBox(height: 16),
          _ComparisonField(
            label: 'Projeção',
            icon: Icons.surround_sound_outlined,
            leftWidget: _buildScaleBar(
              value: _left!.projecao,
              categories: const ['íntima', 'moderada', 'forte'],
            ),
            rightWidget: _buildScaleBar(
              value: _right!.projecao,
              categories: const ['íntima', 'moderada', 'forte'],
            ),
          ),
          const SizedBox(height: 16),
          _ComparisonField(
            label: 'Preço',
            icon: Icons.attach_money,
            leftWidget: _buildTextValue(_left!.preco),
            rightWidget: _buildTextValue(_right!.preco),
          ),
          const SizedBox(height: 16),
          _ComparisonField(
            label: 'Diferença principal',
            icon: Icons.compare_arrows,
            leftWidget: _buildTextValue(_diferencaPrincipal),
            rightWidget: null, // single field spanning both
            isFull: true,
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
