import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/services/image_processor_service.dart';

class ImageEnhancementScreen extends StatefulWidget {
  const ImageEnhancementScreen({
    required this.imagePath,
    super.key,
  });

  final String imagePath;

  @override
  State<ImageEnhancementScreen> createState() => _ImageEnhancementScreenState();
}

class _ImageEnhancementScreenState extends State<ImageEnhancementScreen> {
  late String _currentImagePath;
  double _contrast = 1.0;
  double _brightness = 0.0;
  int _blackAndWhiteThreshold = 127;
  bool _isProcessing = false;
  String _selectedFilter = 'original';

  final List<String> _filters = [
    'original',
    'grayscale',
    'blackwhite',
    'enhanced',
    'edges',
  ];

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<void> _applyFilter(String filter) async {
    setState(() => _isProcessing = true);

    try {
      late String newPath;

      switch (filter) {
        case 'grayscale':
          final bytes = await ImageProcessorService.toGrayscale(_currentImagePath);
          newPath = await _saveTempImage(bytes);
          break;
        case 'blackwhite':
          final bytes = await ImageProcessorService.applyBlackAndWhite(
            _currentImagePath,
            threshold: _blackAndWhiteThreshold,
          );
          newPath = await _saveTempImage(bytes);
          break;
        case 'enhanced':
          final bytes = await ImageProcessorService.enhance(
            _currentImagePath,
            contrast: _contrast,
            brightness: _brightness,
          );
          newPath = await _saveTempImage(bytes);
          break;
        case 'edges':
          final bytes = await ImageProcessorService.detectEdges(_currentImagePath);
          newPath = await _saveTempImage(bytes);
          break;
        case 'original':
        default:
          newPath = widget.imagePath;
      }

      setState(() {
        _currentImagePath = newPath;
        _selectedFilter = filter;
      });
    } catch (e) {
      _showMessage('Error applying filter: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String> _saveTempImage(List<int> imageBytes) async {
    final tempDir = Directory.systemTemp;
    final fileName =
        'chitra_temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  Future<void> _autoCrop() async {
    setState(() => _isProcessing = true);

    try {
      final bytes = await ImageProcessorService.autoCrop(_currentImagePath);
      final newPath = await _saveTempImage(bytes);
      setState(() => _currentImagePath = newPath);
      _showMessage('Auto-crop applied');
    } catch (e) {
      _showMessage('Error applying auto-crop: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _autoStraighten() async {
    setState(() => _isProcessing = true);

    try {
      final bytes =
          await ImageProcessorService.autoStraighten(_currentImagePath);
      final newPath = await _saveTempImage(bytes);
      setState(() => _currentImagePath = newPath);
      _showMessage('Auto-straighten applied');
    } catch (e) {
      _showMessage('Error applying auto-straighten: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rotateImage(double degrees) async {
    setState(() => _isProcessing = true);

    try {
      final bytes = await ImageProcessorService.rotate(_currentImagePath, degrees);
      final newPath = await _saveTempImage(bytes);
      setState(() => _currentImagePath = newPath);
    } catch (e) {
      _showMessage('Error rotating image: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _saveAndClose() {
    Navigator.pop(context, _currentImagePath);
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhance Image'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _saveAndClose,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Preview
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    File(_currentImagePath),
                    fit: BoxFit.contain,
                    height: 300,
                  ),
                ),

                // Filter chips
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final filter in _filters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(filter),
                            selected: _selectedFilter == filter,
                            onSelected: (_) => _applyFilter(filter),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Rotation controls
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rotation & Alignment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.rotate_left),
                              onPressed: () => _rotateImage(-90),
                              tooltip: 'Rotate left',
                            ),
                            IconButton(
                              icon: const Icon(Icons.crop),
                              onPressed: _autoCrop,
                              tooltip: 'Auto crop',
                            ),
                            IconButton(
                              icon: const Icon(Icons.straighten),
                              onPressed: _autoStraighten,
                              tooltip: 'Auto straighten',
                            ),
                            IconButton(
                              icon: const Icon(Icons.rotate_right),
                              onPressed: () => _rotateImage(90),
                              tooltip: 'Rotate right',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Contrast adjustment
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Contrast'),
                            Text('${_contrast.toStringAsFixed(1)}x'),
                          ],
                        ),
                        Slider(
                          value: _contrast,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          onChanged: (value) {
                            setState(() => _contrast = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Brightness adjustment
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Brightness'),
                            Text('${_brightness.toStringAsFixed(1)}'),
                          ],
                        ),
                        Slider(
                          value: _brightness,
                          min: -50,
                          max: 50,
                          divisions: 100,
                          onChanged: (value) {
                            setState(() => _brightness = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Black & White threshold
                if (_selectedFilter == 'blackwhite')
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('B&W Threshold'),
                              Text(_blackAndWhiteThreshold.toString()),
                            ],
                          ),
                          Slider(
                            value: _blackAndWhiteThreshold.toDouble(),
                            min: 0,
                            max: 255,
                            divisions: 255,
                            onChanged: (value) {
                              setState(
                                () =>
                                    _blackAndWhiteThreshold = value.toInt(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : _cancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _saveAndClose,
                        child: const Text('Save & Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
