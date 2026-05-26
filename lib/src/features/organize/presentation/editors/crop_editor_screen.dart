import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'editor_utils.dart';

/// Crop editor with draggable corner handles (TL, TR, BR, BL).
/// Returns the cropped image path or null if cancelled.
class CropEditorScreen extends StatefulWidget {
  const CropEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<CropEditorScreen> createState() => _CropEditorScreenState();
}

class _CropEditorScreenState extends State<CropEditorScreen> {
  static const double _minZoom = 1.0;
  static const double _maxZoom = 4.0;

  // Normalized (0..1) corner points: TL, TR, BR, BL
  List<Offset> _corners = const [
    Offset(0.10, 0.10),
    Offset(0.90, 0.10),
    Offset(0.90, 0.90),
    Offset(0.10, 0.90),
  ];
  bool _saving = false;
  int _activePointers = 0;
  bool _draggingHandle = false;
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  double get _currentScale =>
      _transformController.value.getMaxScaleOnAxis().clamp(_minZoom, _maxZoom);

  void _setZoom(double value) {
    final next = value.clamp(_minZoom, _maxZoom);
    _transformController.value = Matrix4.identity()..scale(next);
    setState(() {});
  }

  void _zoomIn() => _setZoom(_currentScale + 0.25);

  void _zoomOut() => _setZoom(_currentScale - 0.25);

  void _moveCorner(int i, Offset delta, Size size) {
    final dx = delta.dx / size.width;
    final dy = delta.dy / size.height;
    setState(() {
      final c = _corners[i];
      _corners = List<Offset>.from(_corners)
        ..[i] = Offset(
          (c.dx + dx).clamp(0.02, 0.98),
          (c.dy + dy).clamp(0.02, 0.98),
        );
    });
  }

  void _moveCropWindow(Offset delta, Size size) {
    var ndx = delta.dx / size.width;
    var ndy = delta.dy / size.height;

    final minX = _corners.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    final maxX = _corners.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final minY = _corners.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    final maxY = _corners.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    if (minX + ndx < 0.02) ndx = 0.02 - minX;
    if (maxX + ndx > 0.98) ndx = 0.98 - maxX;
    if (minY + ndy < 0.02) ndy = 0.02 - minY;
    if (maxY + ndy > 0.98) ndy = 0.98 - maxY;

    setState(() {
      _corners = _corners
          .map((p) => Offset((p.dx + ndx).clamp(0.02, 0.98), (p.dy + ndy).clamp(0.02, 0.98)))
          .toList();
    });
  }

  Future<void> _applyCrop() async {
    setState(() => _saving = true);
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return;

      final xs = _corners.map((p) => p.dx);
      final ys = _corners.map((p) => p.dy);
      final x = (xs.reduce((a, b) => a < b ? a : b) * src.width).round().clamp(0, src.width - 1);
      final y = (ys.reduce((a, b) => a < b ? a : b) * src.height).round().clamp(0, src.height - 1);
      final w = ((xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b)) * src.width).round().clamp(1, src.width - x);
      final h = ((ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b)) * src.height).round().clamp(1, src.height - y);

      final cropped = img.copyCrop(src, x: x, y: y, width: w, height: h);
      final outBytes = img.encodeJpg(cropped, quality: 95);
      final path = await EditorUtils.writeToTemp(outBytes, 'jpg');
      if (mounted) Navigator.pop(context, path);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EditorUtils.editorBackground,
      appBar: AppBar(
        backgroundColor: EditorUtils.editorBackground,
        foregroundColor: Colors.white,
        title: const Text('Crop'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Zoom out',
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
          ),
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: () => _setZoom(1.0),
            icon: const Icon(Icons.center_focus_strong),
          ),
          TextButton(
            onPressed: _saving ? null : _applyCrop,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Apply', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (_, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        const handleRadius = 22.0;
        Offset toPx(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

        return Listener(
          onPointerDown: (_) => _activePointers++,
          onPointerUp: (_) => _activePointers = (_activePointers - 1).clamp(0, 10),
          onPointerCancel: (_) => _activePointers = (_activePointers - 1).clamp(0, 10),
          onPointerMove: (event) {
            if (_activePointers == 1 && !_draggingHandle) {
              _moveCropWindow(event.delta, size);
            }
          },
          child: Stack(
            children: [
              // Only the image is inside InteractiveViewer so zoom affects image only
              SizedBox(
                width: size.width,
                height: size.height,
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: _minZoom,
                  maxScale: _maxZoom,
                  panEnabled: false,
                  scaleEnabled: true,
                  child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
                ),
              ),
              // Crop overlay stays at fixed screen coordinates regardless of zoom
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CropPainter(_corners.map(toPx).toList()),
                  ),
                ),
              ),
              // Corner handles stay at fixed screen coordinates regardless of zoom
              for (var i = 0; i < _corners.length; i++)
                Positioned(
                  left: toPx(_corners[i]).dx - handleRadius,
                  top: toPx(_corners[i]).dy - handleRadius,
                  child: GestureDetector(
                    onPanStart: (_) => _draggingHandle = true,
                    onPanUpdate: (d) {
                      if (_activePointers <= 1) {
                        _moveCorner(i, d.delta, size);
                      }
                    },
                    onPanEnd: (_) => _draggingHandle = false,
                    onPanCancel: () => _draggingHandle = false,
                    child: Container(
                      width: handleRadius * 2,
                      height: handleRadius * 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyan, width: 3),
                        boxShadow: const [
                          BoxShadow(blurRadius: 4, color: Colors.black38),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.open_with, size: 16, color: Colors.cyan),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.pts);
  final List<Offset> pts;

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length != 4) return;
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..lineTo(pts[3].dx, pts[3].dy)
      ..close();
    final full = Path()..addRect(Offset.zero & size);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, path),
      Paint()..color = Colors.black.withAlpha(120),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.pts != pts;
}
