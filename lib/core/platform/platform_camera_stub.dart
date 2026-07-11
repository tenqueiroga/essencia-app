import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Mobile camera using the camera package.
class PlatformCamera {
  CameraController? _controller;
  bool _initialized = false;
  String? errorMessage;

  bool get isReady => _initialized;
  bool get hasError => errorMessage != null;

  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = 'Nenhuma câmera encontrada.';
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      _initialized = true;
    } catch (e) {
      errorMessage = 'Erro ao acessar câmera.';
    }
  }

  Widget buildPreview() {
    if (_controller == null || !_initialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2));
    }
    return CameraPreview(_controller!);
  }

  Future<String?> captureBase64() async {
    if (_controller == null || !_initialized) return null;
    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<String?> captureDataUrl() async {
    final b64 = await captureBase64();
    if (b64 == null) return null;
    return 'data:image/jpeg;base64,$b64';
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _initialized = false;
  }
}
