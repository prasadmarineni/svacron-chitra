import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'editor_utils.dart';

enum _WatermarkPosition { center, topLeft, topRight, bottomLeft, bottomRight, tiled }

class WatermarkEditorScreen extends StatefulWidget {
  const WatermarkEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<WatermarkEditorScreen> createState() => _WatermarkEditorScreenState();
}

class _WatermarkEditorScreenState extends State<WatermarkEditorScreen> {
  final _key = GlobalKey();
  final _textController = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.35;
  double _fontSize = 36.0;
  Color _color = Colors.red;
  _WatermarkPosition _position = _WatermarkPosition.center;
  bool _saving = false;

  static const _colors = [
    Colors.red,
    Colors.white,
    Colors.black,
    Colors.grey,
    Colors.blue,
  ];

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
        title: const Text('Watermark'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
            child: RepaintBoundary(
              key: _key,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.imagePath), fit: BoxFit.contain),
                  CustomPaint(
                    painter: _WatermarkPainter(
                      text: _textController.text,
                      opacity: _opacity,
                      fontSize: _fontSize,
                      color: _color,
                      position: _position,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: EditorUtils.editorBackground,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text input
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Watermark text...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                // Opacity
                Row(
                  children: [
                    const Text(
                      'Opacity',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: _opacity,
                        min: 0.05,
                        max: 1.0,
                        activeColor: Colors.blueAccent,
                        onChanged: (v) => setState(() => _opacity = v),
                      ),
                    ),
                    Text(
                      '${(_opacity * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                // Font size
                Row(
                  children: [
                    const Text(
                      'Size',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 16,
                        max: 80,
                        activeColor: Colors.blueAccent,
                        onChanged: (v) => setState(() => _fontSize = v),
                      ),
                    ),
                    // Color dots
                    Row(
                      children:
                          _colors.map((c) {
                            return GestureDetector(
                              onTap: () => setState(() => _color = c),
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        _color == c
                                            ? Colors.white
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                // Position chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _WatermarkPosition.values.map((p) {
                          final label = p.name[0].toUpperCase() + p.name.substring(1);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(label, style: const TextStyle(fontSize: 11)),
                              selected: _position == p,
                              onSelected: (_) => setState(() => _position = p),
                              selectedColor: Colors.blueAccent,
                              backgroundColor: Colors.grey[800],
                              labelStyle: TextStyle(
                                color:
                                    _position == p ? Colors.white : Colors.grey[300],
                              ),
                            ),
                          );
                        }).toList(),
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

class _WatermarkPainter extends CustomPainter {
  _WatermarkPainter({
    required this.text,
    required this.opacity,
    required this.fontSize,
    required this.color,
    required this.position,
  });

  final String text;
  final double opacity;
  final double fontSize;
  final Color color;
  final _WatermarkPosition position;

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    final style = ui.TextStyle(
      color: color.withValues(alpha: opacity),
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(style)
      ..addText(text);
    final para = pb.build()..layout(ui.ParagraphConstraints(width: size.width));

    if (position == _WatermarkPosition.tiled) {
      final tileH = para.height + 40;
      final tileW = para.longestLine + 40;
      for (double y = 0; y < size.height; y += tileH) {
        for (double x = 0; x < size.width; x += tileW) {
          canvas.save();
          canvas.translate(x + tileW / 2, y + tileH / 2);
          canvas.rotate(-0.4);
          canvas.drawParagraph(para, Offset(-para.longestLine / 2, -para.height / 2));
          canvas.restore();
        }
      }
    } else {
      Offset offset;
      switch (position) {
        case _WatermarkPosition.center:
          offset = Offset(0, (size.height - para.height) / 2);
        case _WatermarkPosition.topLeft:
          offset = const Offset(16, 16);
        case _WatermarkPosition.topRight:
          offset = Offset(size.width - para.longestLine - 16, 16);
        case _WatermarkPosition.bottomLeft:
          offset = Offset(16, size.height - para.height - 16);
        case _WatermarkPosition.bottomRight:
          offset = Offset(
            size.width - para.longestLine - 16,
            size.height - para.height - 16,
          );
        case _WatermarkPosition.tiled:
          offset = Offset.zero; // handled above
      }
      canvas.drawParagraph(para, offset);
    }
  }

  @override
  bool shouldRepaint(_WatermarkPainter old) => true;
}
