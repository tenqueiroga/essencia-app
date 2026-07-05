import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';
import '../../../core/network/api_client.dart';
import '../../collection/presentation/type_selection_dialog.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isIdentifying = false;
  Map<String, dynamic>? _foundPerfume;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Identificar Perfume',
          style: GoogleFonts.ebGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: OlfatoTokens.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Camera frame — tappable to open camera
            _buildCameraFrame(),
            const SizedBox(height: 20),

            // Buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isIdentifying ? null : _captureFromCamera,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text('Tirar Foto', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OlfatoTokens.plum,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: OlfatoTokens.plum.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isIdentifying ? null : _uploadFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text('Galeria', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OlfatoTokens.plum,
                      side: const BorderSide(color: OlfatoTokens.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Result area: loading / error / result
            _buildResultArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFrame() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isIdentifying ? null : _captureFromCamera,
      child: Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Guide frame corners
            CustomPaint(
              size: const Size(180, 220),
              painter: _GuideFramePainter(color: OlfatoTokens.plum),
            ),
            // Center icon
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: OlfatoTokens.plum.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque para abrir a câmera',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: OlfatoTokens.gray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Bottom instruction
            Positioned(
              bottom: 16,
              child: Text(
                'Centralize o frasco na foto',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: OlfatoTokens.plum,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    // Loading state
    if (_isIdentifying) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: OlfatoTokens.plum.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.plum.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: OlfatoTokens.plum,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Identificando perfume...',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: OlfatoTokens.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A Aura está analisando a imagem',
              style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OlfatoTokens.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
          border: Border.all(color: OlfatoTokens.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: OlfatoTokens.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.error),
              ),
            ),
          ],
        ),
      );
    }

    // Success state
    if (_foundPerfume != null) {
      return _buildResult();
    }

    // Empty — no action taken yet
    return const SizedBox.shrink();
  }

  Widget _buildResult() {
    final name = _foundPerfume!['name'] as String? ?? '';
    final brand = _foundPerfume!['brand'] as String? ?? '';
    final perfumeId = _foundPerfume!['id']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OlfatoTokens.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        border: Border.all(color: OlfatoTokens.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: OlfatoTokens.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Perfume Identificado!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: OlfatoTokens.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: OlfatoTokens.ink,
            ),
          ),
          Text(brand, style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.gray)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (perfumeId.isNotEmpty) context.push('/perfume/$perfumeId');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OlfatoTokens.plum,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl)),
                  ),
                  child: Text('Ver ficha', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _addToCollection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OlfatoTokens.plum,
                    side: const BorderSide(color: OlfatoTokens.plum),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl)),
                  ),
                  child: Text('Adicionar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    // Clear previous state immediately
    setState(() {
      _error = null;
      _foundPerfume = null;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image == null) return;
      await _identifyImage(image);
    } catch (e) {
      // Camera not available on web — fall back to gallery
      if (mounted) {
        setState(() {
          _error = 'Câmera não disponível neste navegador. Use a galeria.';
        });
      }
    }
  }

  Future<void> _uploadFromGallery() async {
    // Clear previous state immediately
    setState(() {
      _error = null;
      _foundPerfume = null;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      await _identifyImage(image);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erro ao selecionar imagem.');
      }
    }
  }

  Future<void> _identifyImage(XFile image) async {
    setState(() {
      _isIdentifying = true;
      _error = null;
      _foundPerfume = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await ApiClient().dio.post('/perfumes/identify', data: {'image': base64Image});
      final data = response.data as Map<String, dynamic>;

      if (data['identified'] == true && data['perfume'] != null) {
        if (mounted) {
          setState(() {
            _foundPerfume = data['perfume'] as Map<String, dynamic>;
            _isIdentifying = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = data['message'] as String? ?? 'Perfume não identificado. Tente com outra foto.';
            _isIdentifying = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao identificar. Tente novamente.';
          _isIdentifying = false;
        });
      }
    }
  }

  Future<void> _addToCollection() async {
    if (_foundPerfume == null) return;

    final selectedType = await showTypeSelectionDialog(context);
    if (selectedType == null) return;

    try {
      await ApiClient().dio.post('/collection', data: {
        'perfume_id': _foundPerfume!['id'],
        'type': selectedType.apiValue,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_foundPerfume!['name']} adicionado à coleção!'),
            backgroundColor: OlfatoTokens.plum,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfume já está na coleção'),
            backgroundColor: OlfatoTokens.error,
          ),
        );
      }
    }
  }
}

/// Paints the centering guide frame corners
class _GuideFramePainter extends CustomPainter {
  final Color color;

  _GuideFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const radius = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..arcToPoint(Offset(radius, 0), radius: const Radius.circular(radius))
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius))
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius))
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
