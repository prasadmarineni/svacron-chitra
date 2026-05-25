import 'package:flutter/material.dart';

import '../../../core/services/camera_service.dart';
import '../../../core/state/chitra_session.dart';
import 'image_enhancement_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  late CameraService _cameraService;
  final _session = ChitraSession.instance;
  bool _flashEnabled = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final permission = await _cameraService.requestCameraPermission();
      if (!permission) {
        _showMessage('Camera permission is required');
        return;
      }

      final imagePath = await _cameraService.capturePhoto();
      if (imagePath == null) {
        _showMessage('Failed to capture photo');
        return;
      }

      if (!mounted) return;

      // Navigate to enhancement screen
      final enhanced = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => ImageEnhancementScreen(
            imagePath: imagePath,
          ),
        ),
      );

      if (enhanced != null && mounted) {
        _session.addImagePath(enhanced);
        _showMessage('Image added to session');
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showMessage('Error capturing photo: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _toggleFlash() {
    setState(() {
      _flashEnabled = !_flashEnabled;
      _cameraService.setFlash(_flashEnabled);
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        actions: [
          IconButton(
            icon: Icon(
              _flashEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera guide overlay
          Container(
            color: Colors.black87,
            child: Center(
              child: Container(
                width: 250,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.cyan,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.document_scanner,
                      size: 64,
                      color: Colors.cyan.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Place document\nwithin the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Corner guides
          Positioned(
            top: 60,
            left: 30,
            child: _buildCornerGuide(),
          ),
          Positioned(
            top: 60,
            right: 30,
            child: Transform.flip(
              flipX: true,
              child: _buildCornerGuide(),
            ),
          ),
          Positioned(
            bottom: 140,
            left: 30,
            child: Transform.flip(
              flipY: true,
              child: _buildCornerGuide(),
            ),
          ),
          Positioned(
            bottom: 140,
            right: 30,
            child: Transform.flip(
              flipX: true,
              flipY: true,
              child: _buildCornerGuide(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Cancel',
            ),
            FloatingActionButton(
              onPressed: _isCapturing ? null : _capturePhoto,
              tooltip: 'Capture',
              child: _isCapturing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
            ),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Gallery',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerGuide() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.cyan, width: 3),
          left: BorderSide(color: Colors.cyan, width: 3),
        ),
      ),
    );
  }
}
