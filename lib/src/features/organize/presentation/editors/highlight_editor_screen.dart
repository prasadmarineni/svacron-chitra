import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'editor_utils.dart';

class HighlightEditorScreen extends StatefulWidget {
  const HighlightEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<HighlightEditorScreen> createState() => _HighlightEditorScreenState();
}

class _HighlightEditorScreenState extends State<HighlightEditorScreen> {
  final _key = GlobalKey();
  final List<_HighlightRect> _rects = [];
  Offset? _dragStart;
  Rect? _currentRect;
  Color _color = const Color(0xAAFFEB3B); // yellow semi-transparent
  bool _saving = false;

  static const _colors = [
    Color(0xAAFFEB3B), // yellow
    Color(0xAA00BCD4), // cyan
    Color(0xAA4CAF50), // green
    Color(0xAAF06292), // pink
    Color(0xAA90CAF9), // light blue
  ];

  void _onPanStart(DragStartDetails d) =>
      setState(() => _dragStart = d.localPosition);

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    setState(
      () =>
          _currentRect = Rect.fromPoints(_dragStart!, d.localPosition),
    );
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentRect != null && _currentRect!.width > 10) {
      setState(
        () => _rects.add(_HighlightRect(rect: _currentRect!, color: _color)),
      );
    }
    _dragStart = null;
    _currentRect = null;
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Highlight'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed:
                _rects.isEmpty ? null : () => setState(() => _rects.removeLast()),
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
                      painter: _HighlightPainter(_rects, _currentRect, _color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Color:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 12),
                ..._colors.map(
                  (c) => GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightRect {
  _HighlightRect({required this.rect, required this.color});
  final Rect rect;
  final Color color;
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.rects, this.current, this.currentColor);
  final List<_HighlightRect> rects;
  final Rect? current;
  final Color currentColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in rects) {
      canvas.drawRect(r.rect, Paint()..color = r.color);
    }
    if (current != null) {
      canvas.drawRect(
        current!,
        Paint()
          ..color = currentColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        current!,
        Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => true;
}
