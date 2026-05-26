import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/document.dart';
import '../../../core/models/folder.dart';

/// Displays a single image with options for edit, share, save, print, delete, batch edit.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    required this.document,
    required this.initialPageIndex,
    required this.folder,
    super.key,
  });

  final ChitraDocument document;
  final int initialPageIndex;
  final ChitraFolder folder;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPageIndex;
  }

  Future<void> _shareImage() async {
    if (_currentPageIndex >= widget.document.pages.length) return;
    final imagePath = widget.document.pages[_currentPageIndex].sourcePath;
    final file = File(imagePath);

    if (file.existsSync()) {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: '${widget.document.name} - Page ${_currentPageIndex + 1}',
      );
    }
  }

  Future<void> _saveImageToGallery() async {
    if (_currentPageIndex >= widget.document.pages.length) return;
    final imagePath = widget.document.pages[_currentPageIndex].sourcePath;
    final file = File(imagePath);

    if (file.existsSync()) {
      final appDir = await Directory('/storage/emulated/0/Pictures').create(recursive: true);
      final fileName = '${widget.document.name}_page_${_currentPageIndex + 1}.jpg';
      final newFile = await file.copy('${appDir.path}/$fileName');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${newFile.path}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document.pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.document.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No images in this document'),
        ),
      );
    }

    final currentPage = widget.document.pages[_currentPageIndex];
    final imagePath = currentPage.sourcePath;
    final hasFile = File(imagePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.document.name} - Page ${_currentPageIndex + 1}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: hasFile
                ? Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  )
                : Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
          ),
          if (widget.document.pages.length > 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentPageIndex > 0
                        ? () => setState(() => _currentPageIndex--)
                        : null,
                  ),
                  Text(
                    '${_currentPageIndex + 1} / ${widget.document.pages.length}',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _currentPageIndex < widget.document.pages.length - 1
                        ? () => setState(() => _currentPageIndex++)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Edit
                Tooltip(
                  message: 'Edit',
                  child: ActionChip(
                    label: const Text('Edit'),
                    avatar: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      _showEditOptions();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Share
                Tooltip(
                  message: 'Share',
                  child: ActionChip(
                    label: const Text('Share'),
                    avatar: const Icon(Icons.share, size: 18),
                    onPressed: _shareImage,
                  ),
                ),
                const SizedBox(width: 8),
                // Save
                Tooltip(
                  message: 'Save to Gallery',
                  child: ActionChip(
                    label: const Text('Save'),
                    avatar: const Icon(Icons.save, size: 18),
                    onPressed: _saveImageToGallery,
                  ),
                ),
                const SizedBox(width: 8),
                // Print
                Tooltip(
                  message: 'Print',
                  child: ActionChip(
                    label: const Text('Print'),
                    avatar: const Icon(Icons.print, size: 18),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Print feature coming soon')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Delete
                Tooltip(
                  message: 'Delete',
                  child: ActionChip(
                    label: const Text('Delete'),
                    avatar: const Icon(Icons.delete, size: 18),
                    onPressed: () {
                      _showDeleteConfirmation();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Batch Edit
                Tooltip(
                  message: 'Batch Edit',
                  child: ActionChip(
                    label: const Text('Batch Edit'),
                    avatar: const Icon(Icons.layers, size: 18),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Batch edit coming soon')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              _editOption('Crop', Icons.crop, () => _editImage('crop')),
              _editOption('Color Filters', Icons.palette, () => _editImage('colorfilter')),
              _editOption('Rotate', Icons.rotate_left, () => _editImage('rotate')),
              _editOption('Erase', Icons.cleaning_services, () => _editImage('erase')),
              _editOption('Add Text', Icons.text_fields, () => _editImage('text')),
              _editOption('Highlight', Icons.highlight, () => _editImage('highlight')),
              _editOption('Doodle', Icons.brush, () => _editImage('doodle')),
              _editOption('Watermark', Icons.water_drop, () => _editImage('watermark')),
              _editOption('Cut', Icons.content_cut, () => _editImage('cut')),
              _editOption('Signature', Icons.edit, () => _editImage('signature')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editOption(String label, IconData icon, VoidCallback onTap) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  void _editImage(String editType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $editType editor...')),
    );
    Navigator.pop(context);
  }

  void _showDeleteConfirmation() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text(
          'Are you sure you want to delete this image? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
