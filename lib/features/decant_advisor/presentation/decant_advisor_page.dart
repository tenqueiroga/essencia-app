import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';

/// Model representing a volume option from the decant advisor API.
class _VolumeOption {
  final int ml;
  final String justification;

  const _VolumeOption({required this.ml, required this.justification});

  factory _VolumeOption.fromJson(Map<String, dynamic> json) {
    final justification = (json['justification'] as String? ?? '').length > 140
        ? (json['justification'] as String).substring(0, 140)
        : (json['justification'] as String? ?? '');
    return _VolumeOption(
      ml: (json['ml'] as num?)?.toInt() ?? 0,
      justification: justification,
    );
  }
}

/// Model for the perfume info returned by the decant advisor API.
class _PerfumeInfo {
  final String name;
  final String brand;
  final String? imageUrl;

  const _PerfumeInfo({
    required this.name,
    required this.brand,
    this.imageUrl,
  });

  factory _PerfumeInfo.fromJson(Map<String, dynamic> json) {
    return _PerfumeInfo(
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }
}

/// Consultor de Decantes page — recommends ideal decant volumes.
///
/// Route: `/decant-advisor?perfume_id=xxx`
///
/// Calls POST `/api/chat/decant-advisor` with the perfume_id to get
/// volume recommendations (2ml, 5ml, 10ml) with justifications and
/// a recommended volume badge.
class DecantAdvisorPage extends StatefulWidget {
  final String? perfumeId;

  const DecantAdvisorPage({super.key, this.perfumeId});

  @override
  State<DecantAdvisorPage> createState() => _DecantAdvisorPageState();
}

class _DecantAdvisorPageState extends State<DecantAdvisorPage> {
  _PerfumeInfo? _perfume;
  List<_VolumeOption> _volumes = [];
  int? _recommendedVolume;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAdvisorData();
  }

  bool get _hasPerfumeId =>
      widget.perfumeId != null && widget.perfumeId!.isNotEmpty;

  Future<void> _loadAdvisorData() async {
    if (!_hasPerfumeId) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final response = await ApiClient()
          .dio
          .post('/chat/decant-advisor', data: {
            'perfume_id': widget.perfumeId,
          })
          .timeout(const Duration(seconds: 15));

      final data = response.data as Map<String, dynamic>;

      final perfumeJson = data['perfume'] as Map<String, dynamic>?;
      final volumesJson = data['volumes'] as List?;
      final recommendedVol = (data['recommended_volume'] as num?)?.toInt();

      if (mounted) {
        setState(() {
          _perfume =
              perfumeJson != null ? _PerfumeInfo.fromJson(perfumeJson) : null;
          _volumes = volumesJson
                  ?.map((v) =>
                      _VolumeOption.fromJson(v as Map<String, dynamic>))
                  .toList() ??
              [];
          _recommendedVolume = recommendedVol;
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
          'Consultor de Decantes',
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

    // Empty state: no perfume selected
    if (!_hasPerfumeId) {
      return _buildEmptyState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_perfume == null || _volumes.isEmpty) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Perfume info header
          _buildPerfumeHeader(),
          const SizedBox(height: 32),

          // Volume cards
          ..._volumes.map((volume) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _VolumeCard(
                  volume: volume,
                  isRecommended: volume.ml == _recommendedVolume,
                ),
              )),

          const SizedBox(height: 16),

          // CTA
          if (_recommendedVolume != null) _buildCTA(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPerfumeHeader() {
    final imageUrl = _proxyUrl(_perfume!.imageUrl);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OlfatoTokens.mist,
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        border: Border.all(color: OlfatoTokens.borderLight),
      ),
      child: Row(
        children: [
          // Perfume image
          Container(
            width: 72,
            height: 90,
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
          const SizedBox(width: 16),
          // Perfume name, brand, longevity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _perfume!.name,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: OlfatoTokens.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _perfume!.brand,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: OlfatoTokens.plum,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Longevity rating indicator
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: OlfatoTokens.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Longa duração',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: OlfatoTokens.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              Icons.science_outlined,
              size: 64,
              color: OlfatoTokens.plum.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Selecione um perfume',
              textAlign: TextAlign.center,
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Escolha um perfume para receber recomendações de volume de decante ideal para você.',
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
              'Não foi possível carregar as recomendações.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: OlfatoTokens.gray,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAdvisorData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: OlfatoTokens.plum,
                foregroundColor: Colors.white,
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

  Widget _buildCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: OlfatoTokens.auraGradient,
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        boxShadow: [OlfatoTokens.cardShadow],
      ),
      child: Text(
        'Melhor escolha para você: ${_recommendedVolume}ml',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
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

// ─── VolumeCard ─────────────────────────────────────────────────────────────

/// A card displaying a volume option (2ml, 5ml, or 10ml) with justification.
/// Shows a "RECOMENDADO" badge if it's the recommended option.
class _VolumeCard extends StatelessWidget {
  final _VolumeOption volume;
  final bool isRecommended;

  const _VolumeCard({
    required this.volume,
    required this.isRecommended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRecommended ? OlfatoTokens.green.withValues(alpha: 0.05) : OlfatoTokens.mist,
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        border: Border.all(
          color: isRecommended ? OlfatoTokens.green : OlfatoTokens.borderLight,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isRecommended ? [OlfatoTokens.cardShadow] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: volume + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Volume label
              Text(
                '${volume.ml}ml',
                style: GoogleFonts.ebGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isRecommended ? OlfatoTokens.green : OlfatoTokens.ink,
                ),
              ),
              const Spacer(),
              // "RECOMENDADO" badge
              if (isRecommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: OlfatoTokens.green,
                    borderRadius:
                        BorderRadius.circular(OlfatoTokens.radiusControl),
                  ),
                  child: Text(
                    'RECOMENDADO',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Justification text
          Text(
            volume.justification,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              color: OlfatoTokens.gray,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
