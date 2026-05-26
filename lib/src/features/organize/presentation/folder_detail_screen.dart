import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/models/document.dart';
import '../../../core/models/document_page.dart';
import '../../../core/models/folder.dart';
import '../../../core/state/chitra_session.dart';
import '../../scanner/presentation/in_app_camera_screen.dart';
import 'image_viewer_screen.dart';

/// Displays all documents in a folder as a 2-column grid with sequential labels.
class FolderDetailScreen extends StatefulWidget {
  const FolderDetailScreen({required this.folder, super.key});

  final ChitraFolder folder;

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final _session = ChitraSession.instance;

  Future<void> _pickFilesIntoFolder() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.isEmpty) return;

    var added = 0;
    for (final f in result.files) {
      final path = f.path;
      if (path == null || path.isEmpty) continue;

      final now = DateTime.now();
      final cleanName = (f.name.isNotEmpty ? f.name : 'Image_${now.millisecondsSinceEpoch}')
          .replaceAll(RegExp(r'\.[^.]+$'), '');
      final doc = ChitraDocument(
        id: now.microsecondsSinceEpoch.toString(),
        name: cleanName,
        folderId: widget.folder.id,
        pages: [
          DocumentPage(
            id: '${now.microsecondsSinceEpoch}_0',
            sourcePath: path,
          ),
        ],
        createdAt: now,
      );
      _session.saveDocument(doc);
      added++;
    }

    if (!mounted || added == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$added image(s) added to ${widget.folder.name}.')),
    );
  }

  Future<void> _openCameraInThisFolder() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => InAppCameraScreen(initialFolderId: widget.folder.id),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        final docs = _session.documentsInFolder(widget.folder.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.folder.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('No documents in this folder'),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final firstPath =
                        doc.pages.isNotEmpty ? doc.pages.first.sourcePath : null;
                    final hasFile =
                        firstPath != null && File(firstPath).existsSync();

                    return GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ImageViewerScreen(
                              document: doc,
                              initialPageIndex: 0,
                              folder: widget.folder,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: hasFile
                                ? Image.file(
                                    File(firstPath),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                    child: Icon(
                                      Icons.insert_drive_file_outlined,
                                      size: 48,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(180),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                doc.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'folder_fab_pick_file',
                tooltip: 'Pick File',
                onPressed: _pickFilesIntoFolder,
                child: const Icon(Icons.attach_file),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(
                heroTag: 'folder_fab_camera',
                tooltip: 'Open Camera',
                onPressed: _openCameraInThisFolder,
                child: const Icon(Icons.camera_alt),
              ),
            ],
          ),
        );
      },
    );
  }
}
