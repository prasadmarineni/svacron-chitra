import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import 'editor_utils.dart';

class SignatureEditorScreen extends StatefulWidget {
  const SignatureEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<SignatureEditorScreen> createState() => _SignatureEditorScreenState();
}

class _SignatureEditorScreenState extends State<SignatureEditorScreen> {
  final _sigKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  Color _inkColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _saving = false;

  static const _inkColors = [
    Colors.black,
    Colors.blue,
    Colors.red,
  ];

  void _onPanStart(DragStartDetails d) =>
      setState(() => _current = [d.localPosition]);

  void _onPanUpdate(DragUpdateDetails d) =>
      setState(() => _current.add(d.localPosition));

  void _onPanEnd(DragEndDetails _) {
    if (_current.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_current));
        _current = [];
      });
    }
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      // 1. Capture the signature canvas
      final renderObject = _sigKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final sigImage = await renderObject.toImage(pixelRatio: 3.0);
      final sigByteData =
          await sigImage.toByteData(format: ui.ImageByteFormat.png);
      final sigBytes = sigByteData!.buffer.asUint8List();
      final sigDecoded = img.decodeImage(sigBytes);

      // 2. Load source image
      final srcBytes = await File(widget.imagePath).readAsBytes();
      final src = img.decodeImage(srcBytes);
      if (src == null || sigDecoded == null) return;

      // 3. Composite signature onto bottom-right of source image
      final scale = src.width / sigDecoded.width;
      final scaledSig = img.copyResize(
        sigDecoded,
        width: (sigDecoded.width * scale * 0.4).toInt(),
      );

      final dx = src.width - scaledSig.width - 20;
      final dy = src.height - scaledSig.height - 20;
      img.compositeImage(src, scaledSig, dstX: dx, dstY: dy);

      final Uint8List out = img.encodeJpg(src, quality: 95);
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
        title: const Text('Signature'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () => setState(() {
              _strokes.clear();
              _current = [];
            }),
          ),
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
                onPressed: _strokes.isEmpty ? null : _apply,
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: _strokes.isEmpty ? Colors.grey : Colors.white,
                  ),
                ),
              ),
        ],
      ),
      body: Column(
        children: [
          // Instruction
          Container(
            color: EditorUtils.editorBackground,
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            child: const Text(
              'Draw your signature below — it will be placed on the document',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          // Signature canvas
          Expanded(
            child: Container(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: RepaintBoundary(
                  key: _sigKey,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _SignaturePainter(
                      _strokes,
                      _current,
                      _inkColor,
                      _strokeWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls
          Container(
            color: EditorUtils.editorBackground,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Ink color
                ..._inkColors.map(
                  (c) => GestureDetector(
                    onTap: () => setState(() => _inkColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _inkColor == c ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Stroke width
                const Icon(Icons.line_weight, color: Colors.white70, size: 16),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 8,
                    activeColor: Colors.blueAccent,
                    onChanged: (v) => setState(() => _strokeWidth = v),
                  ),
                ),
                // Undo
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white70),
                  onPressed:
                      _strokes.isEmpty
                          ? null
                          : () => setState(() => _strokes.removeLast()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes, this.current, this.color, this.width);
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final Color color;
  final double width;

  void _draw(Canvas canvas, List<Offset> pts) {
    if (pts.isEmpty) return;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
    if (pts.length == 1) {
      canvas.drawCircle(pts.first, width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = ui.Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    for (final s in strokes) {
      _draw(canvas, s);
    }
    _draw(canvas, current);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
