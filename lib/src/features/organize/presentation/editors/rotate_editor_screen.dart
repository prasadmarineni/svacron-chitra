import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'editor_utils.dart';

/// Rotate / flip editor. Returns the new image path or null.
class RotateEditorScreen extends StatefulWidget {
  const RotateEditorScreen({required this.imagePath, super.key});
  final String imagePath;

  @override
  State<RotateEditorScreen> createState() => _RotateEditorScreenState();
}

class _RotateEditorScreenState extends State<RotateEditorScreen> {
  /// Cumulative rotation in degrees (multiples of 90).
  int _rotation = 0;
  bool _flipH = false;
  bool _flipV = false;
  bool _saving = false;

  void _rotate(int deg) => setState(() => _rotation = (_rotation + deg) % 360);
  void _toggleFlipH() => setState(() => _flipH = !_flipH);
  void _toggleFlipV() => setState(() => _flipV = !_flipV);

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) return;

      if (_rotation != 0) {
        image = img.copyRotate(image, angle: _rotation.toDouble());
      }
      if (_flipH) image = img.flipHorizontal(image);
      if (_flipV) image = img.flipVertical(image);

      final out = img.encodeJpg(image, quality: 95);
      final path = await EditorUtils.writeToTemp(out, 'jpg');
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
        title: const Text('Rotate & Flip'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _apply,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Apply', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(_rotation * 3.14159265 / 180)
                  ..scale(_flipH ? -1.0 : 1.0, _flipV ? -1.0 : 1.0),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ToolBtn(
                    icon: Icons.rotate_left,
                    label: '90° CCW',
                    onTap: () => _rotate(-90),
                  ),
                  _ToolBtn(
                    icon: Icons.rotate_right,
                    label: '90° CW',
                    onTap: () => _rotate(90),
                  ),
                  _ToolBtn(
                    icon: Icons.flip,
                    label: 'Flip H',
                    active: _flipH,
                    onTap: _toggleFlipH,
                  ),
                  _ToolBtn(
                    icon: Icons.flip,
                    label: 'Flip V',
                    active: _flipV,
                    onTap: _toggleFlipV,
                    rotate90: true,
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

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.rotate90 = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool rotate90;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.cyan : Colors.grey.shade400;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? Colors.cyan.withAlpha(30) : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: RotatedBox(
              quarterTurns: rotate90 ? 1 : 0,
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
