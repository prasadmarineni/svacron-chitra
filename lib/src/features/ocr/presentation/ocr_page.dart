import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/models/document.dart';
import '../../../core/state/chitra_session.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> with SingleTickerProviderStateMixin {
  final _session = ChitraSession.instance;
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  late TabController _tabController;

  bool _extracting = false;
  String? _sourcePath;
  String? _sourceDocId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recognizer.close();
    super.dispose();
  }

  Future<void> _pickImageAndExtract() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _sourcePath = file.path;
      _sourceDocId = null;
    });

    await _extractFromPath(file.path);
  }

  Future<void> _extractFromLatestScan() async {
    if (_session.imagePaths.isEmpty) {
      _showMessage('No scanned images found. Scan a document first.');
      return;
    }
    final latestPath = _session.imagePaths.last;
    setState(() {
      _sourcePath = latestPath;
      _sourceDocId = null;
    });
    await _extractFromPath(latestPath);
  }

  Future<void> _extractFromDocument(ChitraDocument doc) async {
    if (doc.pages.isEmpty) {
      _showMessage('Document has no pages.');
      return;
    }
    final firstPagePath = doc.pages.first.sourcePath;
    setState(() {
      _sourcePath = firstPagePath;
      _sourceDocId = doc.id;
    });
    await _extractFromPath(firstPagePath);
  }

  Future<void> _extractFromPath(String path) async {
    setState(() => _extracting = true);
    try {
      final inputImage = InputImage.fromFilePath(path);
      final result = await _recognizer.processImage(inputImage);
      if (mounted) {
        setState(() {
          _session.setOcrText(result.text.trim());
          _searchQuery = '';
        });
      }
    } catch (e) {
      _showMessage('OCR extraction failed: $e');
    } finally {
      if (mounted) {
        setState(() => _extracting = false);
      }
    }
  }

  Future<void> _copyOcrText() async {
    final text = _session.ocrText;
    if (text.isEmpty) {
      _showMessage('No OCR text to copy.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage('OCR text copied to clipboard.');
  }

  Future<void> _exportTxt() async {
    final text = _session.ocrText;
    if (text.isEmpty) {
      _showMessage('No OCR text to export.');
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(text, flush: true);
    _showMessage('TXT exported: ${file.path.split('/').last}');
  }

  List<String> _highlightSearch(String text) {
    if (_searchQuery.isEmpty) return [text];
    final pattern = _searchQuery.toLowerCase();
    final result = <String>[];
    int lastIndex = 0;
    final lowerText = text.toLowerCase();
    int index = lowerText.indexOf(pattern);
    while (index != -1) {
      result.add(text.substring(lastIndex, index));
      result.add(text.substring(index, index + pattern.length));
      lastIndex = index + pattern.length;
      index = lowerText.indexOf(pattern, lastIndex);
    }
    result.add(text.substring(lastIndex));
    return result;
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
            title: const Text('OCR & Text Extraction'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.auto_fix_high), text: 'Quick Extract'),
                Tab(icon: Icon(Icons.image_search), text: 'From Gallery'),
                Tab(icon: Icon(Icons.folder_outlined), text: 'From Library'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Quick extract from session
              _buildQuickExtractTab(),

              // Tab 2: Extract from gallery
              _buildGalleryTab(),

              // Tab 3: Extract from library documents
              _buildLibraryTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickExtractTab() {
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
                  'Extract from Latest Scan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quickly extract text from your most recent scanned image.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      _extracting || _session.imagePaths.isEmpty ? null : _extractFromLatestScan,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(
                    _extracting
                        ? 'Extracting...'
                        : _session.imagePaths.isEmpty
                            ? 'No scans available'
                            : 'Extract Text',
                  ),
                ),
                if (_session.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Latest scan: ${_session.imagePaths.last.split('/').last}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextDisplay(),
      ],
    );
  }

  Widget _buildGalleryTab() {
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
                  'Extract from Image',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select an image from your gallery to extract text.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _extracting ? null : _pickImageAndExtract,
                      icon: const Icon(Icons.image_search),
                      label: const Text('Select Image'),
                    ),
                    if (_sourcePath != null)
                      Chip(
                        label: Text(_sourcePath!.split('/').last,
                            overflow: TextOverflow.ellipsis),
                        onDeleted: () =>
                            setState(() => _sourcePath = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextDisplay(),
      ],
    );
  }

  Widget _buildLibraryTab() {
    final docs = _session.documents;
    return docs.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No documents yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Your Documents',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...docs.map(
                (doc) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      doc.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${doc.pages.length} page(s)'),
                    trailing:
                        _sourceDocId == doc.id && _extracting
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                            : IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () =>
                                  _extractFromDocument(doc),
                            ),
                    onTap: () => _extractFromDocument(doc),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextDisplay(),
            ],
          );
  }

  Widget _buildTextDisplay() {
    final ocrText = _session.ocrText;
    final isEmpty = ocrText.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Extracted Text',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (!isEmpty)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'copy') {
                            _copyOcrText();
                          } else if (value == 'export') {
                            _exportTxt();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'copy',
                            child: ListTile(
                              leading: Icon(Icons.copy),
                              title: Text('Copy'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'export',
                            child: ListTile(
                              leading: Icon(Icons.download),
                              title: Text('Export as TXT'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!isEmpty) ...[
                  const SizedBox(height: 8),
                  SearchBar(
                    hintText: 'Search in text...',
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _searchQuery = ''),
                        ),
                    ],
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(30),
            ),
          ),
          child: isEmpty
              ? Center(
                  child: Text(
                    'Extracted text will appear here.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: _searchQuery.isEmpty
                      ? SelectableText(ocrText)
                      : _buildHighlightedText(ocrText),
                ),
        ),
      ],
    );
  }

  Widget _buildHighlightedText(String text) {
    final parts = _highlightSearch(text);
    return Wrap(
      children: parts.map((part) {
        final isMatch = part.toLowerCase() == _searchQuery.toLowerCase();
        return Container(
          color: isMatch ? Colors.yellow.withAlpha(100) : null,
          child: SelectableText(part),
        );
      }).toList(),
    );
  }
}
