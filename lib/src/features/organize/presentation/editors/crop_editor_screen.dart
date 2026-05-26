import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'editor_utils.dart';

/// Crop editor with draggable corner handles (TL, TR, BR, BL).
/// Returns the cropped image path or null if cancelled.
class CropEditorScreen extends StatefulWidget {
  const CropEditorScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<CropEditorScreen> createState() => _CropEditorScreenState();
}

class _CropEditorScreenState extends State<CropEditorScreen> {
  // Normalized (0..1) corner points: TL, TR, BR, BL
  List<Offset> _corners = const [
    Offset(0.10, 0.10),
    Offset(0.90, 0.10),
    Offset(0.90, 0.90),
    Offset(0.10, 0.90),
  ];
  bool _saving = false;

  void _moveCorner(int i, Offset delta, Size size) {
    setState(() {
      final c = _corners[i];
      _corners = List<Offset>.from(_corners)
        ..[i] = Offset(
          (c.dx + delta.dx / size.width).clamp(0.02, 0.98),
          (c.dy + delta.dy / size.height).clamp(0.02, 0.98),
        );
    });
  }

  Future<void> _applyCrop() async {
    setState(() => _saving = true);
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return;

      final xs = _corners.map((p) => p.dx);
      final ys = _corners.map((p) => p.dy);
      final x = (xs.reduce((a, b) => a < b ? a : b) * src.width).round().clamp(0, src.width - 1);
      final y = (ys.reduce((a, b) => a < b ? a : b) * src.height).round().clamp(0, src.height - 1);
      final w = ((xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b)) * src.width).round().clamp(1, src.width - x);
      final h = ((ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b)) * src.height).round().clamp(1, src.height - y);

      final cropped = img.copyCrop(src, x: x, y: y, width: w, height: h);
      final outBytes = img.encodeJpg(cropped, quality: 95);
      final path = await EditorUtils.writeToTemp(outBytes, 'jpg');
      if (mounted) Navigator.pop(context, path);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const handleR = 14.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _applyCrop,
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
      body: LayoutBuilder(builder: (_, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        Offset toPx(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

        return Stack(
          children: [
            Positioned.fill(
              child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CropPainter(_corners.map(toPx).toList()),
              ),
            ),
            for (var i = 0; i < _corners.length; i++)
              Positioned(
                left: toPx(_corners[i]).dx - handleR,
                top: toPx(_corners[i]).dy - handleR,
                child: GestureDetector(
                  onPanUpdate: (d) => _moveCorner(i, d.delta, size),
                  child: Container(
                    width: handleR * 2,
                    height: handleR * 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyan, width: 3),
                      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.pts);
  final List<Offset> pts;

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length != 4) return;
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..lineTo(pts[3].dx, pts[3].dy)
      ..close();
    final full = Path()..addRect(Offset.zero & size);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, path),
      Paint()..color = Colors.black.withAlpha(120),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.pts != pts;
}
