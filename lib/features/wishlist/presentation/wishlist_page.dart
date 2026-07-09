import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import 'wishlist_provider.dart';

class WishlistPage extends ConsumerStatefulWidget {
  const WishlistPage({super.key});

  @override
  ConsumerState<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends ConsumerState<WishlistPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final response = await ApiClient().dio.get('/wishlist');
      final data = response.data;
      final items = (data is List ? data : (data['data'] as List? ?? []))
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) {
        setState(() {
          _items = items;
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: OlfatoTokens.pitanga, size: 20),
            const SizedBox(width: 8),
            Text(
              'Wishlist',
              style: GoogleFonts.ebGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: OlfatoTokens.ink,
              ),
            ),
          ],
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: OlfatoTokens.gray.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Erro ao carregar a wishlist',
              style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.gray),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWishlist,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadWishlist,
      color: OlfatoTokens.plum,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildPerfumeCard(_items[index]),
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
              Icons.favorite_border,
              size: 64,
              color: OlfatoTokens.plum.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum perfume na wishlist',
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore perfumes e adicione os que deseja à sua lista!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: OlfatoTokens.gray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Explorar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: OlfatoTokens.plum,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildPerfumeCard(Map<String, dynamic> item) {
    final perfume = item['perfume'] as Map<String, dynamic>? ?? item;
    final name = perfume['name'] as String? ?? '';
    final brand = perfume['brand'] as String? ?? '';
    final imageUrl = _proxyUrl(perfume['image_url'] as String?);
    final perfumeId = perfume['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (perfumeId.isNotEmpty) {
          context.push('/perfume/$perfumeId');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(OlfatoTokens.radiusCard),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_florist,
                            color: OlfatoTokens.plum,
                            size: 36,
                          ),
                        )
                      : const Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 36),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OlfatoTokens.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      brand,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: OlfatoTokens.gray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Remove button
                    GestureDetector(
                      onTap: () async {
                        final success = await ref.read(wishlistIdsProvider.notifier).remove(perfumeId);
                        if (success && mounted) {
                          setState(() {
                            _items.removeWhere((i) {
                              final p = i['perfume'] as Map<String, dynamic>? ?? i;
                              return p['id']?.toString() == perfumeId;
                            });
                          });
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 12, color: OlfatoTokens.error),
                          const SizedBox(width: 4),
                          Text(
                            'Remover',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: OlfatoTokens.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
