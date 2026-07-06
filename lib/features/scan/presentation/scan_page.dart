import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
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
  bool _showCapturedFrame = false;
  String? _error;
  String? _cameraErrorMessage;
  Map<String, dynamic>? _foundPerfume;
  String? _capturedImageData; // data URL for showing captured frame

  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  late final String _viewId;
  bool _viewRegistered = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'scan-camera-${DateTime.now().millisecondsSinceEpoch}';
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

    try {
      final constraints = {
        'video': {'facingMode': 'environment', 'width': {'ideal': 1280}, 'height': {'ideal': 720}},
        'audio': false,
      };

      html.MediaStream stream;
      try {
        stream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      } catch (_) {
        // Fallback without facingMode
        stream = await html.window.navigator.mediaDevices!.getUserMedia({'video': true, 'audio': false});
      }

      _mediaStream = stream;

      final video = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      _videoElement = video;

      if (!_viewRegistered) {
        ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) => _videoElement!);
        _viewRegistered = true;
      }

      await video.play();

      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      if (mounted) {
        String msg = 'Erro ao acessar câmera.';
        final err = e.toString();
        if (err.contains('NotAllowedError') || err.contains('Permission') || err.contains('Denied')) {
          msg = 'Permissão negada. Habilite a câmera nas configurações do navegador.';
        } else if (err.contains('NotFoundError')) {
          msg = 'Nenhuma câmera encontrada.';
        } else if (err.contains('NotReadableError') || err.contains('AbortError')) {
          msg = 'Câmera em uso por outro aplicativo.';
        }
        setState(() { _isCameraError = true; _cameraErrorMessage = msg; });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_videoElement == null || !_isCameraReady) return;
    if (_isIdentifying) return;

    // Reset state for new capture
    setState(() {
      _error = null;
      _foundPerfume = null;
      _showCapturedFrame = false;
    });

    try {
      final vw = _videoElement!.videoWidth;
      final vh = _videoElement!.videoHeight;
      final canvas = html.CanvasElement(width: vw, height: vh);
      canvas.context2D.drawImage(_videoElement!, 0, 0);

      // Get data URL for preview
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);

      setState(() {
        _showCapturedFrame = true;
        _capturedImageData = dataUrl;
        _isIdentifying = true;
      });

      // Get base64 for API
      final base64Image = dataUrl.split(',').last;

      // Send to API — handle non-2xx as data, not exception
      final response = await ApiClient().dio.post(
        '/perfumes/identify',
        data: {'image': base64Image},
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      final data = response.data as Map<String, dynamic>;

      if (data['identified'] == true && data['perfume'] != null) {
        if (mounted) setState(() { _foundPerfume = data['perfume'] as Map<String, dynamic>; _isIdentifying = false; });
      } else {
        if (mounted) setState(() {
          _error = data['message'] as String? ?? 'Perfume não identificado. Tente outra foto com melhor iluminação.';
          _isIdentifying = false;
          _showCapturedFrame = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Erro ao processar. Verifique sua conexão.';
        _isIdentifying = false;
        _showCapturedFrame = false;
      });
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao adicionar'), backgroundColor: OlfatoTokens.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OlfatoTokens.vanilla,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OlfatoTokens.ink), onPressed: () => context.pop()),
        title: Text('Identificar Perfume', style: GoogleFonts.ebGaramond(fontSize: 20, fontWeight: FontWeight.w700, color: OlfatoTokens.ink)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Camera area (fixed height)
          _buildCameraSection(),
          // Bottom scrollable area: capture button + result
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Capture button — always visible
                  _buildCaptureButton(),
                  const SizedBox(height: 16),
                  // Error
                  if (_error != null) _buildError(),
                  // Result card
                  if (_foundPerfume != null) _buildResultCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Always keep the live camera in the tree
          if (_isCameraReady)
            SizedBox.expand(child: HtmlElementView(viewType: _viewId))
          else if (_isCameraError)
            _buildCameraError()
          else
            const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),

          // Captured frame overlay — sits on top of live camera
          if (_showCapturedFrame && _capturedImageData != null)
            Positioned.fill(
              child: Image.memory(
                base64Decode(_capturedImageData!.split(',').last),
                fit: BoxFit.cover,
              ),
            ),

          // Guide frame overlay (only when live)
          if (!_showCapturedFrame)
            CustomPaint(size: const Size(180, 230), painter: _GuideFramePainter()),

          // Identifying overlay
          if (_isIdentifying)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    const SizedBox(height: 12),
                    Text('Identificando...', style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

          // Bottom hint
          if (!_showCapturedFrame && _isCameraReady && !_isIdentifying)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: Text('Centralize o frasco', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 36, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(_cameraErrorMessage ?? 'Câmera indisponível', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextButton(onPressed: _initWebCamera, child: Text('Tentar novamente', style: GoogleFonts.inter(color: Colors.white, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    final isReady = _isCameraReady && !_isIdentifying;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isReady ? _capturePhoto : null,
        icon: Icon(_isIdentifying ? Icons.hourglass_top : Icons.camera_alt, size: 20),
        label: Text(
          _isIdentifying ? 'Processando...' : (_foundPerfume != null ? 'Escanear outro' : 'Capturar Foto'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: OlfatoTokens.plum,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OlfatoTokens.plum.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl)),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OlfatoTokens.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
        border: Border.all(color: OlfatoTokens.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: OlfatoTokens.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: OlfatoTokens.error))),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final name = _foundPerfume!['name'] as String? ?? '';
    final brand = _foundPerfume!['brand'] as String? ?? '';
    final perfumeId = _foundPerfume!['id']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OlfatoTokens.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OlfatoTokens.radiusCard),
        border: Border.all(color: OlfatoTokens.green.withValues(alpha: 0.25)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: OlfatoTokens.plum, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl))),
                  child: Text('Ver ficha', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _addToCollection,
                  style: OutlinedButton.styleFrom(foregroundColor: OlfatoTokens.plum, side: const BorderSide(color: OlfatoTokens.plum), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl))),
                  child: Text('Adicionar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const cl = 30.0; const r = 12.0;
    canvas.drawPath(Path()..moveTo(0, cl)..lineTo(0, r)..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))..lineTo(cl, 0), paint);
    canvas.drawPath(Path()..moveTo(size.width - cl, 0)..lineTo(size.width - r, 0)..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))..lineTo(size.width, cl), paint);
    canvas.drawPath(Path()..moveTo(0, size.height - cl)..lineTo(0, size.height - r)..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))..lineTo(cl, size.height), paint);
    canvas.drawPath(Path()..moveTo(size.width - cl, size.height)..lineTo(size.width - r, size.height)..arcToPoint(Offset(size.width, size.height - r), radius: const Radius.circular(r))..lineTo(size.width, size.height - cl), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
