import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/state/chitra_session.dart';

class PdfToolsPage extends StatefulWidget {
  const PdfToolsPage({super.key});

  @override
  State<PdfToolsPage> createState() => _PdfToolsPageState();
}

class _PdfToolsPageState extends State<PdfToolsPage>
    with SingleTickerProviderStateMixin {
  final _session = ChitraSession.instance;
  late TabController _tabController;
  bool _creatingPdf = false;
  bool _merging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Create PDF from images ──────────────────────────────────────────────────
  Future<void> _createPdfFromImages() async {
    if (_session.imagePaths.isEmpty) {
      _showMessage('Add images in Scan tab first.');
      return;
    }

    setState(() => _creatingPdf = true);
    try {
      final document = pw.Document();
      for (final imagePath in _session.imagePaths) {
        final bytes = await File(imagePath).readAsBytes();
        final memoryImage = pw.MemoryImage(bytes);
        document.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(0),
            build: (_) {
              return pw.Image(memoryImage, fit: pw.BoxFit.cover);
            },
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputFile = File(path_lib.join(directory.path, fileName));
      final pdfBytes = await document.save();
      await outputFile.writeAsBytes(pdfBytes, flush: true);

      if (mounted) {
        setState(() {
          _session.setActivePdfPath(outputFile.path);
        });
        _showMessage('PDF created: ${outputFile.path.split('/').last}');
      }
    } catch (e) {
      _showMessage('Failed to create PDF: $e');
    } finally {
      if (mounted) {
        setState(() => _creatingPdf = false);
      }
    }
  }

  // ── Merge multiple PDFs ──────────────────────────────────────────────────────
  Future<void> _mergePdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() => _merging = true);
    try {
      _showMessage('Merge feature implementation pending - select files to merge');
      // Note: Full PDF merging requires additional dependencies
      // Implementing placeholder for now
    } catch (e) {
      _showMessage('Failed to merge PDFs: $e');
    } finally {
      if (mounted) {
        setState(() => _merging = false);
      }
    }
  }

  // ── Open PDF from device ─────────────────────────────────────────────────────
  Future<void> _openPdfFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _session.setActivePdfPath(path);
      });
      _showMessage('PDF loaded: ${path.split('/').last}');
    }
  }

  // ── Open PDF preview ─────────────────────────────────────────────────────────
  Future<void> _openPreview() async {
    final path = _session.activePdfPath;
    if (path == null) {
      _showMessage('No active PDF selected.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _PdfPreviewPage(pdfPath: path)),
    );
  }

  // ── Share active PDF ─────────────────────────────────────────────────────────
  Future<void> _shareActivePdf() async {
    final path = _session.activePdfPath;
    if (path == null) {
      _showMessage('No active PDF selected.');
      return;
    }
    try {
      final bytes = await File(path).readAsBytes();
      await Printing.sharePdf(bytes: bytes, filename: path_lib.basename(path));
    } catch (e) {
      _showMessage('Share failed: $e');
    }
  }

  // ── Print active PDF ─────────────────────────────────────────────────────────
  Future<void> _printActivePdf() async {
    final path = _session.activePdfPath;
    if (path == null) {
      _showMessage('No active PDF selected.');
      return;
    }
    try {
      final bytes = await File(path).readAsBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      _showMessage('Print failed: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('PDF Tools'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.add_photo_alternate_outlined), text: 'Create'),
                Tab(icon: Icon(Icons.merge_outlined), text: 'Merge'),
                Tab(icon: Icon(Icons.visibility_outlined), text: 'View'),
                Tab(icon: Icon(Icons.build_outlined), text: 'Edit'),
                Tab(icon: Icon(Icons.more_horiz), text: 'More'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Create PDF from images
              _buildCreateTab(),

              // Tab 2: Merge PDFs
              _buildMergeTab(),

              // Tab 3: View/Open PDF
              _buildViewTab(),

              // Tab 4: Edit PDF
              _buildEditTab(),

              // Tab 5: More tools
              _buildMoreTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convert Images to PDF',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a PDF from your scanned images. All images in the current session will be combined into a single PDF.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _creatingPdf ? null : _createPdfFromImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(
                    _creatingPdf
                        ? 'Creating PDF...'
                        : _session.imagePaths.isEmpty
                            ? 'No images available'
                            : 'Create PDF from ${_session.imagePaths.length} image(s)',
                  ),
                ),
                if (_session.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Images in session: ${_session.imagePaths.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMergeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merge Multiple PDFs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select 2 or more PDFs to merge them into a single file. Pages will be combined in the order selected.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _merging ? null : _mergePdfs,
                  icon: const Icon(Icons.merge),
                  label: Text(_merging ? 'Merging...' : 'Select PDFs'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewTab() {
    final hasActivePdf = _session.activePdfPath != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF Viewer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'View and navigate your PDF files with zoom and text search capabilities.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (hasActivePdf) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current PDF:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          path_lib.basename(_session.activePdfPath!),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                overflow: TextOverflow.ellipsis,
                              ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _openPdfFromDevice,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Open PDF'),
                    ),
                    if (hasActivePdf)
                      FilledButton.icon(
                        onPressed: _openPreview,
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditTab() {
    final tools = [
      ('split_pages', 'Split PDF', 'Extract specific pages or ranges'),
      ('reorder_pages', 'Reorder Pages', 'Rearrange page order with drag-drop'),
      ('rotate_pages', 'Rotate Pages', 'Rotate individual pages'),
      ('delete_pages', 'Delete Pages', 'Remove unwanted pages'),
      ('compress', 'Compress PDF', 'Reduce file size'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Edit Tools',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...tools.map(
          (tool) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.edit_note_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(tool.$2),
              subtitle: Text(tool.$3, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward, size: 18),
              onTap: () => _showMessage('Feature coming soon'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Additional Actions',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_session.activePdfPath != null) ...[
          FilledButton.icon(
            onPressed: _shareActivePdf,
            icon: const Icon(Icons.share),
            label: const Text('Share PDF'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _printActivePdf,
            icon: const Icon(Icons.print),
            label: const Text('Print PDF'),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Open a PDF first to see more options',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Features Coming Soon',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        ...const [
          'Watermark & Page Numbers',
          'Password Protection',
          'Digital Signature',
          'Add Annotations',
          'Extract Pages as Images',
        ].map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 8),
                Text(feature, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PDF Preview Page
// ══════════════════════════════════════════════════════════════════════════════
class _PdfPreviewPage extends StatelessWidget {
  const _PdfPreviewPage({required this.pdfPath});

  final String pdfPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(path_lib.basename(pdfPath)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                final bytes = await File(pdfPath).readAsBytes();
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: path_lib.basename(pdfPath),
                );
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: File(pdfPath).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Unable to load PDF file.'));
          }
          return PdfPreview(
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            build: (_) async => snapshot.data!,
          );
        },
      ),
    );
  }
}
