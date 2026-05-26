import 'dart:io';

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

  /// Accumulated pages for this scanning session.
  final List<String> _scannedPages = [];

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
          builder: (_) => ImageEnhancementScreen(imagePath: imagePath),
        ),
      );

      if (enhanced != null && mounted) {
        setState(() => _scannedPages.add(enhanced));
        // Show review bottom sheet
        await _showPageReview(enhanced);
      }
    } catch (e) {
      _showMessage('Error capturing photo: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  /// Shows a bottom sheet after each scan with Retake / Next Page / Save options.
  Future<void> _showPageReview(String imagePath) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Thumbnail of scanned page
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath),
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Page ${_scannedPages.length} scanned',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _scannedPages.length == 1
                              ? '1 page in document'
                              : '${_scannedPages.length} pages in document',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Retake — removes last page, closes sheet
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.replay),
                      label: const Text('Retake'),
                      onPressed: () {
                        setState(() => _scannedPages.removeLast());
                        Navigator.pop(sheetCtx);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Next Page — closes sheet, stays in camera for next scan
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Next Page'),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Save — saves all pages as a document and exits
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save'),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _saveDocument();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveDocument() {
    if (_scannedPages.isEmpty) {
      Navigator.pop(context);
      return;
    }
    for (final p in _scannedPages) {
      _session.addImagePath(p);
    }
    _session.createDocumentFromBatch(
      name: 'Scan ${DateTime.now().day.toString().padLeft(2, '0')}-'
          '${DateTime.now().month.toString().padLeft(2, '0')}-'
          '${DateTime.now().year}',
    );
    if (mounted) Navigator.pop(context);
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

  /// Called when user tries to exit (back gesture, close button).
  /// If pages exist, prompts Save / Discard / Cancel.
  Future<bool> _confirmExit() async {
    if (_scannedPages.isEmpty) return true;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Save scanned pages?'),
        content: Text(
          '${_scannedPages.length} page${_scannedPages.length == 1 ? '' : 's'} will be lost if you exit without saving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      _saveDocument();
      return false; // _saveDocument already pops
    }
    return result == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await _confirmExit();
        if (canExit && mounted) Navigator.pop(context);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          _scannedPages.isEmpty
              ? 'Scan Document'
              : 'Scanning — ${_scannedPages.length} page${_scannedPages.length == 1 ? '' : 's'}',
        ),
        actions: [
          IconButton(
            icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          if (_scannedPages.isNotEmpty)
            TextButton(
              onPressed: _saveDocument,
              child: const Text('Save'),
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
                  border: Border.all(color: Colors.cyan, width: 3),
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
                    Text(
                      _scannedPages.isEmpty
                          ? 'Place document\nwithin the frame'
                          : 'Place next page\nwithin the frame',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
            child: Transform.flip(flipX: true, child: _buildCornerGuide()),
          ),
          Positioned(
            bottom: 140,
            left: 30,
            child: Transform.flip(flipY: true, child: _buildCornerGuide()),
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
          // Scanned pages thumbnail strip at the bottom-left
          if (_scannedPages.isNotEmpty)
            Positioned(
              bottom: 90,
              left: 12,
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: _scannedPages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(_scannedPages[i]),
                          width: 45,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
              onPressed: () async {
                final canExit = await _confirmExit();
                if (canExit && mounted) Navigator.pop(context);
              },
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
              onPressed: () async {
                final canExit = await _confirmExit();
                if (canExit && mounted) Navigator.pop(context);
              },
              tooltip: 'Gallery',
            ),
          ],
        ),
      ),
    ),   // closes Scaffold (child of PopScope)
    );   // closes PopScope
  }

  Widget _buildCornerGuide() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.cyan, width: 3),
          left: BorderSide(color: Colors.cyan, width: 3),
        ),
      ),
    );
  }
}

