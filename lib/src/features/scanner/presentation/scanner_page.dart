import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/state/chitra_session.dart';
import 'camera_capture_screen.dart';
import 'image_enhancement_screen.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final _picker = ImagePicker();
  final _session = ChitraSession.instance;

  Future<bool> _ensureGalleryPermission() async {
    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  Future<void> _captureFromCamera() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CameraCaptureScreen(),
      ),
    );
  }

  Future<void> _importFromGallery() async {
    final granted = await _ensureGalleryPermission();
    if (!granted) {
      _showMessage('Photo access is required to import images.');
      return;
    }

    final files = await _picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }

    // Process imported images
    for (final file in files) {
      final enhanced = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => ImageEnhancementScreen(imagePath: file.path),
        ),
      );
      if (enhanced != null) {
        _session.addImagePath(enhanced);
      }
    }
    setState(() {});
  }

  void _clearDraft() {
    setState(_session.clearImages);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _enhanceImage(String imagePath, int index) async {
    final enhanced = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ImageEnhancementScreen(imagePath: imagePath),
      ),
    );

    if (enhanced != null && enhanced != imagePath) {
      setState(() {
        _session.removeImagePath(imagePath);
        _session.addImagePath(enhanced);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      'Capture with auto edge detection',
      'Adjust corners manually if needed',
      'Auto crop, straighten and rotate',
      'Apply enhancement and filter',
      'Save as multi-page draft or export PDF',
    ];

    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanner Workspace',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Continuous capture mode with batch scanning, blur warning, and smart auto enhancement.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _captureFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Open Camera'),
                      ),
                      FilledButton.icon(
                        onPressed: _importFromGallery,
                        icon: const Icon(Icons.collections),
                        label: const Text('From Gallery'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _session.imagePaths.isEmpty
                            ? null
                            : _clearDraft,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear Draft'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Batch',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${_session.imagePaths.length} page(s) selected'),
                  const SizedBox(height: 10),
                  if (_session.imagePaths.isEmpty)
                    const Text(
                      'No images captured yet. Start from camera or gallery.',
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _session.imagePaths.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final imagePath = _session.imagePaths[index];
                          return GestureDetector(
                            onLongPress: () => _enhanceImage(imagePath, index),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                        ),
                                      ),
                                      child: const Text(
                                        'P',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: PopupMenuButton<String>(
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'enhance',
                                          child: Row(
                                            children: [
                                              Icon(Icons.tune),
                                              SizedBox(width: 8),
                                              Text('Enhance'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'enhance') {
                                          _enhanceImage(imagePath, index);
                                        } else if (value == 'delete') {
                                          setState(() =>
                                              _session.removeImagePath(imagePath));
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture Flow',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < steps.length; i++)
                    ListTile(
                      leading: CircleAvatar(
                        radius: 12,
                        child: Text('${i + 1}'),
                      ),
                      title: Text(steps[i]),
                      dense: true,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
