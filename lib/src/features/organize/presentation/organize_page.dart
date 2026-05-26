import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/document.dart';
import '../../../core/models/folder.dart';
import '../../../core/state/chitra_session.dart';
import '../../scanner/presentation/camera_capture_screen.dart';

// ── sort options ─────────────────────────────────────────────────────────────
enum _SortBy { name, date, size }

class OrganizePage extends StatefulWidget {
  const OrganizePage({super.key});

  @override
  State<OrganizePage> createState() => _OrganizePageState();
}

class _OrganizePageState extends State<OrganizePage> {
  final _session = ChitraSession.instance;
  _SortBy _sortBy = _SortBy.date;
  String? _activeFolderId; // null = show all
  String _searchQuery = '';

  // ── helpers ──────────────────────────────────────────────────────────────
  List<ChitraDocument> _sortedDocs(List<ChitraDocument> docs) {
    final list = [...docs];
    switch (_sortBy) {
      case _SortBy.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortBy.date:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortBy.size:
        list.sort((a, b) => b.pages.length.compareTo(a.pages.length));
    }
    return list;
  }

  List<ChitraDocument> _filtered(List<ChitraDocument> docs) {
    if (_searchQuery.isEmpty) return docs;
    return docs
        .where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── dialogs ───────────────────────────────────────────────────────────────
  Future<void> _showCreateFolderDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      _session.createFolder(name);
    }
  }

  Future<void> _showRenameFolderDialog(ChitraFolder folder) async {
    final ctrl = TextEditingController(text: folder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      _session.renameFolder(folder.id, name);
    }
  }

  Future<void> _showRenameDocDialog(ChitraDocument doc) async {
    final ctrl = TextEditingController(text: doc.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      _session.renameDocument(doc.id, name);
    }
  }

  Future<void> _showMoveToFolderDialog(ChitraDocument doc) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Folder'),
        content: SizedBox(
          width: 280,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final f in _session.folders)
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(f.name),
                  selected: f.id == doc.folderId,
                  onTap: () => Navigator.pop(ctx, f.id),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (chosen != null && chosen != doc.folderId) {
      _session.moveDocumentToFolder(doc.id, chosen);
    }
  }

  // ── camera & file pick ───────────────────────────────────────────────────
  Future<void> _openCamera() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CameraCaptureScreen(),
      ),
    );
  }

  Future<void> _pickFileOrImage() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add to Library',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.blue),
              ),
              title: const Text('Pick Image'),
              subtitle: const Text('Add a photo or scanned image'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final picked =
                    await picker.pickImage(source: ImageSource.gallery);
                if (picked != null && mounted) {
                  _session.addImagePath(picked.path);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Image added. Tap the banner above to save.')),
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
              ),
              title: const Text('Pick PDF'),
              subtitle: const Text('Import a PDF document'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null &&
                    result.files.single.path != null &&
                    mounted) {
                  final name =
                      result.files.single.name.replaceAll('.pdf', '');
                  _session.createDocumentFromBatch(
                    name: name,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF "$name" imported.')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return Scaffold(
          body: _FoldersTab(
            session: _session,
            sortBy: _sortBy,
            onSortChanged: (v) => setState(() => _sortBy = v),
            searchQuery: _searchQuery,
            activeFolderId: _activeFolderId,
            onFolderSelected: (id) =>
                setState(() => _activeFolderId = id),
            onCreateFolder: _showCreateFolderDialog,
            onRenameFolder: _showRenameFolderDialog,
            onRenameDoc: _showRenameDocDialog,
            onMoveDoc: _showMoveToFolderDialog,
            sortedDocs: _sortedDocs,
            filtered: _filtered,
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_pick_file',
                tooltip: 'Pick Image or PDF',
                onPressed: _pickFileOrImage,
                child: const Icon(Icons.attach_file),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(
                heroTag: 'fab_camera',
                tooltip: 'Open Camera',
                onPressed: _openCamera,
                child: const Icon(Icons.camera_alt),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Folders tab
// ══════════════════════════════════════════════════════════════════════════════
class _FoldersTab extends StatelessWidget {
  const _FoldersTab({
    required this.session,
    required this.sortBy,
    required this.onSortChanged,
    required this.searchQuery,
    required this.activeFolderId,
    required this.onFolderSelected,
    required this.onCreateFolder,
    required this.onRenameFolder,
    required this.onRenameDoc,
    required this.onMoveDoc,
    required this.sortedDocs,
    required this.filtered,
  });

  final ChitraSession session;
  final _SortBy sortBy;
  final ValueChanged<_SortBy> onSortChanged;
  final String searchQuery;
  final String? activeFolderId;
  final ValueChanged<String?> onFolderSelected;
  final VoidCallback onCreateFolder;
  final ValueChanged<ChitraFolder> onRenameFolder;
  final ValueChanged<ChitraDocument> onRenameDoc;
  final ValueChanged<ChitraDocument> onMoveDoc;
  final List<ChitraDocument> Function(List<ChitraDocument>) sortedDocs;
  final List<ChitraDocument> Function(List<ChitraDocument>) filtered;

  @override
  Widget build(BuildContext context) {
    final docs = activeFolderId == null
        ? sortedDocs(filtered(session.documents))
        : sortedDocs(
            filtered(session.documentsInFolder(activeFolderId!)),
          );

    return CustomScrollView(
      slivers: [
        // Doc list
        if (docs.isEmpty)
          SliverFillRemaining(
            child: _EmptyState(
              icon: Icons.folder_open,
              message: 'No documents here yet.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _DocumentCard(
                  doc: docs[i],
                  session: session,
                  onRename: () => onRenameDoc(docs[i]),
                  onMove: () => onMoveDoc(docs[i]),
                ),
                childCount: docs.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Document card
// ══════════════════════════════════════════════════════════════════════════════
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.doc,
    required this.session,
    required this.onRename,
    required this.onMove,
  });

  final ChitraDocument doc;
  final ChitraSession session;
  final VoidCallback onRename;
  final VoidCallback onMove;

  String _folderName() {
    try {
      return session.folders
          .firstWhere((f) => f.id == doc.folderId)
          .name;
    } catch (_) {
      return 'Unknown';
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // future: open document viewer
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _DocThumbnail(doc: doc, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.pages.length} page(s)  ·  ${_folderName()}  ·  ${_formatDate(doc.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (doc.labels.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (final l in doc.labels)
                            Chip(
                              label: Text(l),
                              padding: EdgeInsets.zero,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      doc.isFavorite ? Icons.star : Icons.star_outline,
                      color: doc.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () => session.toggleFavorite(doc.id),
                    tooltip: doc.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      switch (v) {
                        case 'rename':
                          onRename();
                        case 'move':
                          onMove();
                        case 'trash':
                          session.moveToTrash(doc.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.drive_file_rename_outline),
                          title: Text('Rename'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'move',
                        child: ListTile(
                          leading: Icon(Icons.drive_file_move_outlined),
                          title: Text('Move to Folder'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'trash',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: Colors.red),
                          title: Text(
                            'Move to Trash',
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Document thumbnail
// ══════════════════════════════════════════════════════════════════════════════
class _DocThumbnail extends StatelessWidget {
  const _DocThumbnail({required this.doc, this.size = 52});

  final ChitraDocument doc;
  final double size;

  @override
  Widget build(BuildContext context) {
    final firstPath =
        doc.pages.isNotEmpty ? doc.pages.first.sourcePath : null;
    final hasFile = firstPath != null && File(firstPath).existsSync();

    if (hasFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(firstPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        doc.isEncrypted ? Icons.lock : Icons.insert_drive_file_outlined,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Empty state
// ══════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
