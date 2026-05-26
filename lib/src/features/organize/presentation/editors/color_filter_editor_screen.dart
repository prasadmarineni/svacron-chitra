import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'editor_utils.dart';

class _FilterOption {
  final String name;
  final String label;
  final Function(img.Image) apply;

  _FilterOption({
    required this.name,
    required this.label,
    required this.apply,
  });
}

class ColorFilterEditorScreen extends StatefulWidget {
  const ColorFilterEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<ColorFilterEditorScreen> createState() =>
      _ColorFilterEditorScreenState();
}

class _ColorFilterEditorScreenState extends State<ColorFilterEditorScreen> {
  late List<_FilterOption> _filters;
  int _selectedFilterIndex = 0;
  double _brightness = 0.0;
  double _contrast = 1.0;
  bool _saving = false;
  img.Image? _original;
  Uint8List? _previewBytes;
  List<Uint8List?> _thumbBytes = [];
  int _previewJob = 0;

  @override
  void initState() {
    super.initState();
    _filters = [
      _FilterOption(
        name: 'original',
        label: 'Original',
        apply: (src) => img.Image.from(src),
      ),
      _FilterOption(
        name: 'vibrant',
        label: 'Vibrant',
        apply: (src) => img.adjustColor(
          img.Image.from(src),
          saturation: 1.8,
          contrast: 1.3,
        ),
      ),
      _FilterOption(
        name: 'softTone',
        label: 'Soft Tone',
        apply: (src) => img.adjustColor(
          img.Image.from(src),
          brightness: 0.15,
          saturation: 0.7,
          contrast: 0.9,
        ),
      ),
      _FilterOption(
        name: 'ocvColor',
        label: 'OCV Color',
        apply: (src) => img.adjustColor(
          img.Image.from(src),
          saturation: 1.2,
          contrast: 1.15,
          hue: 5,
        ),
      ),
      _FilterOption(
        name: 'bw',
        label: 'B&W',
        apply: (src) => img.grayscale(img.Image.from(src)),
      ),
      _FilterOption(
        name: 'carbonBlack',
        label: 'Carbon Black',
        apply: (src) {
          final g = img.grayscale(img.Image.from(src));
          return img.adjustColor(g, contrast: 1.6, brightness: -0.2);
        },
      ),
      _FilterOption(
        name: 'colorPop',
        label: 'Color Pop',
        apply: (src) => img.adjustColor(
          img.Image.from(src),
          saturation: 2.0,
          contrast: 1.2,
        ),
      ),
      _FilterOption(
        name: 'sepia',
        label: 'Sepia',
        apply: (src) => img.sepia(img.Image.from(src)),
      ),
    ];
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded != null && mounted) {
      setState(() {
        _original = decoded;
        _thumbBytes = List<Uint8List?>.filled(_filters.length, null);
      });
      _updatePreview();
      _updateThumbnails();
    }
  }

  Future<void> _updatePreview() async {
    if (_original == null) return;
    final job = ++_previewJob;
    try {
      var filtered = _filters[_selectedFilterIndex].apply(_original!);
      if (_brightness != 0.0 || _contrast != 1.0) {
        filtered = img.adjustColor(
          filtered,
          brightness: _brightness,
          contrast: _contrast,
        );
      }
      final bytes = img.encodeJpg(filtered, quality: 90);
      if (mounted && job == _previewJob) {
        setState(() => _previewBytes = bytes);
      }
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }

  Future<void> _updateThumbnails() async {
    if (_original == null) return;
    try {
      final smallBase = img.copyResize(_original!, width: 140);
      final next = List<Uint8List?>.filled(_filters.length, null);
      for (var i = 0; i < _filters.length; i++) {
        var filtered = _filters[i].apply(smallBase);
        if (_brightness != 0.0 || _contrast != 1.0) {
          filtered = img.adjustColor(
            filtered,
            brightness: _brightness,
            contrast: _contrast,
          );
        }
        next[i] = img.encodeJpg(filtered, quality: 70);
      }
      if (mounted) setState(() => _thumbBytes = next);
    } catch (e) {
      debugPrint('Thumbnail preview error: $e');
    }
  }

  Future<void> _apply() async {
    if (_original == null) return;
    setState(() => _saving = true);
    try {
      var filtered = _filters[_selectedFilterIndex].apply(_original!);
      if (_brightness != 0.0 || _contrast != 1.0) {
        filtered = img.adjustColor(
          filtered,
          brightness: _brightness,
          contrast: _contrast,
        );
      }
      final outBytes = img.encodeJpg(filtered, quality: 95);
      final path = await EditorUtils.writeToTemp(outBytes, 'jpg');
      if (mounted) Navigator.pop(context, path);
    } catch (e) {
      debugPrint('Apply error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
          // Real-time preview with adjustment bars above image
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _original == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _previewBytes == null
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : Image.memory(
                              _previewBytes!,
                              fit: BoxFit.contain,
                            ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 78,
                            child: Text(
                              'Brightness',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _brightness,
                              min: -1.0,
                              max: 1.0,
                              activeColor: Colors.blueAccent,
                              onChanged: (v) {
                                setState(() => _brightness = v);
                                _updatePreview();
                                _updateThumbnails();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              _brightness.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 78,
                            child: Text(
                              'Contrast',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _contrast,
                              min: 0.0,
                              max: 2.0,
                              activeColor: Colors.blueAccent,
                              onChanged: (v) {
                                setState(() => _contrast = v);
                                _updatePreview();
                                _updateThumbnails();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              _contrast.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),



          // Preview strip: icon at top and label below
          Container(
            color: EditorUtils.editorBackground,
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final isSelected = _selectedFilterIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilterIndex = i);
                        _updatePreview();
                      },
                      child: SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blueAccent
                                          : Colors.white24,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: _thumbBytes.length > i && _thumbBytes[i] != null
                                        ? Image.memory(
                                            _thumbBytes[i]!,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.image_outlined,
                                            color: Colors.white70,
                                            size: 24,
                                          ),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    right: -6,
                                    top: -6,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.blueAccent,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                              const SizedBox(height: 4),
                            Text(
                              _filters[i].label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[300],
                                  fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),


        ],
      ),
    );
  }
}
