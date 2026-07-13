import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import 'share_collection_card.dart';

class ShareInstagramPage extends StatefulWidget {
  const ShareInstagramPage({super.key});

  @override
  State<ShareInstagramPage> createState() => _ShareInstagramPageState();
}

class _ShareInstagramPageState extends State<ShareInstagramPage> {
  final _cardKey = GlobalKey();
  bool _loading = true;
  bool _sharing = false;

  String _userName = '';
  int _totalPerfumes = 0;
  int _totalDecants = 0;
  int _totalAmostras = 0;
  List<Map<String, String>> _topPerfumes = [];
  List<String> _topFamilies = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('/user/profile'),
        ApiClient().dio.get('/collection/stats'),
        ApiClient().dio.get('/collection?sort=rating&dir=desc'),
      ]);

      final user = responses[0].data as Map<String, dynamic>;
      final stats = responses[1].data as Map<String, dynamic>;
      final collection = responses[2].data as Map<String, dynamic>;
      final items = (collection['data'] as List?) ?? [];

      // Extract top perfumes
      final topP = items.take(5).map<Map<String, String>>((item) {
        final p = item['perfume'] as Map<String, dynamic>? ?? {};
        return {
          'name': (p['name'] ?? '').toString(),
          'brand': (p['brand'] ?? '').toString(),
        };
      }).toList();

      // Extract families
      final families = <String>{};
      for (final item in items) {
        final p = item['perfume'] as Map<String, dynamic>? ?? {};
        final family = p['olfactory_family']?['name'] as String?;
        if (family != null && family.isNotEmpty) families.add(family);
      }

      if (mounted) {
        setState(() {
          _userName = user['name'] ?? '';
          _totalPerfumes = stats['total'] ?? 0;
          _totalDecants = stats['decants'] ?? 0;
          _totalAmostras = stats['samples'] ?? 0;
          _topPerfumes = topP;
          _topFamilies = families.take(4).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareToInstagram() async {
    setState(() => _sharing = true);

    // Wait for the card to render
    await Future.delayed(const Duration(milliseconds: 300));

    final bytes = await captureCardAsImage(_cardKey);
    if (bytes == null) {
      if (mounted) {
        setState(() => _sharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao gerar imagem'), backgroundColor: OlfatoTokens.error),
        );
      }
      return;
    }

    try {
      if (kIsWeb) {
        // Web: use share sheet with file data
        await Share.shareXFiles([
          XFile.fromData(bytes, mimeType: 'image/png', name: 'minha_colecao_perfumia.png'),
        ], text: 'Minha coleção no PerfumIA 🧴✨');
      } else {
        // Mobile: save temp file and share
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/perfumia_collection.png');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Minha coleção no PerfumIA 🧴✨\nperfumia.com.br',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao compartilhar'), backgroundColor: OlfatoTokens.error),
        );
      }
    }

    if (mounted) setState(() => _sharing = false);
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
          'Compartilhar Coleção',
          style: GoogleFonts.ebGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: OlfatoTokens.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OlfatoTokens.plum))
          : Column(
              children: [
                // Preview (scaled down)
                Expanded(
                  child: Center(
                    child: FittedBox(
                      child: CollectionShareCard(
                        userName: _userName,
                        totalPerfumes: _totalPerfumes,
                        totalDecants: _totalDecants,
                        totalAmostras: _totalAmostras,
                        topPerfumes: _topPerfumes,
                        topFamilies: _topFamilies,
                        repaintKey: _cardKey,
                      ),
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sharing ? null : _shareToInstagram,
                          icon: _sharing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.share, size: 18),
                          label: Text(
                            'Compartilhar nos Stories',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE1306C), // Instagram pink
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A imagem será enviada para o Instagram Stories',
                        style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
