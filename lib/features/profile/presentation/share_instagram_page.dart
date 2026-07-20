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
  bool _generating = true;
  bool _sharing = false;
  String? _imageUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateImage();
  }

  Future<void> _generateImage() async {
    try {
      final response = await ApiClient().dio.get('/collection/share-image');
      final url = response.data['image_url'] as String?;
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _generating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = 'Não foi possível gerar a imagem. Tente novamente.';
        });
      }
    }
  }

  Future<void> _share() async {
    if (_imageUrl == null) return;
    setState(() => _sharing = true);

    try {
      if (kIsWeb) {
        // Web: open image in new tab or download
        // ignore: avoid_web_libraries_in_flutter
        await Share.share('Minha coleção no PerfumIA 🧴✨\nperfumia.com.br');
      } else {
        // Mobile: download image and share
        final response = await Dio().get<List<int>>(
          _imageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/perfumia_collection.png');
        await file.writeAsBytes(response.data!);

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
          style: GoogleFonts.ebGaramond(fontSize: 20, fontWeight: FontWeight.w700, color: OlfatoTokens.ink),
        ),
        centerTitle: true,
      ),
      body: _generating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: OlfatoTokens.plum),
                  const SizedBox(height: 24),
                  Text('Gerando imagem com IA...', style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.gray)),
                  const SizedBox(height: 8),
                  Text('Isso pode levar alguns segundos', style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: OlfatoTokens.gray.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(_error!, style: GoogleFonts.inter(fontSize: 14, color: OlfatoTokens.gray), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () { setState(() { _generating = true; _error = null; }); _generateImage(); },
                          style: ElevatedButton.styleFrom(backgroundColor: OlfatoTokens.plum, foregroundColor: Colors.white),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Preview
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: OlfatoTokens.plum));
                            },
                            errorBuilder: (_, __, ___) => Center(
                              child: Text('Erro ao carregar preview', style: GoogleFonts.inter(color: OlfatoTokens.gray)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
                          const SizedBox(height: 12),
                          Text(
                            'Imagem gerada com IA • Válida até o fim do mês',
                            style: GoogleFonts.inter(fontSize: 11, color: OlfatoTokens.gray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
