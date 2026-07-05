import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/location_service.dart';

// ─── Pure helper functions (exported for testing) ─────────────────────────────

/// Always returns 👋 emoji (prototype standard).
String getTimeOfDayEmoji(int hour) {
  return '👋';
}

/// Returns perfume family suggestion based on temperature in °C.
String getWeatherFamily(double temp) {
  if (temp >= 30) return 'Cítrica/Aquática';
  if (temp >= 25) return 'Fresca/Cítrica';
  if (temp >= 20) return 'Floral/Aromática';
  if (temp >= 15) return 'Amadeirada/Oriental';
  return 'Oriental/Gourmand';
}

/// Returns descriptive weather text based on temperature.
String getWeatherDescription(double? temp) {
  if (temp == null) return 'Fragrâncias versáteis para qualquer momento do dia.';
  if (temp >= 30) return 'Quente e ensolarado. Perfeito para cítricos, aquáticos e notas frescas.';
  if (temp >= 25) return 'Agradável e morno. Combina com perfumes frescos e cítricos leves.';
  if (temp >= 20) return 'Clima ameno. Ideal para florais, aromáticos e madeiras suaves.';
  if (temp >= 15) return 'Friozinho chegando. Hora de amadeirados e orientais.';
  return 'Frio intenso. Aposte em orientais, gourmands e madeiras.';
}

/// Returns the first character of a name, uppercased.
/// Returns 'U' for empty strings.
String getAvatarLetter(String name) {
  if (name.isEmpty) return 'U';
  return name[0].toUpperCase();
}

// ─── HomePage ─────────────────────────────────────────────────────────────────

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = (authState.user?['name'] ?? 'Perfumista')
        .toString()
        .split(' ')
        .first;

    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingHeader(userName: userName),
              const SizedBox(height: 24),
              const _WeatherCard(),
              const SizedBox(height: 28),
              const _CompatibilitySection(),
              const SizedBox(height: 28),
              const _AuraCTA(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── GreetingHeader ───────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String userName;
  const _GreetingHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    final letter = getAvatarLetter(userName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $userName 👋',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: OlfatoTokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Que bom ter vc por aqui.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: OlfatoTokens.gray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: OlfatoTokens.plum.withValues(alpha: 0.12),
                border: Border.all(
                  color: OlfatoTokens.plum.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OlfatoTokens.plum,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WeatherCard ──────────────────────────────────────────────────────────────

class _WeatherCard extends StatefulWidget {
  const _WeatherCard();

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  Map<String, dynamic>? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final weather = await LocationService.updateWeather();
      if (mounted) {
        setState(() {
          _weather = weather;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final temp = (_weather?['temperature'] as num?)?.toDouble();
    final city = _weather?['city'] as String?;
    final state = _weather?['state'] as String?;
    final description = getWeatherDescription(temp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: sun icon + temperature
                if (temp != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny_rounded,
                        color: OlfatoTokens.amber,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${temp.round()}°',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: OlfatoTokens.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                ],
                // Right: descriptive text
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: OlfatoTokens.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            // Location below
            if (city != null && state != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: OlfatoTokens.gray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$city, $state',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: OlfatoTokens.gray,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── CompatibilitySection (3-column row) ──────────────────────────────────────

class _CompatibilitySection extends StatefulWidget {
  const _CompatibilitySection();

  @override
  State<_CompatibilitySection> createState() => _CompatibilitySectionState();
}

class _CompatibilitySectionState extends State<_CompatibilitySection> {
  List<dynamic> _suggestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final response =
          await ApiClient().dio.get('/suggestions/compatibility');
      if (mounted) {
        final data = response.data;
        final list = data is List ? data : (data is Map ? (data['perfumes'] as List? ?? []) : []);
        setState(() {
          _suggestions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _proxyImg(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'https://essencia.laravel.cloud/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'O que combina com hoje?',
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: 180,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: OlfatoTokens.plum,
                  ),
                ),
              ),
            ),
          )
        else if (_suggestions.isEmpty)
          _buildEmptyState()
        else
          _buildThreeColumnRow(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_florist_outlined,
                  color: OlfatoTokens.plum.withValues(alpha: 0.6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Adicione perfumes à sua coleção para receber sugestões do que combina com o seu dia.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: OlfatoTokens.gray,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/explore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OlfatoTokens.plum,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
                  ),
                ),
                child: Text(
                  'Explorar Perfumes',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeColumnRow() {
    // Show only first 3 suggestions
    final items = _suggestions.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final perfume = item['perfume'] as Map<String, dynamic>? ?? item;
          final name = perfume['name'] as String? ?? '';
          final brand = perfume['brand'] as String? ?? '';
          final imageUrl = _proxyImg(perfume['image_url'] as String?);
          final score =
              (item['compatibility_score'] ?? item['score'] ?? 0) as num;
          final perfumeId = perfume['id']?.toString() ?? '';

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == items.length - 1 ? 0 : 6,
              ),
              child: GestureDetector(
                onTap: () {
                  if (perfumeId.isNotEmpty) {
                    context.go('/perfume/$perfumeId');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(OlfatoTokens.radiusCard),
                    border: Border.all(color: OlfatoTokens.borderLight),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        color: OlfatoTokens.ink.withValues(alpha: 0.06),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular image
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: OlfatoTokens.mist,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.local_florist,
                                    color: OlfatoTokens.plum,
                                    size: 28,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_florist,
                                  color: OlfatoTokens.plum,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(height: 10),
                        // Name
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: OlfatoTokens.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        // Brand
                        Text(
                          brand,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: OlfatoTokens.gray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Match badge (green)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: OlfatoTokens.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${score.toInt()}% match',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: OlfatoTokens.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── AuraCTA ──────────────────────────────────────────────────────────────────

class _AuraCTA extends StatelessWidget {
  const _AuraCTA();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => context.go('/chat'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: OlfatoTokens.mist,
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
            border: Border.all(color: OlfatoTokens.borderLight),
          ),
          child: Row(
            children: [
              // Aura avatar (gradient circle)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: OlfatoTokens.auraGradient,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pergunte à Aura',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: OlfatoTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tire dúvidas e receba recomendações personalizadas',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OlfatoTokens.gray,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: OlfatoTokens.gray,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
