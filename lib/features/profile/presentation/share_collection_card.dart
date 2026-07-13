import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';

/// Generates a shareable image card for the user's collection.
/// Returns the PNG bytes of the rendered card.
class CollectionShareCard extends StatelessWidget {
  final String userName;
  final int totalPerfumes;
  final int totalDecants;
  final int totalAmostras;
  final List<Map<String, String>> topPerfumes; // [{name, brand}]
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0A2E), // deep purple
              Color(0xFF2D1B4E), // plum dark
              Color(0xFF0F0520), // almost black
            ],
          ),
        ),
        padding: const EdgeInsets.all(80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            // Header
            Text(
              'Minha Coleção',
              style: GoogleFonts.ebGaramond(
                fontSize: 72,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userName,
              style: GoogleFonts.inter(
                fontSize: 36,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 60),

            // Stats
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem('$totalPerfumes', 'Perfumes'),
                  _divider(),
                  _statItem('$totalDecants', 'Decantes'),
                  _divider(),
                  _statItem('$totalAmostras', 'Amostras'),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Top perfumes
            if (topPerfumes.isNotEmpty) ...[
              Text(
                'Destaques',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              ...topPerfumes.take(5).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
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
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            p['brand'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              color: OlfatoTokens.amber,
                            ),
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
            if (topFamilies.isNotEmpty) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: topFamilies.take(4).map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.inter(fontSize: 22, color: Colors.white70),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 40),
            ],

            // Branding
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: OlfatoTokens.plum,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('P', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'PerfumIA',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  'perfumia.com.br',
                  style: GoogleFonts.inter(fontSize: 22, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.ebGaramond(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: OlfatoTokens.amber,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 22, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 60, color: Colors.white.withValues(alpha: 0.2));
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
