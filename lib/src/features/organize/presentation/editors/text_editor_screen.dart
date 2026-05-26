import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'editor_utils.dart';

class TextEditorScreen extends StatefulWidget {
  const TextEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  final _key = GlobalKey();
  final _textController = TextEditingController(text: 'Your text here');
  final List<_TextLabel> _labels = [];
  Color _color = Colors.red;
  double _fontSize = 28.0;
  bool _saving = false;
  bool _showInput = true;

  static const _colorOptions = [
    Colors.red,
    Colors.yellow,
    Colors.white,
    Colors.black,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  void _addText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _labels.add(
        _TextLabel(
          text: text,
          color: _color,
          fontSize: _fontSize,
          position: const Offset(100, 100),
        ),
      );
      _showInput = false;
    });
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
        title: const Text('Add Text'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add another',
            onPressed: () => setState(() => _showInput = true),
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
                onPressed: _labels.isEmpty ? null : _apply,
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: _labels.isEmpty ? Colors.grey : Colors.white,
                  ),
                ),
              ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: RepaintBoundary(
              key: _key,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.imagePath), fit: BoxFit.contain),
                  ..._labels.map(
                    (label) => _DraggableText(
                      label: label,
                      onMoved:
                          (pos) => setState(() => label.position = pos),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Input panel
          if (_showInput)
            Container(
              color: Colors.grey[850],
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type text...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Size',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 12,
                          max: 80,
                          activeColor: Colors.blueAccent,
                          onChanged: (v) => setState(() => _fontSize = v),
                        ),
                      ),
                      // Colors
                      Row(
                        children:
                            _colorOptions.map((c) {
                              return GestureDetector(
                                onTap: () => setState(() => _color = c),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  width: 24,
                                  height: 24,
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
                  ElevatedButton.icon(
                    onPressed: _addText,
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
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

class _TextLabel {
  _TextLabel({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.position,
  });
  final String text;
  final Color color;
  final double fontSize;
  Offset position;
}

class _DraggableText extends StatelessWidget {
  const _DraggableText({required this.label, required this.onMoved});
  final _TextLabel label;
  final ValueChanged<Offset> onMoved;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: label.position.dx,
      top: label.position.dy,
      child: GestureDetector(
        onPanUpdate: (d) => onMoved(label.position + d.delta),
        child: Text(
          label.text,
          style: TextStyle(
            color: label.color,
            fontSize: label.fontSize,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(blurRadius: 4, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
