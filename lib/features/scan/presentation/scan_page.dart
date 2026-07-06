import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:typed_data';
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
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isInitializing = true;
  bool _isIdentifying = false;
  Map<String, dynamic>? _foundPerfume;
  String? _error;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  void _disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isCameraInitialized) _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _isCameraError = false;
      _cameraErrorMessage = null;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraError = true;
            _isInitializing = false;
            _cameraErrorMessage = 'Nenhuma câmera encontrada neste dispositivo.';
          });
        }
        return;
      }

      // Prefer back/environment camera
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;

      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Erro ao acessar a câmera.';
        if (e.toString().contains('Permission') || e.toString().contains('NotAllowed')) {
          msg = 'Permissão de câmera negada. Habilite nas configurações do navegador.';
        } else if (e.toString().contains('NotFound') || e.toString().contains('Overconstrained')) {
          msg = 'Câmera não encontrada ou não suportada.';
        }
        setState(() {
          _isCameraError = true;
          _isInitializing = false;
          _cameraErrorMessage = msg;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _error = 'Câmera não pronta. Aguarde ou recarregue a página.');
      return;
    }

    setState(() { _error = null; _foundPerfume = null; });

    try {
      final XFile image = await _cameraController!.takePicture();
      await _identifyImage(image);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erro ao capturar. Tente novamente.');
      }
    }
  }

  Future<void> _identifyImage(XFile image) async {
    setState(() { _isIdentifying = true; _error = null; _foundPerfume = null; });

    try {
      final Uint8List bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await ApiClient().dio.post('/perfumes/identify', data: {'image': base64Image});
      final data = response.data as Map<String, dynamic>;

      if (data['identified'] == true && data['perfume'] != null) {
        if (mounted) setState(() { _foundPerfume = data['perfume'] as Map<String, dynamic>; _isIdentifying = false; });
      } else {
        if (mounted) setState(() { _error = data['message'] as String? ?? 'Perfume não identificado. Tente outra foto com boa iluminação.'; _isIdentifying = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro ao identificar. Verifique sua conexão.'; _isIdentifying = false; });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text(
                    'Identificar Perfume',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance
                ],
              ),
            ),

            // Camera preview (takes all available space)
            Expanded(
              child: _buildCameraView(),
            ),

            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
            SizedBox(height: 16),
            Text('Iniciando câmera...', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }

    if (_isCameraError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                _cameraErrorMessage ?? 'Câmera indisponível',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar novamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Full camera preview
        SizedBox.expand(
          child: CameraPreview(_cameraController!),
        ),

        // Guide frame overlay
        CustomPaint(
          size: const Size(200, 260),
          painter: _GuideFramePainter(color: Colors.white),
        ),

        // Bottom hint
        Positioned(
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Centralize o frasco na moldura',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Result / Error / Loading
          if (_isIdentifying)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text('Identificando...', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
          if (_error != null && !_isIdentifying)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.pitanga), textAlign: TextAlign.center),
            ),
          if (_foundPerfume != null && !_isIdentifying)
            _buildCompactResult(),

          // Capture button
          if (!_isIdentifying && _foundPerfume == null)
            GestureDetector(
              onTap: (_isCameraInitialized && !_isIdentifying) ? _capturePhoto : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactResult() {
    final name = _foundPerfume!['name'] as String? ?? '';
    final brand = _foundPerfume!['brand'] as String? ?? '';
    final perfumeId = _foundPerfume!['id']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OlfatoTokens.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: OlfatoTokens.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$name — $brand', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () { if (perfumeId.isNotEmpty) context.push('/perfume/$perfumeId'); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OlfatoTokens.plum, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Ver ficha', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _addToCollection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Adicionar', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() { _foundPerfume = null; _error = null; }),
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                tooltip: 'Nova foto',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Guide frame corner painter
class _GuideFramePainter extends CustomPainter {
  final Color color;
  _GuideFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cl = 35.0;
    const r = 14.0;

    // Top-left
    canvas.drawPath(Path()..moveTo(0, cl)..lineTo(0, r)..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))..lineTo(cl, 0), paint);
    // Top-right
    canvas.drawPath(Path()..moveTo(size.width - cl, 0)..lineTo(size.width - r, 0)..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))..lineTo(size.width, cl), paint);
    // Bottom-left
    canvas.drawPath(Path()..moveTo(0, size.height - cl)..lineTo(0, size.height - r)..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))..lineTo(cl, size.height), paint);
    // Bottom-right
    canvas.drawPath(Path()..moveTo(size.width - cl, size.height)..lineTo(size.width - r, size.height)..arcToPoint(Offset(size.width, size.height - r), radius: const Radius.circular(r))..lineTo(size.width, size.height - cl), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
