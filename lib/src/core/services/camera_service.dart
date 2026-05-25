import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to manage camera operations for document scanning.
class CameraService {
  CameraService._();

  static final CameraService _instance = CameraService._();

  factory CameraService() {
    return _instance;
  }

  final _picker = ImagePicker();
  bool _useFlash = false;

  bool get useFlash => _useFlash;

  /// Request camera permission.
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Capture a photo and return the file path.
  Future<String?> capturePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      return image?.path;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Toggle flash setting.
  void toggleFlash() {
    _useFlash = !_useFlash;
  }

  /// Set flash mode.
  void setFlash(bool enabled) {
    _useFlash = enabled;
  }

  /// Capture multiple photos.
  Future<List<String>> captureMultiplePhotos(int count) async {
    final photos = <String>[];
    for (var i = 0; i < count; i++) {
      final photo = await capturePhoto();
      if (photo != null) {
        photos.add(photo);
      }
    }
    return photos;
  }
}
