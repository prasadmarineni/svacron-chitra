import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages the persistent base storage folder for all app data.
///
/// Priority:
///   Android → /storage/emulated/0/Download/SvachronChitra/  (survives reinstall)
///   iOS     → <AppDocuments>/SvachronChitra/
///   Fallback → <AppDocuments>/SvachronChitra/
///
/// Call [AppStorage.init] once at app startup before using any other method.
class AppStorage {
  AppStorage._();

  static const String _folderName = 'SvachronChitra';

  static late Directory _baseDir;

  /// Absolute path that is set after [init] completes.
  static String get basePath => _baseDir.path;

  // ── sub-folders ────────────────────────────────────────────────────────────
  /// Where captured / edited images are stored.
  static Directory get imagesDir =>
      Directory('${_baseDir.path}/images')..createSync(recursive: true);

  /// Metadata JSON file.
  static File get metadataFile => File('${_baseDir.path}/data.json');

  // ── initialization ─────────────────────────────────────────────────────────
  /// Must be awaited before the app renders.
  static Future<void> init() async {
    _baseDir = await _resolveBaseDir();
    await _baseDir.create(recursive: true);
    debugPrint('[AppStorage] base dir: ${_baseDir.path}');
  }

  static Future<Directory> _resolveBaseDir() async {
    if (Platform.isAndroid) {
      // Try to use public Downloads folder (survives app uninstall).
      final hasPermission = await _requestStoragePermission();
      if (hasPermission) {
        final dl = Directory('/storage/emulated/0/Download/$_folderName');
        return dl;
      }
    }

    // iOS or fallback: app documents directory (survives reinstall on iOS via
    // iCloud backup; on Android at least survives restarts).
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/$_folderName');
  }

  static Future<bool> _requestStoragePermission() async {
    // Android 13+ uses granular READ_MEDIA_IMAGES instead of storage.
    if (await Permission.manageExternalStorage.isGranted) return true;

    // Request MANAGE_EXTERNAL_STORAGE for Android 11+ (API 30+).
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;

    // Fallback for Android ≤ 10: legacy WRITE_EXTERNAL_STORAGE.
    final legacyStatus = await Permission.storage.request();
    return legacyStatus.isGranted;
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  /// Creates a unique image file path inside [imagesDir].
  static String newImagePath({String ext = 'jpg'}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${imagesDir.path}/img_$ts.$ext';
  }

  /// Copies [srcPath] into [imagesDir] if it is not already inside the base
  /// dir. Returns the final path.
  static Future<String> ensureInImagesDir(String srcPath) async {
    if (srcPath.startsWith(_baseDir.path)) return srcPath;
    final dest = newImagePath(ext: srcPath.split('.').last);
    await File(srcPath).copy(dest);
    return dest;
  }
}
