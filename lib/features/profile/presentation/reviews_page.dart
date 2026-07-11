import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<dynamic> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final response = await ApiClient().dio.get('/reviews');
      if (mounted) {
        setState(() {
          _reviews = response.data as List;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) {
      return 'https://perfumia.com.br/api/image-proxy?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  String _typeLabel(String? type) {
    return switch (type) {
      'perfume' => 'Perfume',
      'decant' => 'Decante',
      'amostra' => 'Amostra',
      'ja_tive' => 'Já Tive',
      _ => 'Coleção',
    };
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
          'Minhas Avaliações',
          style: GoogleFonts.ebGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: OlfatoTokens.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OlfatoTokens.plum))
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 56, color: OlfatoTokens.gray.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma avaliação ainda',
                        style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.gray),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avalie perfumes na ficha para vê-los aqui',
                        style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final perfume = review['perfume'] as Map<String, dynamic>?;
                    if (perfume == null) return const SizedBox.shrink();

                    final imageUrl = _proxyUrl(perfume['image_url'] as String?);
                    final name = perfume['name'] as String? ?? '';
                    final brand = perfume['brand'] as String? ?? '';
                    final type = review['type'] as String?;
                    final finalScore = review['final_score'] as int?;

                    return GestureDetector(
                      onTap: () => context.push('/perfume/${perfume['id']}?tab=3'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 64,
                                  height: 80,
                                  color: Colors.white,
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(imageUrl, fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 24)))
                                      : const Center(child: Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 24)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: OlfatoTokens.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      brand,
                                      style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.plum),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (type != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: OlfatoTokens.plum.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _typeLabel(type),
                                              style: GoogleFonts.inter(fontSize: 10, color: OlfatoTokens.plum, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        const Spacer(),
                                        if (finalScore != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(5, (i) {
                                              // Map 1-10 score to 5 stars
                                              final starValue = (i + 1) * 2;
                                              return Icon(
                                                finalScore >= starValue ? Icons.star_rounded : Icons.star_border_rounded,
                                                size: 16,
                                                color: OlfatoTokens.amber,
                                              );
                                            }),
                                          ),
                                      ],
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
