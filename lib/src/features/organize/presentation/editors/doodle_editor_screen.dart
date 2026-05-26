import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'editor_utils.dart';

class DoodleEditorScreen extends StatefulWidget {
  const DoodleEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<DoodleEditorScreen> createState() => _DoodleEditorScreenState();
}

class _DoodleEditorScreenState extends State<DoodleEditorScreen> {
  final _key = GlobalKey();
  final List<_DoodlePath> _paths = [];
  List<Offset> _currentPath = [];
  Color _color = Colors.redAccent;
  double _strokeWidth = 4.0;
  bool _saving = false;

  static const _colors = [
    Colors.redAccent,
    Colors.yellow,
    Colors.white,
    Colors.black,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orange,
    Colors.purpleAccent,
  ];

  void _onPanStart(DragStartDetails d) =>
      setState(() => _currentPath = [d.localPosition]);

  void _onPanUpdate(DragUpdateDetails d) =>
      setState(() => _currentPath.add(d.localPosition));

  void _onPanEnd(DragEndDetails _) {
    if (_currentPath.isNotEmpty) {
      setState(() {
        _paths.add(
          _DoodlePath(
            points: List.from(_currentPath),
            color: _color,
            strokeWidth: _strokeWidth,
          ),
        );
        _currentPath = [];
      });
    }
  }

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
      backgroundColor: EditorUtils.editorBackground,
      appBar: AppBar(
        backgroundColor: EditorUtils.editorBackground,
        foregroundColor: Colors.white,
        title: const Text('Doodle'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed:
                _paths.isEmpty ? null : () => setState(() => _paths.removeLast()),
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
                      painter: _DoodlePainter(
                        _paths,
                        _currentPath,
                        _color,
                        _strokeWidth,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: EditorUtils.editorBackground,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _colors.map((c) {
                          return GestureDetector(
                            onTap: () => setState(() => _color = c),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      _color == c
                                          ? Colors.white
                                          : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                // Stroke width
                Row(
                  children: [
                    const Icon(Icons.line_weight, color: Colors.white70, size: 18),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 2,
                        max: 30,
                        activeColor: Colors.blueAccent,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                    Text(
                      _strokeWidth.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoodlePath {
  _DoodlePath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.paths, this.current, this.currentColor, this.currentWidth);
  final List<_DoodlePath> paths;
  final List<Offset> current;
  final Color currentColor;
  final double currentWidth;

  void _drawPath(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in paths) {
      _drawPath(canvas, p.points, p.color, p.strokeWidth);
    }
    if (current.isNotEmpty) {
      _drawPath(canvas, current, currentColor, currentWidth);
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => true;
}
