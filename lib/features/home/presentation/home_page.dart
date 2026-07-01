import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/perfume_detail_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = (authState.user?['name'] ?? 'Perfumista').toString().split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + avatar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    // Logo mark
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.gold]),
                      ),
                      child: Center(child: Text('E',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 16, fontWeight: FontWeight.w900,
                          color: AppColors.background))),
                    ),
                    const SizedBox(width: 10),
                    Text('ESSÊNCIA',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, letterSpacing: 1)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border)),
                        child: Center(child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.accent))),
                      ),
                    ),
                  ],
                ),
              ),

              // Greeting
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(text: TextSpan(
                      style: Theme.of(context).textTheme.headlineMedium,
                      children: [
                        const TextSpan(text: 'Encontre sua\n'),
                        TextSpan(text: 'essência ', style: TextStyle(color: AppColors.accent)),
                        const TextSpan(text: 'de hoje'),
                      ],
                    )),
                    const SizedBox(height: 4),
                    const Text('Baseado no seu perfil e no momento',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Suggestion
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SuggestionCard(),
              ),
              const SizedBox(height: 28),

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('ACESSO RÁPIDO'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _QuickTile(icon: Icons.auto_awesome, label: 'Essence AI',
                        color: AppColors.accent, onTap: () => context.go('/chat')),
                      const SizedBox(width: 10),
                      _QuickTile(icon: Icons.search_rounded, label: 'Explorar',
                        color: AppColors.gold, onTap: () => context.go('/explore')),
                      const SizedBox(width: 10),
                      _QuickTile(icon: Icons.book_outlined, label: 'Diário',
                        color: AppColors.success, onTap: () => context.go('/journal')),
                      const SizedBox(width: 10),
                      _QuickTile(icon: Icons.qr_code_scanner_rounded, label: 'Scan',
                        color: const Color(0xFF9B7AE8), onTap: () => context.go('/explore')),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Feed do influencer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const _SectionLabel('ÚLTIMOS REVIEWS'),
              ),
              const SizedBox(height: 12),
              _FeedSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted,
      letterSpacing: 1.5));
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15))),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    ));
  }
}


class _SuggestionCard extends StatefulWidget {
  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final response = await ApiClient().dio.get('/suggestions/seasonal');
      if (mounted) setState(() { _data = response.data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  String _proxyImg(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) return 'http://localhost:8000/api/image-proxy?url=${Uri.encodeComponent(url)}';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Container(
      height: 100, decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: const Center(child: CircularProgressIndicator(
        color: AppColors.accent, strokeWidth: 2)),
    );

    final suggestion = _data?['suggestion'] as Map<String, dynamic>?;
    if (suggestion == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border)),
        child: const Row(children: [
          Icon(Icons.local_florist, color: AppColors.accent, size: 22),
          SizedBox(width: 12),
          Expanded(child: Text(
            'Adicione perfumes e classifique por estação para receber sugestões.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ]),
      );
    }

    final perfume = suggestion['perfume'] as Map<String, dynamic>?;
    final reason = suggestion['reason'] as String? ?? '';
    final imgUrl = _proxyImg(perfume?['image_url'] as String?);

    return GestureDetector(
      onTap: () { if (perfume != null) openPerfumeDetailSheet(context, perfume); },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.elevated, AppColors.surface]),
          border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top label
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('PARA AGORA', style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600,
                  color: AppColors.accent, letterSpacing: 1)),
              ]),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(children: [
                Container(
                  width: 54, height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imgUrl.isNotEmpty
                      ? Image.network(imgUrl, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_florist, color: AppColors.accent, size: 22))
                      : const Icon(Icons.local_florist, color: AppColors.accent, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(perfume?['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(perfume?['brand'] ?? '',
                      style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6)),
                      child: Text('✦ $reason',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ),
                  ],
                )),
                const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted, size: 14),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}


class _FeedSection extends StatefulWidget {
  const _FeedSection();
  @override
  State<_FeedSection> createState() => _FeedSectionState();
}

class _FeedSectionState extends State<_FeedSection> {
  List<dynamic> _feedItems = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final response = await ApiClient().dio.get('/feed');
      if (mounted) setState(() => _feedItems = response.data as List<dynamic>);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_feedItems.isEmpty) return const SizedBox.shrink();

    String _proxyThumb(String? url) {
      if (url == null || url.isEmpty) return '';
      return 'http://localhost:8000/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _feedItems.length,
        itemBuilder: (_, i) {
          final item = _feedItems[i];
          return GestureDetector(
            onTap: () {
              final url = item['instagram_url'] as String?;
              if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail — full width
                    if (item['thumbnail_url'] != null && (item['thumbnail_url'] as String).isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Stack(
                          children: [
                            Image.network(
                              _proxyThumb(item['thumbnail_url']),
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 220, color: AppColors.elevated,
                                child: const Center(child: Icon(Icons.play_arrow_rounded, color: AppColors.accent, size: 32))),
                            ),
                            // Play icon overlay
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.elevated,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                        child: const Center(child: Icon(Icons.play_arrow_rounded, color: AppColors.accent, size: 32)),
                      ),
                    // Text
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? 'Review',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6)),
                            child: const Text('▶ Assistir no Instagram',
                              style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
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
