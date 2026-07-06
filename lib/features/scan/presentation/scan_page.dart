import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
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
  bool _isCameraReady = false;
  bool _isCameraError = false;
  bool _isIdentifying = false;
  String? _error;
  String? _cameraErrorMessage;
  Map<String, dynamic>? _foundPerfume;

  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  final String _viewId = 'scan-camera-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _initWebCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  void _stopCamera() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
    _videoElement?.pause();
    _videoElement?.srcObject = null;
    _videoElement = null;
  }

  Future<void> _initWebCamera() async {
    setState(() {
      _isCameraReady = false;
      _isCameraError = false;
      _cameraErrorMessage = null;
    });

    _stopCamera();

    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'environment', 'width': {'ideal': 1280}, 'height': {'ideal': 720}},
        'audio': false,
      });

      _mediaStream = stream;

      final video = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      _videoElement = video;

      // Register the view
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => video);

      // Wait for video to be ready
      await video.play();

      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Erro ao acessar câmera.';
        final err = e.toString();
        if (err.contains('NotAllowedError') || err.contains('Permission')) {
          msg = 'Permissão negada. Clique no ícone de cadeado na barra de endereços e permita o acesso à câmera.';
        } else if (err.contains('NotFoundError')) {
          msg = 'Nenhuma câmera encontrada neste dispositivo.';
        } else if (err.contains('NotReadableError') || err.contains('AbortError')) {
          msg = 'Câmera em uso por outro app. Feche-o e tente novamente.';
        } else if (err.contains('OverconstrainedError')) {
          // Try again without facingMode constraint
          try {
            final stream2 = await html.window.navigator.mediaDevices!.getUserMedia({
              'video': true,
              'audio': false,
            });
            _mediaStream = stream2;
            final video2 = html.VideoElement()
              ..srcObject = stream2
              ..autoplay = true
              ..setAttribute('playsinline', 'true')
              ..style.width = '100%'
              ..style.height = '100%'
              ..style.objectFit = 'cover';
            _videoElement = video2;
            ui_web.platformViewRegistry.registerViewFactory('$_viewId-fallback', (int viewId) => video2);
            await video2.play();
            if (mounted) setState(() => _isCameraReady = true);
            return;
          } catch (_) {
            msg = 'Câmera não suportada neste navegador.';
          }
        }
        setState(() {
          _isCameraError = true;
          _cameraErrorMessage = msg;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_videoElement == null || !_isCameraReady) return;

    setState(() { _error = null; _foundPerfume = null; });

    try {
      // Draw video frame to canvas
      final canvas = html.CanvasElement(width: _videoElement!.videoWidth, height: _videoElement!.videoHeight);
      final ctx = canvas.context2D;
      ctx.drawImage(_videoElement!, 0, 0);

      // Convert to blob then to base64
      final blob = await canvas.toBlob('image/jpeg', 0.85);
      final reader = html.FileReader();
      final completer = Completer<String>();
      reader.onLoadEnd.listen((_) {
        final result = reader.result as String;
        // Remove data:image/jpeg;base64, prefix
        final base64 = result.split(',').last;
        completer.complete(base64);
      });
      reader.readAsDataUrl(blob);
      final base64Image = await completer.future;

      await _identifyFromBase64(base64Image);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao capturar foto.');
    }
  }

  Future<void> _identifyFromBase64(String base64Image) async {
    setState(() { _isIdentifying = true; _error = null; _foundPerfume = null; });

    try {
      final response = await ApiClient().dio.post('/perfumes/identify', data: {'image': base64Image});
      final data = response.data as Map<String, dynamic>;

      if (data['identified'] == true && data['perfume'] != null) {
        if (mounted) setState(() { _foundPerfume = data['perfume'] as Map<String, dynamic>; _isIdentifying = false; });
      } else {
        if (mounted) setState(() { _error = data['message'] as String? ?? 'Perfume não identificado. Tente com melhor iluminação.'; _isIdentifying = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro de conexão. Tente novamente.'; _isIdentifying = false; });
    }
  }

  Future<void> _addToCollection() async {
    if (_foundPerfume == null) return;
    final selectedType = await showTypeSelectionDialog(context);
    if (selectedType == null) return;

    try {
      await ApiClient().dio.post('/collection', data: { 'perfume_id': _foundPerfume!['id'], 'type': selectedType.apiValue });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_foundPerfume!['name']} adicionado!'), backgroundColor: OlfatoTokens.plum));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfume já está na coleção'), backgroundColor: OlfatoTokens.error));
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
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
                  const Spacer(),
                  Text('Identificar Perfume', style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Camera view
            Expanded(child: _buildCameraView()),

            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isCameraError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, size: 48, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(_cameraErrorMessage ?? 'Câmera indisponível', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initWebCamera,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(backgroundColor: OlfatoTokens.plum, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraReady) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
            SizedBox(height: 12),
            Text('Abrindo câmera...', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // HTML video element
        SizedBox.expand(
          child: HtmlElementView(viewType: _viewId),
        ),
        // Guide frame
        CustomPaint(
          size: const Size(200, 260),
          painter: _GuideFramePainter(),
        ),
        // Hint
        Positioned(
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
            child: Text('Centralize o frasco', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
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
          if (_foundPerfume != null && !_isIdentifying) _buildCompactResult(),

          if (!_isIdentifying && _foundPerfume == null)
            GestureDetector(
              onTap: _isCameraReady ? _capturePhoto : null,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                child: Container(margin: const EdgeInsets.all(4), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
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
      decoration: BoxDecoration(color: OlfatoTokens.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.check_circle, color: OlfatoTokens.green, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('$name — $brand', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () { if (perfumeId.isNotEmpty) context.push('/perfume/$perfumeId'); }, style: ElevatedButton.styleFrom(backgroundColor: OlfatoTokens.plum, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('Ver ficha', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: _addToCollection, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('Adicionar', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)))),
            const SizedBox(width: 8),
            IconButton(onPressed: () => setState(() { _foundPerfume = null; _error = null; }), icon: const Icon(Icons.refresh, color: Colors.white70, size: 20), tooltip: 'Nova foto'),
          ]),
        ],
      ),
    );
  }
}

class _GuideFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const cl = 35.0;
    const r = 14.0;
    canvas.drawPath(Path()..moveTo(0, cl)..lineTo(0, r)..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))..lineTo(cl, 0), paint);
    canvas.drawPath(Path()..moveTo(size.width - cl, 0)..lineTo(size.width - r, 0)..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))..lineTo(size.width, cl), paint);
    canvas.drawPath(Path()..moveTo(0, size.height - cl)..lineTo(0, size.height - r)..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))..lineTo(cl, size.height), paint);
    canvas.drawPath(Path()..moveTo(size.width - cl, size.height)..lineTo(size.width - r, size.height)..arcToPoint(Offset(size.width, size.height - r), radius: const Radius.circular(r))..lineTo(size.width, size.height - cl), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
