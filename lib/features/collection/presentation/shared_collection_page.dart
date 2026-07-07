import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';

class SharedCollectionPage extends StatefulWidget {
  final String token;
  const SharedCollectionPage({super.key, required this.token});

  @override
  State<SharedCollectionPage> createState() => _SharedCollectionPageState();
}

class _SharedCollectionPageState extends State<SharedCollectionPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient().dio.get('/collection/shared/${widget.token}');
      if (mounted) setState(() { _data = response.data as Map<String, dynamic>; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('fimgs.net')) return 'https://essencia.laravel.cloud/api/image-proxy?url=${Uri.encodeComponent(url)}';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OlfatoTokens.ink), onPressed: () => context.go('/')),
        title: Text('Coleção Compartilhada', style: GoogleFonts.ebGaramond(fontSize: 20, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: OlfatoTokens.plum));
    if (_hasError) return Center(child: Text('Coleção não encontrada', style: GoogleFonts.inter(color: OlfatoTokens.gray)));

    final owner = _data!['owner'] as String? ?? '';
    final count = _data!['count'] as int? ?? 0;
    final perfumes = (_data!['perfumes'] as List?) ?? [];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OlfatoTokens.plum.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
              border: Border.all(color: OlfatoTokens.plum.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: OlfatoTokens.plum.withValues(alpha: 0.2),
                  child: Text(owner.isNotEmpty ? owner[0].toUpperCase() : '?', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: OlfatoTokens.plum)),
                ),
                const SizedBox(height: 10),
                Text('Coleção de $owner', style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
                const SizedBox(height: 4),
                Text('$count perfumes', style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.gray)),
              ],
            ),
          ),
        ),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            itemCount: perfumes.length,
            itemBuilder: (_, i) {
              final p = perfumes[i] as Map<String, dynamic>;
              final imageUrl = _proxyUrl(p['image_url'] as String?);
              return GestureDetector(
                onTap: () {
                  final id = p['id']?.toString();
                  if (id != null && id.isNotEmpty) context.push('/perfume/$id');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: OlfatoTokens.mist,
                    borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
                    border: Border.all(color: OlfatoTokens.borderLight),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(OlfatoTokens.radiusCard)),
                          child: Container(
                            width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 32))
                                : const Icon(Icons.local_florist, color: OlfatoTokens.plum, size: 32),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name'] ?? '', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: OlfatoTokens.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(p['brand'] ?? '', style: GoogleFonts.inter(fontSize: 10, color: OlfatoTokens.gray), maxLines: 1),
                              const Spacer(),
                              if (p['family'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: OlfatoTokens.plum.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                                  child: Text(p['family'], style: GoogleFonts.inter(fontSize: 9, color: OlfatoTokens.plum)),
                                ),
                            ],
                          ),
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
