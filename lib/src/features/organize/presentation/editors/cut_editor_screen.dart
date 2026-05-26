import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'editor_utils.dart';

/// Drag a rectangle selection and crop to it — like Crop but with drag-to-select.
class CutEditorScreen extends StatefulWidget {
  const CutEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<CutEditorScreen> createState() => _CutEditorScreenState();
}

class _CutEditorScreenState extends State<CutEditorScreen> {
  Offset? _start;
  Rect? _selection;
  bool _saving = false;

  void _onPanStart(DragStartDetails d) =>
      setState(() {
        _start = d.localPosition;
        _selection = null;
      });

  void _onPanUpdate(DragUpdateDetails d) {
    if (_start == null) return;
    setState(() => _selection = Rect.fromPoints(_start!, d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {}

  Future<void> _apply(Size renderSize) async {
    if (_selection == null || _selection!.width < 10) return;
    setState(() => _saving = true);
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return;

      // Map render-box coordinates → image pixel coordinates
      final scaleX = src.width / renderSize.width;
      final scaleY = src.height / renderSize.height;

      final x = (_selection!.left * scaleX).round().clamp(0, src.width - 1);
      final y = (_selection!.top * scaleY).round().clamp(0, src.height - 1);
      final w = (_selection!.width * scaleX).round().clamp(1, src.width - x);
      final h = (_selection!.height * scaleY).round().clamp(1, src.height - y);

      final cropped = img.copyCrop(src, x: x, y: y, width: w, height: h);
      final Uint8List out = img.encodeJpg(cropped, quality: 95);
      final path = await EditorUtils.writeToTemp(out, 'jpg');
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
        title: const Text('Cut (Select & Crop)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selection != null)
            _saving
                ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
                : TextButton(
                  onPressed: () {
                    // We need layout size — use LayoutBuilder key below
                    if (_renderKey.currentContext != null) {
                      final box = _renderKey.currentContext!.findRenderObject()
                          as RenderBox;
                      _apply(box.size);
                    }
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    key: _renderKey,
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                  ),
                  if (_selection != null)
                    CustomPaint(painter: _SelectionPainter(_selection!)),
                ],
              ),
            ),
          ),
          Container(
            color: EditorUtils.editorBackground,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Drag to select the area you want to keep',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  final _renderKey = GlobalKey();
}

class _SelectionPainter extends CustomPainter {
  _SelectionPainter(this.rect);
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    // Dim overlay outside selection
    final outside =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRect(rect)
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outside, Paint()..color = Colors.black54);

    // Selection border
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Corner handles
    const handleSize = 10.0;
    final handlePaint = Paint()..color = Colors.white;
    for (final corner in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      canvas.drawRect(
        Rect.fromCenter(center: corner, width: handleSize, height: handleSize),
        handlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter old) => old.rect != rect;
}
