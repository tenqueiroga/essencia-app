import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';

class ShareInstagramPage extends StatefulWidget {
  const ShareInstagramPage({super.key});

  @override
  State<ShareInstagramPage> createState() => _ShareInstagramPageState();
}

class _ShareInstagramPageState extends State<ShareInstagramPage> {
  // Step 1: choose style, Step 2: generating, Step 3: preview
  int _step = 1;
  String? _selectedStyle;
  String? _imageUrl;
  String? _error;
  bool _sharing = false;

  final _styles = <String, Map<String, String>>{
    'photo_card': {'name': 'Elegante', 'desc': 'Foto de perfumes com card escuro', 'icon': '✨'},
    'neon_cyber': {'name': 'Neon', 'desc': 'Visual futurista com acentos neon', 'icon': '💜'},
    'polaroid_stack': {'name': 'Polaroid', 'desc': 'Estilo scrapbook nostálgico', 'icon': '📷'},
    'shelf_photo': {'name': 'Prateleira', 'desc': 'Foto de coleção com dados', 'icon': '🧴'},
    'circular_stats': {'name': 'Data Art', 'desc': 'Gráfico circular com stats', 'icon': '📊'},
  };

  Future<void> _generate() async {
    if (_selectedStyle == null) return;
    setState(() { _step = 2; _error = null; });

    try {
      final response = await ApiClient().dio.get(
        '/collection/share-image',
        queryParameters: {'style': _selectedStyle, 'force': '1'},
        options: Options(receiveTimeout: const Duration(seconds: 150)),
      );
      final url = response.data['image_url'] as String?;
      if (mounted) setState(() { _imageUrl = url; _step = 3; });
    } catch (e) {
      if (mounted) setState(() { _step = 1; _error = 'Erro ao gerar. Tente novamente.'; });
    }
  }

  Future<void> _share() async {
    if (_imageUrl == null) return;
    setState(() => _sharing = true);

    try {
      if (kIsWeb) {
        await Share.share('Minha coleção no PerfumIA 🧴✨\nperfumia.com.br');
      } else {
        final response = await Dio().get<List<int>>(_imageUrl!, options: Options(responseType: ResponseType.bytes));
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/perfumia_collection.png');
        await file.writeAsBytes(response.data!);
        await Share.shareXFiles([XFile(file.path)], text: 'Minha coleção no PerfumIA 🧴✨\nperfumia.com.br');
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao compartilhar'), backgroundColor: OlfatoTokens.error));
    }

    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OlfatoTokens.ink), onPressed: () {
          if (_step == 3) { setState(() => _step = 1); } else { context.pop(); }
        }),
        title: Text(
          _step == 1 ? 'Escolha o estilo' : _step == 2 ? 'Gerando...' : 'Compartilhar',
          style: GoogleFonts.ebGaramond(fontSize: 20, fontWeight: FontWeight.w700, color: OlfatoTokens.ink),
        ),
        centerTitle: true,
      ),
      body: switch (_step) {
        1 => _buildStylePicker(),
        2 => _buildGenerating(),
        3 => _buildPreview(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildStylePicker() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como quer que sua coleção apareça?', style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.gray)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.error)),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _styles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final key = _styles.keys.elementAt(index);
                final style = _styles[key]!;
                final selected = _selectedStyle == key;

                return GestureDetector(
                  onTap: () => setState(() => _selectedStyle = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: selected ? OlfatoTokens.plum.withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? OlfatoTokens.plum : OlfatoTokens.borderLight,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(style['icon']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(style['name']!, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: OlfatoTokens.ink)),
                              const SizedBox(height: 2),
                              Text(style['desc']!, style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray)),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.check_circle, color: OlfatoTokens.plum, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedStyle != null ? _generate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: OlfatoTokens.plum,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                disabledBackgroundColor: OlfatoTokens.gray.withValues(alpha: 0.3),
              ),
              child: Text('Gerar imagem', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: OlfatoTokens.plum),
          const SizedBox(height: 24),
          Text('Gerando sua imagem com IA...', style: GoogleFonts.inter(fontSize: 15, color: OlfatoTokens.ink)),
          const SizedBox(height: 8),
          Text('Isso leva alguns segundos', style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.gray)),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(color: OlfatoTokens.plum)),
                errorBuilder: (_, __, ___) => Center(child: Text('Erro ao carregar', style: GoogleFonts.inter(color: OlfatoTokens.gray))),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sharing ? null : _share,
                  icon: _sharing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.share, size: 18),
                  label: Text('Compartilhar', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1306C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: Text('Escolher outro estilo', style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.plum)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
