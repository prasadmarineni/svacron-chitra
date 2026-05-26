import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/document.dart';
import '../models/document_page.dart';
import '../models/folder.dart';
import '../storage/app_storage.dart';

class ChitraSession extends ChangeNotifier {
  ChitraSession._();

  static final ChitraSession instance = ChitraSession._();

  // ── scan / pdf / ocr ──────────────────────────────────────────────────────
  final List<String> _imagePaths = [];
  String? _activePdfPath;
  String _ocrText = '';

  List<String> get imagePaths => List.unmodifiable(_imagePaths);
  String? get activePdfPath => _activePdfPath;
  String get ocrText => _ocrText;

  void addImagePath(String path) {
    _imagePaths.add(path);
    notifyListeners();
  }

  void addImagePaths(List<String> paths) {
    _imagePaths.addAll(paths);
    notifyListeners();
  }

  void removeImagePath(String path) {
    _imagePaths.remove(path);
    notifyListeners();
  }

  void clearImages() {
    _imagePaths.clear();
    notifyListeners();
  }

  void setActivePdfPath(String? path) {
    _activePdfPath = path;
    notifyListeners();
  }

  void setOcrText(String text) {
    _ocrText = text;
    notifyListeners();
  }

  // ── documents ─────────────────────────────────────────────────────────────
  final List<ChitraDocument> _documents = [];
  final List<String> _trashedDocIds = [];

  List<ChitraDocument> get documents => List.unmodifiable(
    _documents.where((d) => !_trashedDocIds.contains(d.id)),
  );

  List<ChitraDocument> get trashedDocuments =>
      List.unmodifiable(_documents.where((d) => _trashedDocIds.contains(d.id)));

  List<ChitraDocument> get favoriteDocuments =>
      documents.where((d) => d.isFavorite).toList();

  List<ChitraDocument> get recentDocuments {
    final sorted = [...documents]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(10).toList();
  }

  List<ChitraDocument> documentsInFolder(String folderId) =>
      documents.where((d) => d.folderId == folderId).toList();

  void saveDocument(ChitraDocument doc) {
    final idx = _documents.indexWhere((d) => d.id == doc.id);
    if (idx >= 0) {
      _documents[idx] = doc;
    } else {
      _documents.add(doc);
    }
    notifyListeners();
    _markDirty();
  }

  /// Creates a new document from the current imagePaths batch.
  /// Auto-creates a dated folder (dd-MM-yyyy-HHmm format).
  /// Returns the saved document.
  ChitraDocument createDocumentFromBatch({
    required String name,
    String? folderId,
  }) {
    // Auto-create folder with dd-MM-yyyy-HHmm format if folderId not provided
    late String targetFolderId;
    if (folderId == null) {
      final now = DateTime.now();
      final folderName =
          '${now.day.toString().padLeft(2, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.year}-'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}';

      targetFolderId = DateTime.now().microsecondsSinceEpoch.toString();
      _folders.add(ChitraFolder(id: targetFolderId, name: folderName));
    } else {
      targetFolderId = folderId;
    }

    final doc = ChitraDocument(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      folderId: targetFolderId,
      pages: List.generate(
        _imagePaths.length,
        (i) => DocumentPage(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          sourcePath: _imagePaths[i],
        ),
      ),
      createdAt: DateTime.now(),
    );
    _documents.add(doc);
    _imagePaths.clear();
    notifyListeners();
    _markDirty();
    return doc;
  }

  void toggleFavorite(String docId) {
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx < 0) return;
    _documents[idx] = _documents[idx].copyWith(
      isFavorite: !_documents[idx].isFavorite,
    );
    notifyListeners();
    _markDirty();
  }

  void renameDocument(String docId, String newName) {
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx < 0) return;
    _documents[idx] = _documents[idx].copyWith(name: newName);
    notifyListeners();
    _markDirty();
  }

  void moveDocumentToFolder(String docId, String folderId) {
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx < 0) return;
    _documents[idx] = _documents[idx].copyWith(folderId: folderId);
    notifyListeners();
    _markDirty();
  }

  void moveToTrash(String docId) {
    if (!_trashedDocIds.contains(docId)) {
      _trashedDocIds.add(docId);
      notifyListeners();
      _markDirty();
    }
  }

  void restoreFromTrash(String docId) {
    _trashedDocIds.remove(docId);
    notifyListeners();
    _markDirty();
  }

  void deleteForever(String docId) {
    _trashedDocIds.remove(docId);
    _documents.removeWhere((d) => d.id == docId);
    notifyListeners();
    _markDirty();
  }

  void emptyTrash() {
    _documents.removeWhere((d) => _trashedDocIds.contains(d.id));
    _trashedDocIds.clear();
    notifyListeners();
    _markDirty();
  }

  // ── folders ───────────────────────────────────────────────────────────────
  final List<ChitraFolder> _folders = [];

  List<ChitraFolder> get folders => List.unmodifiable(_folders);

  void createFolder(String name) {
    _folders.add(
      ChitraFolder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
      ),
    );
    notifyListeners();
    _markDirty();
  }

  void deleteFolder(String folderId) {
    // Move orphaned docs to default
    for (var i = 0; i < _documents.length; i++) {
      if (_documents[i].folderId == folderId) {
        _documents[i] = _documents[i].copyWith(folderId: 'default');
      }
    }
    _folders.removeWhere((f) => f.id == folderId);
    notifyListeners();
    _markDirty();
  }

  void renameFolder(String folderId, String newName) {
    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx < 0) return;
    _folders[idx] = ChitraFolder(
      id: _folders[idx].id,
      name: newName,
      isLocked: _folders[idx].isLocked,
      isHidden: _folders[idx].isHidden,
    );
    notifyListeners();
    _markDirty();
  }

  // ── labels / tags ─────────────────────────────────────────────────────────
  final Set<String> _allLabels = {'Invoice', 'Receipt', 'Contract', 'Report'};

  Set<String> get allLabels => Set.unmodifiable(_allLabels);

  void addLabel(String label) {
    _allLabels.add(label);
    notifyListeners();
    _markDirty();
  }

  void addLabelToDocument(String docId, String label) {
    _allLabels.add(label);
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx < 0) return;
    final existing = _documents[idx].labels;
    if (existing.contains(label)) return;
    _documents[idx] = _documents[idx].copyWith(labels: [...existing, label]);
    notifyListeners();
    _markDirty();
  }

  void removeLabelFromDocument(String docId, String label) {
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx < 0) return;
    _documents[idx] = _documents[idx].copyWith(
      labels: _documents[idx].labels.where((l) => l != label).toList(),
    );
    notifyListeners();
    _markDirty();
  }

  // ── search ────────────────────────────────────────────────────────────────
  List<ChitraDocument> searchDocuments(String query) {
    final q = query.toLowerCase();
    return documents
        .where(
          (d) =>
              d.name.toLowerCase().contains(q) ||
              (d.ocrText?.toLowerCase().contains(q) ?? false) ||
              d.labels.any((l) => l.toLowerCase().contains(q)),
        )
        .toList();
  }

  // ── persistence ───────────────────────────────────────────────────────────
  bool _persistenceDirty = false;

  /// Loads data from [AppStorage.metadataFile].
  /// Call once at app startup after [AppStorage.init].
  Future<void> loadFromDisk() async {
    final file = AppStorage.metadataFile;
    if (!file.existsSync()) return;
    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final folders = (json['folders'] as List<dynamic>? ?? [])
          .map((f) => ChitraFolder.fromJson(f as Map<String, dynamic>))
          .toList();
      final docs = (json['documents'] as List<dynamic>? ?? [])
          .map((d) => ChitraDocument.fromJson(d as Map<String, dynamic>))
          .where((d) {
            // Remove documents whose image files have all been deleted.
            return d.pages.any((p) => File(p.sourcePath).existsSync());
          })
          .toList();

      _folders
        ..clear()
        ..addAll(folders);
      _documents
        ..clear()
        ..addAll(docs);
      notifyListeners();
      debugPrint('[ChitraSession] loaded ${_documents.length} docs, '
          '${_folders.length} folders from disk.');
    } catch (e) {
      debugPrint('[ChitraSession] failed to load from disk: $e');
    }
  }

  /// Writes current state to [AppStorage.metadataFile].
  Future<void> saveToDisk() async {
    try {
      final payload = jsonEncode({
        'version': 1,
        'folders': _folders.map((f) => f.toJson()).toList(),
        'documents': _documents.map((d) => d.toJson()).toList(),
      });
      await AppStorage.metadataFile.writeAsString(payload);
      _persistenceDirty = false;
    } catch (e) {
      debugPrint('[ChitraSession] failed to save to disk: $e');
    }
  }

  /// Marks session dirty and schedules a save.
  void _markDirty() {
    if (_persistenceDirty) return;
    _persistenceDirty = true;
    Future.microtask(saveToDisk);
  }
}
