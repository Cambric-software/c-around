import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The device camera, reduced to the two operations the app needs: show a
/// preview, and hand over one JPEG.
///
/// Frames are taken as stills on a timer rather than through an image stream.
/// A still is slower than a stream, but it works unchanged on Android and
/// Windows, keeps one code path, and avoids the YUV conversion that made the
/// first prototype drop frames on mid-range phones.
class CameraFrameSource {
  CameraController? _controller;
  String? _error;
  bool _starting = false;
  int _captureCounter = 0;

  /// The live controller, for [CameraPreview].
  CameraController? get controller => _controller;

  /// True when a preview is available.
  bool get isReady => _controller?.value.isInitialized ?? false;

  /// Why the camera is unavailable, if it is.
  String? get error => _error;

  /// Start the first camera that opens.
  Future<bool> start({CameraLensDirection preferred = CameraLensDirection.back}) async {
    if (isReady) return true;
    if (_starting) return false;
    _starting = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _error = 'No camera was found on this device.';
        return false;
      }
      final description = cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == preferred,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      _controller = controller;
      _error = null;
      return true;
    } catch (error) {
      _error = _describe(error);
      _controller = null;
      return false;
    } finally {
      _starting = false;
    }
  }

  /// Capture one JPEG frame.
  Future<Uint8List?> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      // camera_windows writes into the temporary directory and does not always
      // clean up after itself; delete the frame once it is in memory.
      if (file.path.startsWith(Directory.systemTemp.path)) {
        try {
          await File(file.path).delete();
        } catch (_) {
          // A leftover temporary file is not worth failing a capture over.
        }
      }
      return bytes;
    } catch (error) {
      _error = _describe(error);
      return null;
    }
  }

  /// Build a preview widget, or a placeholder explaining why there is none.
  Widget preview({BoxFit fit = BoxFit.cover}) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Color(0xFF0B1418));
    }
    return CameraPreview(controller, child: const SizedBox.expand());
  }

  /// Stop and release the camera.
  Future<void> stop() async {
    final controller = _controller;
    _controller = null;
    try {
      await controller?.dispose();
    } catch (_) {
      // Releasing is best effort.
    }
  }

  /// A fresh temporary path for an imported photo.
  Future<String> newPhotoPath(String prefix) async {
    final directory = await getApplicationDocumentsDirectory();
    final photos = Directory(p.join(directory.path, 'photos'));
    await photos.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return p.join(photos.path, '${prefix}_${stamp}_${_captureCounter++}.jpg');
  }

  String _describe(Object error) {
    final text = error.toString();
    if (text.contains('MissingPluginException')) {
      return Platform.isLinux
          ? 'Live camera is not supported on Linux by this build. '
              'Import a photo instead.'
          : 'The camera plugin is not available on this platform.';
    }
    if (text.toLowerCase().contains('permission')) {
      return 'Camera permission was denied. Allow it in system settings, '
          'then try again.';
    }
    return 'Camera unavailable: $text';
  }
}
