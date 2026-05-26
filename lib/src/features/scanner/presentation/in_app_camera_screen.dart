import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../core/state/chitra_session.dart';
import '../../../core/storage/app_storage.dart';

/// Document type enum for scanner modes
enum DocumentType { document, ids, ocrText, signature }

/// In-app camera with corner detection and capture flow.
/// Supports: Capture -> Adjust Corners -> [Retake | Done | Continue]
class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({required this.initialFolderId, super.key});

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
  bool _isAutoDetectingEdges = false;

  String? _capturedImagePath;
  String? _lastCaptureThumbnailPath;
  final _session = ChitraSession.instance;
  String? _targetFolderId;

  DocumentType _selectedDocType = DocumentType.document;
  bool _autoCapture = false;

  // Normalized corner points (0..1) in order: TL, TR, BR, BL
  List<Offset>? _cornerPoints;

  static const List<Offset> _defaultCornerPoints = [
    Offset(0.10, 0.10),
    Offset(0.90, 0.10),
    Offset(0.90, 0.90),
    Offset(0.10, 0.90),
  ];

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
      final persistentPath = AppStorage.newImagePath();
      await File(xFile.path).copy(persistentPath);

      final detectedCorners = _autoCapture
          ? await _detectDocumentCorners(persistentPath)
          : null;

      if (!mounted) return;
      setState(() {
        _capturedImagePath = persistentPath;
        _lastCaptureThumbnailPath = persistentPath;
        _cornerPoints = detectedCorners ?? _defaultCornerPoints;
        _isCapturing = false;
      });
    } catch (e) {
      _showMessage('Error capturing photo: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _retake() async {
    if (_capturedImagePath != null) {
      final file = File(_capturedImagePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    setState(() {
      _capturedImagePath = null;
      _isCapturing = false;
      _cornerPoints = null;
    });
  }

  Future<void> _done() async {
    await _saveCaptureAndProceed(exitAfterSave: true);
  }

  Future<void> _continueCapture() async {
    await _saveCaptureAndProceed(exitAfterSave: false);
  }

  Future<void> _saveCaptureAndProceed({required bool exitAfterSave}) async {
    if (_capturedImagePath == null) return;

    final processedPath = await _applyCornerCrop(_capturedImagePath!);
    final folderId = _targetFolderId ?? _ensureTargetFolderId();
    final docName = _nextDocumentName();

    _session.clearImages();
    _session.addImagePath(processedPath);
    _session.createDocumentFromBatch(name: docName, folderId: folderId);

    if (!mounted) return;
    if (exitAfterSave) {
      Navigator.pop(context);
    } else {
      _showMessage('$docName saved. Capture next page.');
      setState(() {
        _capturedImagePath = null;
        _isCapturing = false;
        _cornerPoints = null;
      });
    }
  }

  String _nextDocumentName() {
    var index = 1;
    final existing = _session.documents.map((d) => d.name.toLowerCase()).toSet();
    while (existing.contains('document$index')) {
      index++;
    }
    return 'Document$index';
  }

  String _ensureTargetFolderId() {
    if (_targetFolderId != null) return _targetFolderId!;

    if (widget.initialFolderId != null) {
      _targetFolderId = widget.initialFolderId;
      return _targetFolderId!;
    }

    _targetFolderId = _createNewFolder();
    return _targetFolderId!;
  }

  String _createNewFolder() {
    final now = DateTime.now();
    final folderName =
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';

    _session.createFolder(folderName);

    final newFolder = _session.folders.firstWhere(
      (f) => f.name == folderName,
      orElse: () => _session.folders.last,
    );

    return newFolder.id;
  }

  Future<String> _applyCornerCrop(String imagePath) async {
    if (_cornerPoints == null || _cornerPoints!.length != 4) {
      return imagePath;
    }

    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imagePath;

      final leftNorm = _cornerPoints!
          .map((p) => p.dx)
          .reduce((a, b) => a < b ? a : b)
          .clamp(0.0, 1.0);
      final rightNorm = _cornerPoints!
          .map((p) => p.dx)
          .reduce((a, b) => a > b ? a : b)
          .clamp(0.0, 1.0);
      final topNorm = _cornerPoints!
          .map((p) => p.dy)
          .reduce((a, b) => a < b ? a : b)
          .clamp(0.0, 1.0);
      final bottomNorm = _cornerPoints!
          .map((p) => p.dy)
          .reduce((a, b) => a > b ? a : b)
          .clamp(0.0, 1.0);

      final x = (leftNorm * decoded.width).round().clamp(0, decoded.width - 1);
      final y = (topNorm * decoded.height).round().clamp(0, decoded.height - 1);
      final width = ((rightNorm - leftNorm) * decoded.width)
          .round()
          .clamp(1, decoded.width - x);
      final height = ((bottomNorm - topNorm) * decoded.height)
          .round()
          .clamp(1, decoded.height - y);

      final cropped = img.copyCrop(decoded, x: x, y: y, width: width, height: height);
      final outPath = AppStorage.newImagePath();
      await File(outPath).writeAsBytes(img.encodeJpg(cropped, quality: 95));
      return outPath;
    } catch (_) {
      return imagePath;
    }
  }

  Future<List<Offset>?> _detectDocumentCorners(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      var working = decoded;
      if (decoded.width > 900 || decoded.height > 900) {
        if (decoded.width >= decoded.height) {
          working = img.copyResize(decoded, width: 900);
        } else {
          working = img.copyResize(decoded, height: 900);
        }
      }

      int luminance(img.Pixel p) =>
          ((0.299 * p.r) + (0.587 * p.g) + (0.114 * p.b)).round();

      final borderSamples = <int>[];
      final w = working.width;
      final h = working.height;

      const step = 4;
      for (var x = 0; x < w; x += step) {
        borderSamples.add(luminance(working.getPixelSafe(x, 0)));
        borderSamples.add(luminance(working.getPixelSafe(x, h - 1)));
      }
      for (var y = 0; y < h; y += step) {
        borderSamples.add(luminance(working.getPixelSafe(0, y)));
        borderSamples.add(luminance(working.getPixelSafe(w - 1, y)));
      }

      if (borderSamples.isEmpty) return null;
      final bg = borderSamples.reduce((a, b) => a + b) / borderSamples.length;

      var minX = w;
      var minY = h;
      var maxX = -1;
      var maxY = -1;

      const threshold = 20;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final l = luminance(working.getPixelSafe(x, y));
          if ((l - bg).abs() >= threshold) {
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
          }
        }
      }

      if (maxX <= minX || maxY <= minY) return null;

      final boxW = maxX - minX;
      final boxH = maxY - minY;
      final coverage = (boxW * boxH) / (w * h);
      if (coverage < 0.12 || coverage > 0.96) return null;

      final marginX = (0.02 * w).round();
      final marginY = (0.02 * h).round();
      minX = (minX - marginX).clamp(0, w - 1);
      minY = (minY - marginY).clamp(0, h - 1);
      maxX = (maxX + marginX).clamp(0, w - 1);
      maxY = (maxY + marginY).clamp(0, h - 1);

      final left = (minX / w).clamp(0.02, 0.98);
      final top = (minY / h).clamp(0.02, 0.98);
      final right = (maxX / w).clamp(0.02, 0.98);
      final bottom = (maxY / h).clamp(0.02, 0.98);

      if (right - left < 0.10 || bottom - top < 0.10) return null;

      return [
        Offset(left, top),
        Offset(right, top),
        Offset(right, bottom),
        Offset(left, bottom),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> _runAutoEdgeDetection() async {
    if (_capturedImagePath == null || _isAutoDetectingEdges) return;

    setState(() => _isAutoDetectingEdges = true);
    try {
      final corners = await _detectDocumentCorners(_capturedImagePath!);
      if (!mounted) return;

      if (corners == null) {
        _showMessage('Auto edge detection failed. Adjust corners manually.');
        return;
      }

      setState(() {
        _autoCapture = true;
        _cornerPoints = corners;
      });
      _showMessage('Auto edges applied.');
    } finally {
      if (mounted) {
        setState(() => _isAutoDetectingEdges = false);
      }
    }
  }

  void _moveCorner(int index, Offset delta, Size size) {
    if (_cornerPoints == null || index < 0 || index > 3) return;
    final dx = delta.dx / size.width;
    final dy = delta.dy / size.height;
    final current = _cornerPoints![index];
    final updated = Offset(
      (current.dx + dx).clamp(0.02, 0.98),
      (current.dy + dy).clamp(0.02, 0.98),
    );

    setState(() {
      _cornerPoints = [..._cornerPoints!]..[index] = updated;
    });
  }

  Widget _buildCoverCameraPreview() {
    final previewSize = _cameraController.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(_cameraController);
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(_cameraController),
          ),
        ),
      ),
    );
  }

  Widget _buildManualAutoToggle({double fontSize = 12}) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _autoCapture = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: !_autoCapture ? Colors.cyan : Colors.grey.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  'Manual',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              setState(() => _autoCapture = true);
              if (_capturedImagePath != null) {
                await _runAutoEdgeDetection();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: _autoCapture ? Colors.cyan : Colors.grey.shade700,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  'Auto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocTypeButton(DocumentType type, String label, IconData icon) {
    final isSelected = _selectedDocType == type;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => _selectedDocType = type);
        _showMessage('$label mode selected');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.cyan : Colors.grey.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
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

    if (_capturedImagePath != null) {
      return _buildImageReview();
    }

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
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: _buildCoverCameraPreview(),
            ),
          ),
          Center(
            child: Container(
              width: 290,
              height: 395,
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
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildDocTypeButton(DocumentType.document, 'Document', Icons.description),
                    const SizedBox(width: 8),
                    _buildDocTypeButton(DocumentType.ids, 'IDs', Icons.credit_card),
                    const SizedBox(width: 8),
                    _buildDocTypeButton(DocumentType.ocrText, 'OCR Text', Icons.text_fields),
                    const SizedBox(width: 8),
                    _buildDocTypeButton(DocumentType.signature, 'Signature', Icons.edit),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 118,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildManualAutoToggle(fontSize: 11),
                        const SizedBox(height: 8),
                        if (_lastCaptureThumbnailPath != null)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.cyan, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(_lastCaptureThumbnailPath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image_not_supported, size: 24),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FloatingActionButton.small(
                    onPressed: _isCapturing ? null : _capturePhoto,
                    backgroundColor: Colors.cyan,
                    child: _isCapturing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.camera_alt, size: 20),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
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
        actions: [
          TextButton.icon(
            onPressed: _isAutoDetectingEdges ? null : _runAutoEdgeDetection,
            icon: _isAutoDetectingEdges
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
            label: const Text('Auto Edge'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewHeight = constraints.maxHeight - 100;
            final handleRadius = 14.0;
            final size = Size(constraints.maxWidth, previewHeight);
            final points = _cornerPoints ?? _defaultCornerPoints;

            Offset toPx(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

            return SizedBox(
              height: previewHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_capturedImagePath!),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CropOverlayPainter(points.map(toPx).toList()),
                    ),
                  ),
                  for (var i = 0; i < points.length; i++)
                    Positioned(
                      left: toPx(points[i]).dx - handleRadius,
                      top: toPx(points[i]).dy - handleRadius,
                      child: GestureDetector(
                        onPanUpdate: (d) => _moveCorner(i, d.delta, size),
                        child: Container(
                          width: handleRadius * 2,
                          height: handleRadius * 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(handleRadius),
                            border: Border.all(color: Colors.cyan.shade700, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _buildManualAutoToggle(),
            ),
            SizedBox(
              height: 50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildDocTypeButton(DocumentType.document, 'Document', Icons.description),
                    const SizedBox(width: 8),
                    _buildDocTypeButton(DocumentType.ids, 'IDs', Icons.credit_card),
                    const SizedBox(width: 8),
                    _buildDocTypeButton(DocumentType.ocrText, 'OCR Text', Icons.text_fields),
                    const SizedBox(width: 8),
                    _buildDocTypeButton(DocumentType.signature, 'Signature', Icons.edit),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Retake'),
                    onPressed: _retake,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Continue'),
                      onPressed: _continueCapture,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    onPressed: _done,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length != 4) return;

    final maskPaint = Paint()..color = Colors.black.withAlpha(75);
    final borderPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    final fullRect = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final outside = Path.combine(PathOperation.difference, fullRect, path);

    canvas.drawPath(outside, maskPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
