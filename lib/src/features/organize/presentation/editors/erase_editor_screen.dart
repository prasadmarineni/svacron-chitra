import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'editor_utils.dart';

class EraseEditorScreen extends StatefulWidget {
  const EraseEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<EraseEditorScreen> createState() => _EraseEditorScreenState();
}

class _EraseEditorScreenState extends State<EraseEditorScreen> {
  final _key = GlobalKey();
  final List<_ErasePath> _paths = [];
  _ErasePath? _current;
  double _brushSize = 24.0;
  bool _saving = false;

  void _onPanStart(DragStartDetails d) {
    _current = _ErasePath(brushSize: _brushSize)..points.add(d.localPosition);
    setState(() => _paths.add(_current!));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _current?.points.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) => _current = null;

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      final path = await EditorUtils.captureBoundary(_key);
      if (mounted) Navigator.pop(context, path);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Erase'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed:
                _paths.isEmpty
                    ? null
                    : () => setState(() => _paths.removeLast()),
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
                onPressed: _apply,
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
              child: RepaintBoundary(
                key: _key,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(widget.imagePath), fit: BoxFit.contain),
                    CustomPaint(
                      painter: _ErasePainter(_paths),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.cleaning_services,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Brush Size',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: _brushSize,
                    min: 8,
                    max: 80,
                    activeColor: Colors.blueAccent,
                    onChanged: (v) => setState(() => _brushSize = v),
                  ),
                ),
                Text(
                  _brushSize.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErasePath {
  _ErasePath({required this.brushSize});
  final double brushSize;
  final List<Offset> points = [];
}

class _ErasePainter extends CustomPainter {
  _ErasePainter(this.paths);
  final List<_ErasePath> paths;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in paths) {
      final paint =
          Paint()
            ..color = Colors.white
            ..strokeWidth = p.brushSize
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;
      if (p.points.length == 1) {
        canvas.drawCircle(p.points.first, p.brushSize / 2, paint..style = PaintingStyle.fill);
      } else {
        final path = ui.Path()..moveTo(p.points.first.dx, p.points.first.dy);
        for (final pt in p.points.skip(1)) {
          path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ErasePainter old) => old.paths != paths;
}
