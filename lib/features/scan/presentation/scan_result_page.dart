import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/olfato_tokens.dart';

/// Data class representing scan identification result.
///
/// Passed to [ScanResultPage] via GoRouter extra or constructed
/// from route query parameters.
class ScanResultData {
  final String name;
  final String house;
  final String? volume;
  final int? compatibilityScore; // 0–100, null if user has no collection
  final String description; // max 300 characters
  final List<String> tags; // max 5 climate/occasion tags

  const ScanResultData({
    required this.name,
    required this.house,
    this.volume,
    this.compatibilityScore,
    required this.description,
    required this.tags,
  });

  /// Constructs from a JSON map (e.g., API response).
  factory ScanResultData.fromJson(Map<String, dynamic> json) {
    final rawTags = (json['tags'] as List<dynamic>?)
            ?.map((t) => t.toString())
            .take(5)
            .toList() ??
        [];

    final rawDescription = (json['description'] as String?) ?? '';
    final description = rawDescription.length > 300
        ? rawDescription.substring(0, 300)
        : rawDescription;

    final score = json['compatibility_score'] as int?;

    return ScanResultData(
      name: json['name'] as String? ?? '',
      house: json['house'] as String? ?? json['brand'] as String? ?? '',
      volume: json['volume'] as String?,
      compatibilityScore: score?.clamp(0, 100),
      description: description,
      tags: rawTags,
    );
  }
}

/// Page displayed after a successful scan identification.
///
/// Always uses dark theme (Ink background, Vanilla text) regardless
/// of the app's current theme mode.
class ScanResultPage extends StatelessWidget {
  final ScanResultData? resultData;

  const ScanResultPage({super.key, this.resultData});

  @override
  Widget build(BuildContext context) {
    // If no data is provided, show a timeout/error state
    if (resultData == null) {
      return _ScanErrorView();
    }

    return Theme(
      data: _buildDarkTheme(context),
      child: Scaffold(
        backgroundColor: OlfatoTokens.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: OlfatoTokens.vanilla),
            onPressed: () => context.go('/scan'),
          ),
          title: const Text(
            'Resultado',
            style: TextStyle(
              color: OlfatoTokens.vanilla,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(OlfatoTokens.spaceUnit * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScanResultCard(data: resultData!),
                const SizedBox(height: OlfatoTokens.spaceUnit * 3),
                _AuraCTA(data: resultData!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: OlfatoTokens.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: OlfatoTokens.pitanga,
        secondary: OlfatoTokens.plum,
        surface: OlfatoTokens.surfaceDark,
        error: OlfatoTokens.error,
      ),
    );
  }
}

/// Card widget displaying the scan identification result.
///
/// Shows: perfume name, house/brand, volume, compatibility score (if available),
/// editorial description (max 300 chars), and up to 5 tags.
class _ScanResultCard extends StatelessWidget {
  final ScanResultData data;

  const _ScanResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OlfatoTokens.spaceUnit * 3),
      decoration: BoxDecoration(
        color: OlfatoTokens.surfaceDark,
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        border: Border.all(color: OlfatoTokens.borderDark, width: 0.5),
        boxShadow: [OlfatoTokens.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Perfume name
          Text(
            data.name,
            style: const TextStyle(
              color: OlfatoTokens.vanilla,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: OlfatoTokens.spaceUnit),

          // House/brand and volume
          Text(
            [data.house, if (data.volume != null) data.volume]
                .where((s) => s != null && s.isNotEmpty)
                .join(' · '),
            style: const TextStyle(
              color: OlfatoTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: OlfatoTokens.spaceUnit * 2),

          // Compatibility score — hidden if null (user has no collection)
          if (data.compatibilityScore != null) ...[
            _CompatibilityScore(score: data.compatibilityScore!),
            const SizedBox(height: OlfatoTokens.spaceUnit * 2),
          ],

          // Editorial description (max 300 characters)
          if (data.description.isNotEmpty) ...[
            Text(
              data.description,
              style: const TextStyle(
                color: OlfatoTokens.textSecondaryDark,
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: OlfatoTokens.spaceUnit * 2),
          ],

          // Climate/occasion tags (max 5)
          if (data.tags.isNotEmpty) _TagChips(tags: data.tags),
        ],
      ),
    );
  }
}

/// Displays compatibility score as a percentage with a visual indicator.
class _CompatibilityScore extends StatelessWidget {
  final int score;

  const _CompatibilityScore({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OlfatoTokens.spaceUnit * 1.5,
            vertical: OlfatoTokens.spaceUnit,
          ),
          decoration: BoxDecoration(
            gradient: OlfatoTokens.auraGradient,
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          ),
          child: Text(
            '$score%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: OlfatoTokens.spaceUnit),
        const Text(
          'compatibilidade',
          style: TextStyle(
            color: OlfatoTokens.textSecondaryDark,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Renders up to 5 climate/occasion tag chips.
class _TagChips extends StatelessWidget {
  final List<String> tags;

  const _TagChips({required this.tags});

  @override
  Widget build(BuildContext context) {
    final displayTags = tags.take(5).toList();
    return Wrap(
      spacing: OlfatoTokens.spaceUnit,
      runSpacing: OlfatoTokens.spaceUnit,
      children: displayTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OlfatoTokens.spaceUnit * 1.5,
            vertical: OlfatoTokens.spaceUnit * 0.75,
          ),
          decoration: BoxDecoration(
            color: OlfatoTokens.backgroundDark,
            borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
            border: Border.all(color: OlfatoTokens.borderDark),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: OlfatoTokens.textSecondaryDark,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// "Perguntar à Aura" call-to-action button.
///
/// Navigates to /chat pre-loaded with the scanned perfume context
/// (name + house + compatibility score).
class _AuraCTA extends StatelessWidget {
  final ScanResultData data;

  const _AuraCTA({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToAura(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: OlfatoTokens.spaceUnit * 3,
          vertical: OlfatoTokens.spaceUnit * 2,
        ),
        decoration: BoxDecoration(
          gradient: OlfatoTokens.auraGradient,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            SizedBox(width: OlfatoTokens.spaceUnit),
            Text(
              'Perguntar à Aura',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAura(BuildContext context) {
    // Build context string with perfume info for Aura
    final scoreText = data.compatibilityScore != null
        ? ' (${data.compatibilityScore}% compatibilidade)'
        : '';
    final perfumeContext =
        'Me fale sobre ${data.name} da ${data.house}$scoreText';

    // Navigate to chat — passing initial message via query parameter
    context.go(
      Uri(
        path: '/chat',
        queryParameters: {'initialMessage': perfumeContext},
      ).toString(),
    );
  }
}

/// Error/timeout view shown when scan identification fails.
///
/// Displays error message with "Tentar novamente" (retry) and
/// "Buscar manualmente" (navigate to /explore) buttons.
class _ScanErrorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: OlfatoTokens.backgroundDark,
      ),
      child: Scaffold(
        backgroundColor: OlfatoTokens.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: OlfatoTokens.vanilla),
            onPressed: () => context.go('/scan'),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(OlfatoTokens.spaceUnit * 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: OlfatoTokens.error,
                  size: 56,
                ),
                const SizedBox(height: OlfatoTokens.spaceUnit * 3),
                const Text(
                  'Não foi possível identificar o perfume',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OlfatoTokens.vanilla,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: OlfatoTokens.spaceUnit),
                const Text(
                  'A identificação demorou mais do que o esperado. '
                  'Tente novamente ou busque manualmente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OlfatoTokens.textSecondaryDark,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: OlfatoTokens.spaceUnit * 4),

                // Retry button
                ElevatedButton(
                  onPressed: () => context.go('/scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OlfatoTokens.pitanga,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(OlfatoTokens.radiusControl),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Tentar novamente',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                const SizedBox(height: OlfatoTokens.spaceUnit * 1.5),

                // Manual search button
                OutlinedButton(
                  onPressed: () => context.go('/explore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OlfatoTokens.vanilla,
                    side: const BorderSide(color: OlfatoTokens.borderDark),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(OlfatoTokens.radiusControl),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Buscar manualmente',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
