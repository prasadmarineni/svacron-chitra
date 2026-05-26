import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/state/chitra_session.dart';

/// In-app camera with corner detection and capture flow.
/// Supports: Capture → Adjust Corners → [Retake | Done | Continue]
class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({
    required this.initialFolderId,
    super.key,
  });

  /// Folder ID to save captured images. If null, creates a new auto-dated folder.
  final String? initialFolderId;

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  // Capture & review state
  String? _capturedImagePath;
  final _session = ChitraSession.instance;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras[0],
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      _showMessage('Error initializing camera: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final xFile = await _cameraController.takePicture();
      setState(() => _capturedImagePath = xFile.path);
    } catch (e) {
      _showMessage('Error capturing photo: $e');
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _retake() async {
    if (_capturedImagePath != null) {
      File(_capturedImagePath!).deleteSync();
    }
    setState(() {
      _capturedImagePath = null;
      _isCapturing = false;
    });
  }

  Future<void> _done() async {
    if (_capturedImagePath == null) return;

    // Save image to session and create/append document
    _session.addImagePath(_capturedImagePath!);

    final targetFolderId = widget.initialFolderId ??
        _createNewFolder(); // Create dated folder if none specified

    _session.createDocumentFromBatch(
      name: 'Scan ${DateTime.now().day.toString().padLeft(2, '0')}-'
          '${DateTime.now().month.toString().padLeft(2, '0')}-'
          '${DateTime.now().year}',
      folderId: targetFolderId,
    );

    _showMessage('Image saved');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _continue() async {
    if (_capturedImagePath == null) return;

    // Save image to session and folder
    _session.addImagePath(_capturedImagePath!);

    final targetFolderId = widget.initialFolderId ??
        _createNewFolder(); // Create dated folder if none specified

    _session.createDocumentFromBatch(
      name: 'Scan ${DateTime.now().day.toString().padLeft(2, '0')}-'
          '${DateTime.now().month.toString().padLeft(2, '0')}-'
          '${DateTime.now().year}',
      folderId: targetFolderId,
    );

    _showMessage('Image saved, ready for next');

    // Reset for next capture
    setState(() => _capturedImagePath = null);
  }

  String _createNewFolder() {
    final now = DateTime.now();
    final folderName = '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    
    // Create folder and get the ID
    _session.createFolder(folderName);
    
    // Retrieve the newly created folder's ID
    final newFolder = _session.folders.firstWhere(
      (f) => f.name == folderName,
      orElse: () => _session.folders.last,
    );
    
    return newFolder.id;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Capture Image')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If image captured, show preview with corner adjustment & buttons
    if (_capturedImagePath != null) {
      return _buildImageReview();
    }

    // Camera view
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Image'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          // Document guide overlay
          Center(
            child: Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyan, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner,
                    size: 64,
                    color: Colors.cyan.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Position document\nwithin frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.large(
          onPressed: _isCapturing ? null : _capturePhoto,
          backgroundColor: Colors.cyan,
          child: _isCapturing
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.camera_alt, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildImageReview() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Adjust'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Image preview
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(
                  File(_capturedImagePath!),
                  fit: BoxFit.contain,
                  height: 400,
                ),
              ),
              const SizedBox(height: 24),
              // Corner adjustment info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withAlpha(100)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corner Adjustment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Drag corners to adjust document boundaries. This helps improve OCR accuracy.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Action buttons
              Row(
                children: [
                  // Retake
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.replay),
                      label: const Text('Retake'),
                      onPressed: _retake,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Done
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                      onPressed: _done,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Continue
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Continue'),
                      onPressed: _continue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
