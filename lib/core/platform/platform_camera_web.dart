import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

/// Web camera using dart:html VideoElement + getUserMedia.
class PlatformCamera {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  String? _viewId;
  bool _viewRegistered = false;
  bool _initialized = false;
  String? errorMessage;

  bool get isReady => _initialized;
  bool get hasError => errorMessage != null;

  Future<void> initialize() async {
    _viewId = 'scan-camera-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final constraints = {
        'video': {'facingMode': 'environment', 'width': {'ideal': 1280}, 'height': {'ideal': 720}},
        'audio': false,
      };

      html.MediaStream stream;
      try {
        stream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      } catch (_) {
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
        ui_web.platformViewRegistry.registerViewFactory(_viewId!, (int id) => _videoElement!);
        _viewRegistered = true;
      }

      await video.play();
      _initialized = true;
    } catch (e) {
      String msg = 'Erro ao acessar câmera.';
      final err = e.toString();
      if (err.contains('NotAllowedError') || err.contains('Permission') || err.contains('Denied')) {
        msg = 'Permissão negada. Habilite a câmera nas configurações do navegador.';
      } else if (err.contains('NotFoundError')) {
        msg = 'Nenhuma câmera encontrada.';
      } else if (err.contains('NotReadableError') || err.contains('AbortError')) {
        msg = 'Câmera em uso por outro aplicativo.';
      }
      errorMessage = msg;
    }
  }

  Widget buildPreview() {
    if (!_initialized || _viewId == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2));
    }
    return HtmlElementView(viewType: _viewId!);
  }

  Future<String?> captureBase64() async {
    if (_videoElement == null || !_initialized) return null;
    final vw = _videoElement!.videoWidth;
    final vh = _videoElement!.videoHeight;
    final canvas = html.CanvasElement(width: vw, height: vh);
    canvas.context2D.drawImage(_videoElement!, 0, 0);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    return dataUrl.split(',').last;
  }

  Future<String?> captureDataUrl() async {
    if (_videoElement == null || !_initialized) return null;
    final vw = _videoElement!.videoWidth;
    final vh = _videoElement!.videoHeight;
    final canvas = html.CanvasElement(width: vw, height: vh);
    canvas.context2D.drawImage(_videoElement!, 0, 0);
    return canvas.toDataUrl('image/jpeg', 0.85);
  }

  void dispose() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
    _videoElement?.pause();
    _videoElement?.srcObject = null;
    _videoElement = null;
    _initialized = false;
  }
}
