import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isIdentifying = false;
  Map<String, dynamic>? _foundPerfume;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras().timeout(const Duration(seconds: 5));
      if (cameras.isEmpty) {
        if (mounted) setState(() => _isCameraError = true);
        return;
      }

      // Prefer back camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize().timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCameraError = true);
      }
    }
  }

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
            // Camera preview area with guide frame
            _buildCameraArea(),
            const SizedBox(height: 16),

            // Capture + gallery buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isIdentifying ? null : _capturePhoto,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text('Capturar', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
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

            // Result area
            _buildResultArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
      child: Container(
        width: double.infinity,
        height: 320,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Camera preview or fallback
            if (_isCameraInitialized && _cameraController != null)
              SizedBox(
                width: double.infinity,
                height: 320,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 320,
                    height: _cameraController!.value.previewSize?.width ?? 320,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else if (_isCameraError)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off_outlined, size: 40, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Câmera indisponível',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use a galeria para enviar uma foto',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                  ),
                ],
              )
            else
              const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),

            // Guide frame overlay
            CustomPaint(
              size: const Size(180, 240),
              painter: _GuideFramePainter(color: Colors.white),
            ),

            // Bottom instruction
            Positioned(
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Centralize o frasco',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
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
              width: 28, height: 28,
              child: CircularProgressIndicator(color: OlfatoTokens.plum, strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text('Identificando perfume...', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: OlfatoTokens.ink)),
            const SizedBox(height: 4),
            Text('A Aura está analisando a imagem', style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.gray)),
          ],
        ),
      );
    }

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
            Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.error))),
          ],
        ),
      );
    }

    if (_foundPerfume != null) return _buildResult();

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
              Text('Perfume Identificado!', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: OlfatoTokens.green)),
            ],
          ),
          const SizedBox(height: 10),
          Text(name, style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
          Text(brand, style: GoogleFonts.inter(fontSize: 13, color: OlfatoTokens.gray)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () { if (perfumeId.isNotEmpty) context.push('/perfume/$perfumeId'); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OlfatoTokens.plum, foregroundColor: Colors.white,
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
                    foregroundColor: OlfatoTokens.plum, side: const BorderSide(color: OlfatoTokens.plum),
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

  Future<void> _capturePhoto() async {
    setState(() { _error = null; _foundPerfume = null; });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      // Capture from inline camera
      try {
        final image = await _cameraController!.takePicture();
        await _identifyImage(image);
      } catch (e) {
        if (mounted) setState(() => _error = 'Erro ao capturar foto.');
      }
    } else {
      // Fallback: use image_picker camera
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
        if (mounted) setState(() => _error = 'Câmera não disponível. Use a galeria.');
      }
    }
  }

  Future<void> _uploadFromGallery() async {
    setState(() { _error = null; _foundPerfume = null; });

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
      if (mounted) setState(() => _error = 'Erro ao selecionar imagem.');
    }
  }

  Future<void> _identifyImage(XFile image) async {
    setState(() { _isIdentifying = true; _error = null; _foundPerfume = null; });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await ApiClient().dio.post('/perfumes/identify', data: {'image': base64Image});
      final data = response.data as Map<String, dynamic>;

      if (data['identified'] == true && data['perfume'] != null) {
        if (mounted) setState(() { _foundPerfume = data['perfume'] as Map<String, dynamic>; _isIdentifying = false; });
      } else {
        if (mounted) setState(() { _error = data['message'] as String? ?? 'Perfume não identificado. Tente com outra foto.'; _isIdentifying = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro ao identificar. Tente novamente.'; _isIdentifying = false; });
    }
  }

  Future<void> _addToCollection() async {
    if (_foundPerfume == null) return;
    final selectedType = await showTypeSelectionDialog(context);
    if (selectedType == null) return;

    try {
      await ApiClient().dio.post('/collection', data: { 'perfume_id': _foundPerfume!['id'], 'type': selectedType.apiValue });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_foundPerfume!['name']} adicionado à coleção!'), backgroundColor: OlfatoTokens.plum));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfume já está na coleção'), backgroundColor: OlfatoTokens.error));
      }
    }
  }
}

/// Guide frame corner painter
class _GuideFramePainter extends CustomPainter {
  final Color color;
  _GuideFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cl = 30.0;
    const r = 12.0;

    canvas.drawPath(Path()..moveTo(0, cl)..lineTo(0, r)..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))..lineTo(cl, 0), paint);
    canvas.drawPath(Path()..moveTo(size.width - cl, 0)..lineTo(size.width - r, 0)..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))..lineTo(size.width, cl), paint);
    canvas.drawPath(Path()..moveTo(0, size.height - cl)..lineTo(0, size.height - r)..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))..lineTo(cl, size.height), paint);
    canvas.drawPath(Path()..moveTo(size.width - cl, size.height)..lineTo(size.width - r, size.height)..arcToPoint(Offset(size.width, size.height - r), radius: const Radius.circular(r))..lineTo(size.width, size.height - cl), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
