import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';

/// Generates a shareable image card for the user's collection.
class CollectionShareCard extends StatelessWidget {
  final String userName;
  final int totalPerfumes;
  final int totalDecants;
  final int totalAmostras;
  final List<Map<String, String>> topPerfumes;
  final List<String> topFamilies;
  final GlobalKey repaintKey;

  const CollectionShareCard({
    super.key,
    required this.userName,
    required this.totalPerfumes,
    required this.totalDecants,
    required this.totalAmostras,
    required this.topPerfumes,
    required this.topFamilies,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 1080,
        height: 1920,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1B4E),
              Color(0xFF1A0A2E),
              Color(0xFF0D0618),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      OlfatoTokens.plum.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      OlfatoTokens.amber.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [OlfatoTokens.plum, Color(0xFF9B59B6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('P', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PerfumIA',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'perfumia.com.br',
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),

                  // Title
                  Text(
                    'Minha\nColeção',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 88,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [OlfatoTokens.amber, OlfatoTokens.pitanga]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: GoogleFonts.inter(fontSize: 28, color: Colors.white70, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 60),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statBlock('$totalPerfumes', 'Perfumes'),
                        Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.15)),
                        _statBlock('$totalDecants', 'Decantes'),
                        Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.15)),
                        _statBlock('$totalAmostras', 'Amostras'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Top perfumes
                  if (topPerfumes.isNotEmpty) ...[
                    Text(
                      'DESTAQUES',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OlfatoTokens.amber,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...topPerfumes.take(4).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 14),
                            decoration: const BoxDecoration(
                              color: OlfatoTokens.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] ?? '',
                                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  p['brand'] ?? '',
                                  style: GoogleFonts.inter(fontSize: 20, color: OlfatoTokens.amber.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],

                  const Spacer(),

                  // Families
                  if (topFamilies.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: topFamilies.take(4).map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(f, style: GoogleFonts.inter(fontSize: 18, color: Colors.white70)),
                      )).toList(),
                    ),
                  const SizedBox(height: 40),

                  // Footer tagline
                  Center(
                    child: Text(
                      'Seu gosto, traduzido em perfume.',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.ebGaramond(fontSize: 52, fontWeight: FontWeight.w700, color: OlfatoTokens.amber),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 18, color: Colors.white60)),
      ],
    );
  }
}

/// Captures the RepaintBoundary as PNG bytes.
Future<Uint8List?> captureCardAsImage(GlobalKey key) async {
  try {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
