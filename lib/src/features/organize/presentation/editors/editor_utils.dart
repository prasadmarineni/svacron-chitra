import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/storage/app_storage.dart';

/// Shared utilities for all image editors.
abstract final class EditorUtils {
  /// Captures a [RepaintBoundary] identified by [key] and saves the result
  /// as a PNG to the persistent images folder. Returns the new file path.
  static Future<String> captureBoundary(
    GlobalKey key, {
    double pixelRatio = 2.5,
  }) async {
    final renderObject = key.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return writeToTemp(bytes, 'png');
  }

  /// Writes [bytes] to a new persistent image file with [ext] extension.
  static Future<String> writeToTemp(Uint8List bytes, String ext) async {
    final path = AppStorage.newImagePath(ext: ext);
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
