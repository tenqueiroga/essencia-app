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

/// Proxies fimgs.net URLs through the backend image proxy.
String _proxyImg(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.contains('fimgs.net')) {
    return 'https://essencia.laravel.cloud/api/image-proxy?url=${Uri.encodeComponent(url)}';
  }
  return url;
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
              const SizedBox(height: 28),
              const _RotatingSection(),
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

// ─── WeatherCard (clickable → /explore) ───────────────────────────────────────

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
      child: GestureDetector(
        onTap: () {
          final family = temp != null ? getWeatherFamily(temp) : null;
          if (family != null) {
            context.push('/explore?family=${Uri.encodeComponent(family.split('/').first)}');
          } else {
            context.push('/explore');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OlfatoTokens.mist,
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
            border: Border.all(color: OlfatoTokens.borderLight),
            boxShadow: [OlfatoTokens.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: sun icon + temperature
                  if (temp != null) ...[
                    Column(
                      children: [
                        const Icon(
                          Icons.wb_sunny_rounded,
                          color: OlfatoTokens.amber,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${temp.round()}°',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: OlfatoTokens.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                  ],
                  // Right: descriptive text
                  Expanded(
                    child: Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: OlfatoTokens.ink,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              // Location below
              if (city != null && state != null) ...[
                const SizedBox(height: 12),
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
                        fontSize: 12,
                        color: OlfatoTokens.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CompatibilitySection (2 cards side by side) ──────────────────────────────

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
        final list = data is List
            ? data
            : (data is Map ? (data['perfumes'] as List? ?? []) : []);
        setState(() {
          _suggestions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with "Ver todos >"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/explore'),
                  child: Text(
                    'O que combina com hoje?',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: OlfatoTokens.ink,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/explore'),
                child: Text(
                  'Ver todos >',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OlfatoTokens.plum,
                  ),
                ),
              ),
            ],
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
          _buildTwoColumnRow(),
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
                onPressed: () => context.push('/explore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OlfatoTokens.plum,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(OlfatoTokens.radiusControl),
                  ),
                ),
                child: Text(
                  'Explorar Perfumes',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnRow() {
    // Show only first 2 suggestions
    final items = _suggestions.take(2).toList();

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
          final perfumeId = perfume['id']?.toString() ?? item['perfume_id']?.toString() ?? '';

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: index == items.length - 1 ? 0 : 8,
              ),
              child: GestureDetector(
                onTap: () {
                  if (perfumeId.isNotEmpty) {
                    context.push('/perfume/$perfumeId');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(OlfatoTokens.radiusCard),
                    border: Border.all(color: OlfatoTokens.borderLight),
                    boxShadow: [OlfatoTokens.cardShadow],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular image (80px)
                        Container(
                          width: 80,
                          height: 80,
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
                                    size: 32,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_florist,
                                  color: OlfatoTokens.plum,
                                  size: 32,
                                ),
                        ),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: OlfatoTokens.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        // Brand
                        Text(
                          brand,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: OlfatoTokens.gray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        // Match badge (green)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: OlfatoTokens.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${score.toInt()}% match',
                            style: GoogleFonts.inter(
                              fontSize: 11,
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

// ─── AuraCTA (with logo image) ────────────────────────────────────────────────

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
              // Aura avatar — logo image with gradient fallback
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/olfato_simbolo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
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

// ─── RotatingSection (dupes OR affordable, alternating) ───────────────────────

class _RotatingSection extends StatefulWidget {
  const _RotatingSection();

  @override
  State<_RotatingSection> createState() => _RotatingSectionState();
}

class _RotatingSectionState extends State<_RotatingSection> {
  List<dynamic> _items = [];
  bool _loading = true;
  late bool _showDupes;

  @override
  void initState() {
    super.initState();
    _showDupes = DateTime.now().millisecond % 2 == 0;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final endpoint =
          _showDupes ? '/perfumes/dupes-highlight' : '/perfumes/affordable';
      final response = await ApiClient().dio.get(endpoint);
      if (mounted) {
        final data = response.data;
        List list;
        if (data is List) {
          list = data;
        } else if (data is Map) {
          list = data['data'] as List? ?? data['perfumes'] as List? ?? [];
        } else {
          list = [];
        }
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _items.isEmpty) return const SizedBox.shrink();

    final title = _showDupes ? 'Dupes recomendados' : 'Até R\$ 300';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
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
            itemCount: _items.length,
            itemBuilder: (context, index) {
              if (_showDupes) {
                return _buildDupeCard(_items[index] as Map<String, dynamic>);
              } else {
                return _buildAffordableCard(
                    _items[index] as Map<String, dynamic>);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDupeCard(Map<String, dynamic> item) {
    final dupe = item['dupe'] as Map<String, dynamic>? ?? {};
    final name = dupe['name'] as String? ?? '';
    final brand = dupe['brand'] as String? ?? '';
    final imageUrl = _proxyImg(dupe['image_url'] as String?);
    final perfumeId = dupe['id']?.toString() ?? '';
    final accuracy = (item['accuracy_score'] ?? 0) as num;

    return GestureDetector(
      onTap: () {
        if (perfumeId.isNotEmpty) context.push('/perfume/$perfumeId');
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.borderLight),
          boxShadow: [OlfatoTokens.cardShadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: OlfatoTokens.mist,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
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
              const SizedBox(height: 8),
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
              const Spacer(),
              // Accuracy badge (pitanga for dupes)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: OlfatoTokens.pitanga.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(accuracy.toInt() * 10)}% similar',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: OlfatoTokens.pitanga,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAffordableCard(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? '';
    final brand = item['brand'] as String? ?? '';
    final imageUrl = _proxyImg(item['image_url'] as String?);
    final perfumeId = item['id']?.toString() ?? '';
    final price = double.tryParse(item['average_price']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () {
        if (perfumeId.isNotEmpty) context.push('/perfume/$perfumeId');
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.borderLight),
          boxShadow: [OlfatoTokens.cardShadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: OlfatoTokens.mist,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
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
              const SizedBox(height: 8),
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
              const Spacer(),
              // Price badge (green for affordable)
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
                  'R\$ ${price.toInt()}',
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
    );
  }
}


