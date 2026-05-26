import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'editor_utils.dart';

enum _FilterType { original, grayscale, sepia, invert, vivid, cold, warm }

class ColorFilterEditorScreen extends StatefulWidget {
  const ColorFilterEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<ColorFilterEditorScreen> createState() =>
      _ColorFilterEditorScreenState();
}

class _ColorFilterEditorScreenState extends State<ColorFilterEditorScreen> {
  _FilterType _filter = _FilterType.original;
  double _brightness = 0.0; // -1..1
  double _contrast = 1.0; // 0..2
  bool _saving = false;
  img.Image? _decoded;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded != null && mounted) setState(() => _decoded = decoded);
  }

  img.Image _applyFilter(img.Image src) {
    img.Image out;
    switch (_filter) {
      case _FilterType.grayscale:
        out = img.grayscale(img.Image.from(src));
      case _FilterType.sepia:
        out = img.sepia(img.Image.from(src));
      case _FilterType.invert:
        out = img.invert(img.Image.from(src));
      case _FilterType.vivid:
        out = img.adjustColor(
          img.Image.from(src),
          saturation: 1.5,
          contrast: 1.1,
        );
      case _FilterType.cold:
        out = img.adjustColor(img.Image.from(src), hue: 200);
      case _FilterType.warm:
        out = img.adjustColor(img.Image.from(src), hue: 30);
      case _FilterType.original:
        out = img.Image.from(src);
    }
    // Apply brightness & contrast tweaks
    if (_brightness != 0.0 || _contrast != 1.0) {
      out = img.adjustColor(
        out,
        brightness: _brightness,
        contrast: _contrast,
      );
    }
    return out;
  }

  Future<void> _apply() async {
    if (_decoded == null) return;
    setState(() => _saving = true);
    try {
      final processed = _applyFilter(_decoded!);
      final Uint8List outBytes = img.encodeJpg(processed, quality: 95);
      final path = await EditorUtils.writeToTemp(outBytes, 'jpg');
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
        title: const Text('Color Filters'),
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
          // Image preview
          Expanded(
            child:
                _decoded == null
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : Image.file(File(widget.imagePath), fit: BoxFit.contain),
          ),

          // Filter chips
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children:
                    _FilterType.values.map((f) {
                      final label = f.name[0].toUpperCase() + f.name.substring(1);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: Colors.blueAccent,
                          labelStyle: TextStyle(
                            color: _filter == f ? Colors.white : Colors.grey[300],
                          ),
                          backgroundColor: Colors.grey[800],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // Brightness & Contrast sliders
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text(
                        'Brightness',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _brightness,
                        min: -1.0,
                        max: 1.0,
                        activeColor: Colors.blueAccent,
                        onChanged: (v) => setState(() => _brightness = v),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        _brightness.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text(
                        'Contrast',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _contrast,
                        min: 0.0,
                        max: 2.0,
                        activeColor: Colors.blueAccent,
                        onChanged: (v) => setState(() => _contrast = v),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        _contrast.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
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
